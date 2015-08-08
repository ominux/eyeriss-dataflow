close all; clear; clc; 

%% problem size parameters -----------------------------------------------------

% batch_size
N                                           =   64;
% CNN size based on alexnet layers
%   H: input fmap size (width = height)
%   R: filter size (width = height)
%   U: stride size
%   C: number input channels
%   M: number output channels
%   E: output fmap size (width = height)
%   alpha: E/H
%
% choose the layer in AlexNet to run the tests
alexnet_layer_id                            =   5;
[H, R, U, C, M, E, alpha]                   =   get_alexnet_params(alexnet_layer_id);

% word length [in bytes]
WL                                          =   2;

%% architecture parameters -----------------------------------------------------

% total number of PEs (J^2)
J2                                          =   256;
% choose flow: 'rs', 'nlr', 'os_ibm', 'os_sdn', 'ws'
flow                                        =   'ws';

%% default area ----------------------------------------------------------------

% default number of PEs
J2_default                                  =   256;
% RF size for default area
G_byte_default                              =   512;
% buffer size for default area
Q_byte_default                              =   J2_default * G_byte_default;
% total area (processing + storge) [um^2]
B                                           =   J2_default * get_pe_area() + ...
                                                J2_default * get_storage_area_from_size(G_byte_default) + ...
                                                get_storage_area_from_size(Q_byte_default);
% total storage area (buff + RF) [um^2]
A                                           =   B - J2 * get_pe_area();
                                            
%% other parameters ------------------------------------------------------------

% number of trials to run optimization in order to avoid local minimal
num_trials                                  =   3;

%% flows -----------------------------------------------------------------------

% G_byte: register file size per PE [byte]
% Q_byte: buffe size [byte]

if      ( strcmp(flow,'rs') )
    % row stationary:           register file size = ( pqR+qR+p ) * WL
    G_byte                                      =   256 * WL; 
%     G_byte                                      =   1024;
    Q_byte                                      =   get_buffer_size(A, J2, G_byte);
    [access, reuse, params, thruput]            =   rs_flow       (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);
    [total_energy_cost, item_energy_cost]       =   get_energy_cost(access);
elseif  ( strcmp(flow,'nlr') )
    % no local reuse:           register file size = 0
    G_byte                                      =   0 * WL; 
    Q_byte                                      =   get_buffer_size(A, J2, G_byte);
    [access, reuse, params, thruput]            =   nlr_flow      (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);
    [~, energy_cost]                            =   get_energy_cost(access);
elseif  ( strcmp(flow,'os_ibm') )
    % output stationary (IBM):  register file size = 1 * WL
    G_byte                                      =   1 * WL; 
    Q_byte                                      =   get_buffer_size(A, J2, G_byte);
    [access, reuse, params, thruput]            =   os_ibm_flow   (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);
    [~, energy_cost]                            =   get_energy_cost(access);
elseif  ( strcmp(flow,'os_sdn') )
    % output stationary (SDN):  register file size = (U+RU) * WL
    G_byte                                      =   (U+R*U) * WL; 
    Q_byte                                      =   get_buffer_size(A, J2, G_byte);
    [access, reuse, params, thruput]            =   os_sdn_flow   (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);
    [~, energy_cost]                            =   get_energy_cost(access);
elseif  ( strcmp(flow,'ws') )
    % weight stationary:        register file size = ( q+1 ) * WL
    G_byte                                      =   128 * WL; 
    Q_byte                                      =   get_buffer_size(A, J2, G_byte);
    [access, reuse, params, thruput]            =   ws_flow       (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);
    [~, energy_cost]                            =   get_energy_cost(access);
end

% SIMD/SIMT
% n/a


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

