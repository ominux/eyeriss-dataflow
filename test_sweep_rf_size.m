close all; clear; clc; 

%% parallel computation setup --------------------------------------------------

% enable the use of multicores
enable_multicores                           =   0;

curr_parpool = gcp('nocreate');
if isempty(curr_parpool) && enable_multicores
    parpool('local');
end

%% parameter setup -------------------------------------------------------------


% number of PEs
J2                                          =   256;
% RF size for default storage area
G_byte_default                              =   512;
% default storage area
A                                           =   get_total_storage_area(J2, J2 * G_byte_default, G_byte_default);

% choose a flow: 'rs', 'ws'
flow                                        =   'rs';

% word length [in bytes]
WL                                          =   2;
% batch size
N                                           =   128;
% AlexNet layer ID
alexnet_layer_id                            =   5;
% get alexnet parameters 
[H, R, U, C, M, E, alpha]                   =   get_alexnet_params(alexnet_layer_id);

% ====== RF size sweep range ======
G_byte                                      =   [128 256]; % 64:64:1024;

% number of trials to run optimization in order to avoid local minimal
num_trials                                  =   1;

%% run flow --------------------------------------------------------------------

% result arrays
results                                     =   cell(size(G_byte));
energy_cost_array                           =   zeros(1, length(G_byte));
    
% run flow optimization
if enable_multicores == 1
    parfor i = 1:length(G_byte)
        Q_byte                                  =   get_buffer_size(A, J2, G_byte(i));
        if      (strcmp(flow, 'rs') )
            [access, reuse, params, thruput]        =   rs_flow(N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte(i), WL, num_trials);
        elseif  (strcmp(flow, 'ws') )
            [access, reuse, params, thruput]        =   ws_flow(N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte(i), WL, num_trials);
        end
        % collect result
        params.J2                               =   J2;
        params.A                                =   A;
        params.G_byte                           =   G_byte(i);
        params.Q_byte                           =   Q_byte;
        params.total_storage_byte               =   (G_byte(i) * J2 + Q_byte);
        params.alexnet_layer_id                 =   alexnet_layer_id;
        results{i}.reuse                        =   reuse;
        results{i}.access                       =   access;
        results{i}.params                       =   params;
        results{i}.thruput                      =   thruput;
        results{i}.energy_cost                  =   get_energy_cost(access);
        energy_cost_array(i)                    =   results{i}.energy_cost;
    end
else
    for i = 1:length(G_byte)
        Q_byte                                  =   get_buffer_size(A, J2, G_byte(i));
        if      (strcmp(flow, 'rs') )
            [access, reuse, params, thruput]        =   rs_flow(N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte(i), WL, num_trials);
        elseif  (strcmp(flow, 'ws') )
            [access, reuse, params, thruput]        =   ws_flow(N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte(i), WL, num_trials);
        end
        % collect result
        params.J2                               =   J2;
        params.A                                =   A;
        params.G_byte                           =   G_byte(i);
        params.Q_byte                           =   Q_byte;
        params.total_storage_byte               =   (G_byte(i) * J2 + Q_byte);
        params.alexnet_layer_id                 =   alexnet_layer_id;
        results{i}.reuse                        =   reuse;
        results{i}.access                       =   access;
        results{i}.params                       =   params;
        results{i}.thruput                      =   thruput;
        results{i}.energy_cost                  =   get_energy_cost(access);
        energy_cost_array(i)                    =   results{i}.energy_cost;
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
