close all; clear; clc; 

%% parallel computation setup --------------------------------------------------

% enable the use of multicores
enable_multicores                               =   1;

curr_parpool = gcp('nocreate');
if isempty(curr_parpool) && enable_multicores
    parpool('local');
end

%% parameter setup -------------------------------------------------------------

% number of PEs
J2                                              =   256;
% choose a flow: 'rs', 'ws'
flow                                            =   'rs';

% word length [in bytes]
WL                                              =   2;
% batch size
N                                               =   16;
% AlexNet layer ID
alexnet_layer_id                                =   2;
% get alexnet parameters 
[H, R, U, C, M, E, alpha]                       =   get_alexnet_params(alexnet_layer_id);

% ====== RF size sweep range ======
G_byte                                          =   32:32:512;

% number of trials to run optimization in order to avoid local minimal
num_trials                                      =   5;

%% default area ----------------------------------------------------------------

% RF size for default storage area
G_byte_default                                  =   512;
% default storage area
A                                               =   get_total_storage_area(J2, J2 * G_byte_default, G_byte_default);

%% run flow --------------------------------------------------------------------

% result arrays
results                                         =   cell(size(G_byte));
energy_cost_array                               =   zeros(1, length(G_byte));
    
% run flow optimization
if enable_multicores == 1
    parfor i = 1:length(G_byte)
        Q_byte                                  =   get_buffer_size(A, J2, G_byte(i));
        if      (strcmp(flow, 'rs') )
            [results{i}.access, results{i}.reuse, params, results{i}.thruput]   =   rs_flow(N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte(i), WL, num_trials);
        elseif  (strcmp(flow, 'ws') )
            [results{i}.access, results{i}.reuse, params, results{i}.thruput]   =   ws_flow(N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte(i), WL, num_trials);
        end
        % collect result
        params.J2                               =   J2;
        params.A                                =   A;
        params.G_byte                           =   G_byte(i);
        params.Q_byte                           =   Q_byte;
        params.total_storage_byte               =   (G_byte(i) * J2 + Q_byte);
        params.alexnet_layer_id                 =   alexnet_layer_id;
        results{i}.params                       =   params;
        [energy_cost_array(i), results{i}.energy_cost] ...
                                                =   get_energy_cost(results{i}.access);
    end
else
    for j = 1:length(G_byte)
        Q_byte                                  =   get_buffer_size(A, J2, G_byte(j));
        if      (strcmp(flow, 'rs') )
            [access, reuse, params, thruput]    =   rs_flow(N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte(j), WL, num_trials);
        elseif  (strcmp(flow, 'ws') )
            [access, reuse, params, thruput]    =   ws_flow(N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte(j), WL, num_trials);
        end
        % collect result
        params.J2                               =   J2;
        params.A                                =   A;
        params.G_byte                           =   G_byte(j);
        params.Q_byte                           =   Q_byte;
        params.total_storage_byte               =   (G_byte(j) * J2 + Q_byte);
        params.alexnet_layer_id                 =   alexnet_layer_id;
        results{j}.reuse                        =   reuse;
        results{j}.access                       =   access;
        results{j}.params                       =   params;
        results{j}.thruput                      =   thruput;
        results{j}.energy_cost                  =   get_energy_cost(access);
        energy_cost_array(j)                    =   results{j}.energy_cost;
    end
end

%% plot ------------------------------------------------------------------------

fig1 = figure();
axes1   = axes('Parent', fig1, 'FontSize', 20);
hold on;
grid on;
bar(G_byte, energy_cost_array);
xlabel('Register File Size (byte)', 'fontsize', 20);
ylabel('Normalized Energy', 'fontsize', 20);
axis tight;
