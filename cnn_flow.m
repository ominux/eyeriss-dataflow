close all; clear; clc; 

%% system config ---------------------------------------------------------------

% enable the use of multicores
enable_multicores                           =   1;

%% problem size parameters -----------------------------------------------------

% choose the layer in AlexNet to run the tests
% alexnet_layer_id                            =   5;
% batch_size
% N                                           =   128;
% CNN size based on alexnet layers
%   H: input fmap size (width = height)
%   R: filter size (width = height)
%   U: stride size
%   C: number input channels
%   M: number output channels
%   E: output fmap size (width = height)
%   alpha: E/H
% [H, R, U, C, M, E, alpha]                   =   get_alexnet_params(alexnet_layer_id);

% word length [in bytes]
WL                                          =   2;

%% architecture parameters -----------------------------------------------------

% total number of PEs (J^2)
% J2                                          =   512;
% register file size per PE [byte]
% G_byte                                      =   512;
% buffe size [byte]
% Q_byte                                      =   J2 * G_byte; % just to let buffer size = aggregated RF size
% total storage area [um^2]
% A                                           =   get_total_storage_area(J2, Q_byte, G_byte);

%% other parameters ------------------------------------------------------------

% number of trials to run optimization in order to avoid local minimal
num_trials                                  =   100;

%% parallel computation setup --------------------------------------------------

curr_parpool = gcp('nocreate');
if isempty(curr_parpool) && enable_multicores
    parpool('local');
end

%% flows -----------------------------------------------------------------------

% row stationary:           register file size = ( pqR+qR+p ) * WL
% [access, reuse, params, thruput]            =   rs_flow       (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);
% energy_cost                                 =   get_energy_cost(access);

% no local reuse:           register file size = 0
% [access, reuse, params, thruput]            =   nlr_flow      (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);
% energy_cost                                 =   get_energy_cost(access);

% output stationary (IBM):  register file size = 1 * WL
% [access, reuse, params, thruput]            =   os_isb_flow   (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);
% energy_cost                                 =   get_energy_cost(access);

% output stationary (SDN):  register file size = (U+RU) * WL
% [access, reuse, params, thruput]            =   os_sdn_flow   (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);
% energy_cost                                 =   get_energy_cost(access);

% weight stationary:        register file size = ( q+1 ) * WL
% [access, reuse, params, thruput]            =   ws_flow       (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);
% energy_cost                                 =   get_energy_cost(access);

% SIMD/SIMT


%% test 1 ----------------------------------------------------------------------

% under the same chip area and #PEs, the total on-chip storage vs. register file
% size per PE.

% J2                                          =   256;
% A                                           =   4400000;
% G_byte                                      =   32:32:1024;
% Q_byte                                      =   zeros(size(G_byte));
% for i = 1:length(G_byte)
%     Q_byte(i)                               =   get_buffer_size(A, J2, G_byte(i));
% end
% total_storage_byte                          =   (G_byte .* J2 + Q_byte);
% 
% test1.A                                     =   A;
% test1.J2                                    =   J2;
% test1.G_byte                                =   G_byte;
% test1.Q_byte                                =   Q_byte;
% test1.total_storage_byte                    =   total_storage_byte;
% save('results/test1', 'test1');
% 
% fig1    = figure();
% axes1   = axes('Parent', fig1, 'FontSize', 20);
% hold on;
% grid on;
% bar(G_byte, total_storage_byte/1024);
% xlabel('Register File Size (byte)', 'fontsize', 20);
% ylabel('Total On-Chip Storage Size (KB)', 'fontsize', 20);
% axis tight;

%% test 2 ----------------------------------------------------------------------

% Finding the best reg file size for row stationary flow under constant area

% % parameter setup
% J2                                          =   256;
% A                                           =   4400000;
% N                                           =   1;
% alexnet_layer_id                            =   2;
% G_byte_sweep                                =   64:64:1024;
% % run sweep
% [results, energy_cost_array]                =   rs_flow_reg_sweep(J2, A, N, alexnet_layer_id, WL, G_byte_sweep, num_trials);
% 
% fig2 = figure();
% axes2   = axes('Parent', fig2, 'FontSize', 20);
% hold on;
% grid on;
% bar(G_byte_sweep, energy_cost_array);
% xlabel('Register File Size (byte)', 'fontsize', 20);
% ylabel('Normalized Energy', 'fontsize', 20);
% axis tight;

%% test 3 ----------------------------------------------------------------------

% Finding the best reg file size for weight stationary flow under constant area

% % parameter setup
% J2                                          =   512;
% G_byte_default                              =   512;
% A                                           =   get_total_storage_area(J2, J2 * G_byte_default, G_byte_default);
% N                                           =   128;
% alexnet_layer_id                            =   5;
% G_byte_sweep                                =   64:64:1024;
% % run sweep
% [results, energy_cost_array]                =   ws_flow_reg_sweep(J2, A, N, alexnet_layer_id, WL, G_byte_sweep, num_trials);
% 
% fig2 = figure();
% axes2   = axes('Parent', fig2, 'FontSize', 20);
% hold on;
% grid on;
% bar(G_byte_sweep, energy_cost_array);
% xlabel('Register File Size (byte)', 'fontsize', 20);
% ylabel('Normalized Energy', 'fontsize', 20);
% axis tight;

%% test 4 ----------------------------------------------------------------------

% comparing all flows
J2                                          =   [128 256 512 1024];
N                                           =   [1 16 64 128];
alexnet_layer_id                            =   [1 2 3 4 5];
G_byte_default                              =   512;

if enable_multicores
    total_num_threads                       =   length(J2) * length(N) * length(alexnet_layer_id);
    % results cell
    results                                 =   cell(1, total_num_threads);
    fprintf('\n\n');    
    parfor par_th= 1:total_num_threads
        k                                   =   floor( (par_th-1)/(length(J2) * length(N)) ) + 1;
        j                                   =   floor( ((par_th - (k-1)*length(J2)*length(N))-1)/length(J2) ) + 1;
        i                                   =   par_th - (k-1)*length(J2)*length(N) - (j-1)*length(J2);
        fprintf('  Thread #%d (%d, %d, %d) Running... <J2 = %d, N = %d, AlexNet Layer ID = %d>\n', par_th, i, j, k, J2(i), N(j), alexnet_layer_id(k));
        
        A                                   =   get_total_storage_area(J2(i), J2(i)*G_byte_default, G_byte_default);
        results{par_th}                     =   flow_energy_comparison(J2(i), A, N(j), alexnet_layer_id(k), WL, num_trials);
    end
    results                                 =   reshape(results, [length(J2) length(N) length(alexnet_layer_id)]);
else
    % results cell
    results                                 =   cell(length(J2), length(N), length(alexnet_layer_id));
    for i = 1:length(J2)
        A                                   =   get_total_storage_area(J2(i), J2(i)*G_byte_default, G_byte_default);
        for j = 1:length(N)
            for k = 1:length(alexnet_layer_id)
                results{i, j, k}            =   flow_energy_comparison(J2(i), A, N(j), alexnet_layer_id(k), WL, num_trials);
            end
        end
    end
end

save('results/flow_energy_comparison_results', 'results');

% fig4    = figure();
% axes4   = axes('Parent', fig4, 'XTickLabel',{'RS', 'UCLA', 'IBM', 'SDN', 'WS'}, 'FontSize', 20);
% hold on; grid on;
% bar(results{1, 1, 1}.energy);
% ylabel('Normalized Energy', 'fontsize', 20);
% axis tight;

