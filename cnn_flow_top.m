close all; clear; clc; 

%% setup project ---------------------------------------------------------------

project_setup();

%% problem size parameters -----------------------------------------------------

% batch_size
N                                           =   3;
% CNN size parameters
%   G: number of groups
%   H: input fmap size (width = height)
%   R: filter size (width = height)
%   U: stride size
%   C: number input channels
%   M: number output channels
%   E: output fmap size (width = height)
%   alpha: E/H
%
% choose a layer in the CNN model to run the tests
% available models: alexnet, vgg16
alexnet_layer_id                            =   1;
[G, H, R, U, C, M, E, alpha]                =   get_vgg16_params(alexnet_layer_id);

% word length [in bytes]
WL                                          =   2;

%% architecture parameters -----------------------------------------------------

% total number of PEs (J^2)
J2                                          =   168;
% choose flow: 'rs', 'nlr', 'os_ibm', 'os_sdn', 'ws'
flow                                        =   'rs';

%% default area ----------------------------------------------------------------

% default number of PEs
J2_default                                  =   256;
% RF size for default area
RF_byte_default                             =   512;
% buffer size for default area
Q_byte_default                              =   J2_default * RF_byte_default;
% total area (processing + storge) [um^2]
B                                           =   J2_default * get_pe_area() + ...
                                                J2_default * get_storage_area_from_size(RF_byte_default) + ...
                                                get_storage_area_from_size(Q_byte_default);
% total storage area (buff + RF) [um^2]
A                                           =   B - J2 * get_pe_area();
                                            
%% other parameters ------------------------------------------------------------

% number of trials to run optimization in order to avoid local minimal
num_trials                                  =   50;

%% flows -----------------------------------------------------------------------

% G_byte: register file size per PE [byte]
% Q_byte: buffe size [byte]

if      ( strcmp(flow,'rs') )
    % row stationary:           register file size = ( pqR+qR+p ) * WL
    RF_byte                                     =   256 * WL; 
%     Q_byte                                      =   get_buffer_size(A, J2, RF_byte);
    Q_byte                                      =   98304;
    [access, reuse, params, thruput]            =   rs_flow       (G, N, C, M, H, R, E, U, alpha, J2, Q_byte, RF_byte, WL, num_trials);
    [~, energy_cost]                            =   get_energy_cost(access);
elseif  ( strcmp(flow,'nlr') )
    % no local reuse:           register file size = 0
    RF_byte                                     =   0 * WL; 
    Q_byte                                      =   get_buffer_size(A, J2, RF_byte);
    [access, reuse, params, thruput]            =   nlr_flow      (N, C, M, H, R, E, U, alpha, J2, Q_byte, RF_byte, WL, num_trials);
    [~, energy_cost]                            =   get_energy_cost(access);
elseif  ( strcmp(flow,'os_ibm') )
    % output stationary (IBM):  register file size = 1 * WL
    RF_byte                                     =   1 * WL; 
    Q_byte                                      =   get_buffer_size(A, J2, RF_byte);
    [access, reuse, params, thruput]            =   os_ibm_flow   (N, C, M, H, R, E, U, alpha, J2, Q_byte, RF_byte, WL, num_trials);
    [~, energy_cost]                            =   get_energy_cost(access);
elseif  ( strcmp(flow,'os_sdn') )
    % output stationary (SDN):  register file size = (U+RU) * WL
    RF_byte                                     =   (U+R*U) * WL; 
    Q_byte                                      =   get_buffer_size(A, J2, RF_byte);
    [access, reuse, params, thruput]            =   os_sdn_flow   (N, C, M, H, R, E, U, alpha, J2, Q_byte, RF_byte, WL, num_trials);
    [~, energy_cost]                            =   get_energy_cost(access);
elseif  ( strcmp(flow,'ws') )
    % weight stationary:        register file size = ( q+1 ) * WL
    RF_byte                                     =   128 * WL; 
    Q_byte                                      =   get_buffer_size(A, J2, RF_byte);
    [access, reuse, params, thruput]            =   ws_flow       (N, C, M, H, R, E, U, alpha, J2, Q_byte, RF_byte, WL, num_trials);
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

