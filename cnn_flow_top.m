close all; clear; clc; 

%% setup project ----------------------------------------------------------

project_setup();

%% problem size parameters ------------------------------------------------

% batch_size
N                                           =   16;
% choose a layer in the CNN model to run the tests
% available models: alexnet, vgg16
alexnet_layer_id                            =   4;
% get CNN model parameters
model_params                                =   get_alexnet_params(alexnet_layer_id);
% word length [in bytes]
WL                                          =   2;

%% architecture parameters ------------------------------------------------

% total number of PEs (J^2)
J                                           =   256;
% choose flow: 'rs', 'ws', 'nlr'
flow                                        =   'nlr';
                                          
%% other parameters -------------------------------------------------------

% number of trials to run optimization in order to avoid local minimal
num_trials                                  =   1;

%% calculate default area -------------------------------------------------

% default number of PEs
J_default                                   =   256;
% RF size for default area
RF_byte_default                             =   512;
% buffer size for default area
Q_byte_default                              =   J_default * RF_byte_default;
% total area (processing + storge) [um^2]
B                                           =   J_default * get_pe_area() + ...
                                                J_default * get_storage_area_from_size(RF_byte_default) + ...
                                                get_storage_area_from_size(Q_byte_default);
% total storage area (buff + RF) [um^2]
A                                           =   B - J * get_pe_area();
  
%% get energy ratio across memory hierarchies -----------------------------

energy_ratios                               =   get_energy_ratios();

%% flows ------------------------------------------------------------------

% G_byte: register file size per PE [byte]
% Q_byte: buffe size [byte]

if      ( strcmp(flow,'rs') )
    % row stationary:           register file size = ( pqR+qR+p ) * WL
    RF_byte                                     =   256 * WL; 
    Q_byte                                      =   get_buffer_size(A, J, RF_byte);
    [access, reuse, params, thruput]            =   rs_flow         (N, model_params, J, Q_byte, RF_byte, WL, energy_ratios, num_trials);
elseif  ( strcmp(flow,'ws') )
    % row stationary:           register file size = ( pqR+qR+p ) * WL
    RF_byte                                     =   1 * WL; 
    Q_byte                                      =   get_buffer_size(A, J, RF_byte);
    [access, reuse, params, thruput]            =   ws_flow         (N, model_params, J, Q_byte, RF_byte, WL, energy_ratios, num_trials);
elseif  ( strcmp(flow,'nlr') )
    % row stationary:           register file size = ( pqR+qR+p ) * WL
    RF_byte                                     =   0; 
    Q_byte                                      =   get_buffer_size(A, J, RF_byte);
    [access, reuse, params, thruput]            =   nlr_flow        (N, model_params, J, Q_byte, RF_byte, WL, energy_ratios, num_trials);
else
    error(['Cannot recognize the specified dataflow: ''' flow '''.']);
end

