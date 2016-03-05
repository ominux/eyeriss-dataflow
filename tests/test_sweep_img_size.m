close all; clear; clc; 

%% setup project ---------------------------------------------------------------

project_setup();

%% problem size parameters -----------------------------------------------------

% batch_size
N                                           =   4;
% choose the layer in AlexNet to run the tests
alexnet_layer_id                            =   4;
[G, ~, R, U, C, M, ~, ~, P]                 =   get_alexnet_params(alexnet_layer_id);
H = 31 + (2*P);
E = (H + U - R) / U;
alpha = E/H;
% word length [in bytes]
WL                                          =   2;

%% architecture parameters -----------------------------------------------------

% total number of PEs (J^2)
J2                                          =   168;
% register file size (in byte)
RF_byte                                     =   256 * WL; 
% buffer size (in byte)
Q_byte                                      =   98304;

%% other parameters ------------------------------------------------------------

% number of trials to run optimization in order to avoid local minimal
num_trials                                  =   50;

%% run dataflow ----------------------------------------------------------------

% row stationary dataflow
[access, reuse, params, thruput]            =   rs_flow(G, N, C, M, H, R, E, U, alpha, J2, Q_byte, RF_byte, WL, num_trials);

%% -----------------------------------------------------------------------------
