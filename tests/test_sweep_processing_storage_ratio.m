close all; clear; clc; 

%% parallel computation setup --------------------------------------------------

% enable the use of multicores
enable_multicores                           =   1;

curr_parpool = gcp('nocreate');
if isempty(curr_parpool) && enable_multicores
    parpool('local');
end

%% parameter setup -------------------------------------------------------------

% word length [in bytes]
WL                                          =   2;
% batch size
N                                           =   16;
% layer ID of AlexNet
alexnet_layer_id                            =   [1 2 3 4 5];    % [1 2 3 4 5];

% number of PEs
J2                                          =   [32 64 96 128 160 192 224 256 288];
% RF size
G_byte                                      =   [1024 512 256];

% times to run optimization to avoid local minima
num_trials                                  =   50;

%% default area ----------------------------------------------------------------

% number of PEs for default area
J2_default                                  =   256;
% RF size for default area
G_byte_default                              =   512;
% buffer size for default area
Q_byte_default                              =   J2_default * G_byte_default;
% default total area (processing + storage)
B                                           =   J2_default * get_pe_area() + ...
                                                J2_default * get_storage_area_from_size(G_byte_default) + ...
                                                get_storage_area_from_size(Q_byte_default);

%% run flow --------------------------------------------------------------------

num_threads                                 =   length(alexnet_layer_id) * length(J2);

results                                     =   cell(1, num_threads);
energy_cost_array                           =   zeros(1, num_threads);
thruput_array                               =   zeros(1, num_threads);

parfor par_th = 1:num_threads
    j                                       =   floor((par_th-1)/length(J2)) + 1;
    i                                       =   par_th - (j-1)*length(J2);
    
    fprintf('  Thread #%d (J2 = %d, AlexNet Layer ID = %d) \n', par_th, J2(i), alexnet_layer_id(j));
    
    % get alexnet parameters 
    [H, R, U, C, M, E, alpha]               =   get_alexnet_params(alexnet_layer_id(j));
    
    % total storage area
    A                                       =   B - ( J2(i) * get_pe_area() );
    
    total_E                                 =   Inf;
    for k = 1:length(G_byte)
        
        Q_byte                              =   get_buffer_size(A, J2(i), G_byte(k));
        [access, ~, params, thruput]        =   rs_flow(N, C, M, H, R, E, U, alpha, J2(i), Q_byte, G_byte(k), WL, num_trials);
        
        [curr_total_E, energy_cost]         =   get_energy_cost(access);
        
        if ( curr_total_E < (total_E*0.95) ) || (curr_total_E < total_E && thruput.active_pes > thruput_array(par_th))
            total_E                         =   curr_total_E;
            params.G_byte                   =   G_byte(k);
            params.Q_byte                   =   Q_byte;
            results{par_th}.access          =   access;
            results{par_th}.params          =   params;
            results{par_th}.thruput         =   thruput.active_pes;
            results{par_th}.energy.breakdown=   energy_cost;
            results{par_th}.energy.total    =   curr_total_E;
            thruput_array(par_th)           =   thruput.active_pes;
        end
    end
    energy_cost_array(par_th)               =   total_E;
    
end

results                                     =   reshape(results, [length(J2) length(alexnet_layer_id)]);
energy_cost_array                           =   reshape(energy_cost_array, [length(J2) length(alexnet_layer_id)]);
thruput_array                               =   reshape(thruput_array, [length(J2) length(alexnet_layer_id)]);

%% plot ------------------------------------------------------------------------

fig1 = figure();
axes1   = axes('Parent', fig1, 'FontSize', 20);
hold on;
grid on;
bar(energy_cost_array');
% xlabel('Register File Size (byte)', 'fontsize', 20);
ylabel('Normalized Energy', 'fontsize', 20);
axis tight;


fig2 = figure();
hold on;
grid on;
plot(1./thruput_array(:, 2), energy_cost_array(:, 2), 'o-m');
xlabel('1/Throughput', 'fontsize', 20);
ylabel('Normalized Energy', 'fontsize', 20);
axis tight;

%% write out -------------------------------------------------------------------

ofile = fopen('results/sweep_processing_storage_ratio.txt', 'w');

for i = 1:length(J2)

    for j = 1:length(alexnet_layer_id)

        active_pes      =   results{i,j}.thruput;
        energy          =   results{i,j}.energy.total;
        buff_size       =   results{i,j}.params.Q_byte;
        rf_size         =   results{i,j}.params.G_byte;
        
        % active PEs, energy, buffer size, RF size
        fprintf(ofile, '%d, %d, %d, %d\n', active_pes, energy, buff_size, rf_size);
    end
end

fclose(ofile);


