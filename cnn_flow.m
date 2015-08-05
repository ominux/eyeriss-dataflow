close all; clear; clc; 

%% problem size parameters -----------------------------------------------------

% choose the layer in AlexNet to run the tests
% alexnet_layer_id                            =   2;
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
% J2                                          =   256;
% total storage area [um^2]
% A                                           =   4400000; % 256 * 0.5KB RF + 128KB Buff
% register file size per PE [byte]
% G_byte                                      =   512;
% buffe size [byte]
% Q_byte                                      =   buffer_size(A, J2, G_byte);

%% other parameters ------------------------------------------------------------

% number of trials to run optimization in order to avoid local minimal
num_trials                                  =   1;

%% flows -----------------------------------------------------------------------

% row stationary:           register file size = ( pqR+qR+p ) * WL
% [access, reuse, params]                     =   rs_flow       (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);

% no local reuse:           register file size = 0
% [access, reuse, params]                     =   nlr_flow      (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);

% output stationary (IBM):  register file size = 1 * WL
% [access, reuse, params]                     =   os_isb_flow   (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);

% output stationary (SDN):  register file size = (U+RU) * WL
% [access, reuse, params]                     =   os_sdn_flow   (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);

% weight stationary:        register file size = ( q+1 ) * WL
% [access, reuse, params]                     =   ws_flow       (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);

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
% J2                                          =   256;
% A                                           =   4400000;
% N                                           =   1;
% alexnet_layer_id                            =   2;
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

% % comparing all flows
% 
% energy_bar_graph_array                      =   zeros(1, 5);
% 
% % row stationary
% G_byte                                      =   256 * WL; 
% Q_byte                                      =   buffer_size(A, J2, G_byte);
% [access, reuse, params]                     =   row_stationary_flow(N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials); 
% energy_bar_graph_array(1)                   =   energy_cost(access);
% % channel reuse
% G_byte                                      =   0; 
% Q_byte                                      =   buffer_size(A, J2, G_byte);
% [access, reuse, params]                     =   channel_reuse_flow(N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);
% energy_bar_graph_array(2)                   =   energy_cost(access);
% % output stationary (ibm)
% G_byte                                      =   1 * WL; 
% Q_byte                                      =   buffer_size(A, J2, G_byte);
% [access, reuse, params]                     =   output_stationary_ibm_flow(N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);
% energy_bar_graph_array(3)                   =   energy_cost(access);
% % output stationary (shidiannao)
% G_byte                                      =   (U+R*U) * WL; 
% Q_byte                                      =   buffer_size(A, J2, G_byte);
% [access, reuse, params]                     =   output_stationary_shidiannao_flow(N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);
% energy_bar_graph_array(4)                   =   energy_cost(access);
% % weight stationary
% G_byte                                      =   128 * WL; 
% Q_byte                                      =   buffer_size(A, J2, G_byte);
% [access, reuse, params]                     =   weight_stationary_flow(N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);
% energy_bar_graph_array(5)                   =   energy_cost(access);
% 
% fig4 = figure();
% axes4   = axes('Parent', fig4, 'XTickLabel',{'RS', 'UCLA', 'IBM', 'SDN', 'WS'}, 'FontSize', 20);
% hold on;
% grid on;
% bar(energy_bar_graph_array');
% % xlabel('Register File Size (byte)', 'fontsize', 20);
% ylabel('Normalized Energy', 'fontsize', 20);
% axis tight;

%% test 5 ----------------------------------------------------------------------

% % sweeping batch size for weight stationary
% 
% % batch size
% N_sweep                                     =   [1 2 4 8 16 32 64 128];
% % register file size [in bytes]
% G_byte                                      =   128 .* WL;
% % buffer size [in bytes]
% Q_byte                                      =   buffer_size(A, J2, G_byte);
% % result arrays
% stat.weight_stationary.batch_size_sweep     =   cell(size(N_sweep));
% energy_bar_graph_array                      =   zeros(1, length(N_sweep));
% % run flow optimization
% for i = 1:length(N_sweep)
%     % flow optimization
%     [access, reuse, params]                                 =   weight_stationary_flow(N_sweep(i), C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);
%     % collect result
%     params.G_byte                                           =   G_byte;
%     params.Q_byte                                           =   Q_byte;
%     params.total_storage_byte                               =   G_byte * J2 + Q_byte;
%     params.J2                                               =   J2;
%     params.A                                                =   A;
%     stat.weight_stationary.batch_size_sweep{i}.reuse        =   reuse;
%     stat.weight_stationary.batch_size_sweep{i}.access       =   access;
%     stat.weight_stationary.batch_size_sweep{i}.params       =   params;
%     % calculate energy
%     energy_bar_graph_array(i)                               =   energy_cost(stat.weight_stationary.batch_size_sweep{i}.access);
% end
% 
% fig5 = figure();
% axes5   = axes('Parent', fig5, 'FontSize', 20);
% hold on;
% grid on;
% bar(N_sweep, energy_bar_graph_array);
% xlabel('Batch Size', 'fontsize', 20);
% ylabel('Normalized Energy', 'fontsize', 20);
% axis tight;

