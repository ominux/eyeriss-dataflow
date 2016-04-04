close all; clear; clc; 

%% parameter setup --------------------------------------------------------

% number of PEs
J                                               =   256;
% word length [in bytes]
WL                                              =   2;
% batch size
N                                               =   16;
% AlexNet layer ID
alexnet_layer_id                                =   2;
% RF size sweep range
RF_bytes                                        =   32:32:512;
% number of trials to run optimization in order to avoid local minimal
num_trials                                      =   5;

%% setup project ----------------------------------------------------------

project_root = project_setup();

%% parallel computation setup ---------------------------------------------

curr_parpool = gcp('nocreate');
if isempty(curr_parpool)
    parpool('local');
end

%% get default area -------------------------------------------------------

% RF size for default storage area
RF_byte_default                                 =   512;
% default storage area
A                                               =   get_total_storage_area(J, J*RF_byte_default, RF_byte_default);

%% get CNN model parameters -----------------------------------------------

% get alexnet parameters
model_params                                    =   get_alexnet_params(alexnet_layer_id);

%% get energy ratio across memory hierarchies -----------------------------

energy_ratios                               =   get_energy_ratios();

%% collect meta data ------------------------------------------------------

meta.J                                          =   J;
meta.WL                                         =   WL;
meta.N                                          =   N;
meta.A                                          =   A;
meta.RF_bytes                                   =   RF_bytes;
meta.alexnet_layer_id                           =   alexnet_layer_id;
meta.energy_ratios                              =   energy_ratios;

%% run flow --------------------------------------------------------------------

% result arrays
num_RF_bytes                                    =   numel(RF_bytes);
results                                         =   cell(num_RF_bytes);
    
% run flow optimization
parfor i = 1:num_RF_bytes
        Q_byte                                  =   get_buffer_size(A, J, RF_bytes(i));
        [results{i}.access, ~, params, results{i}.thruput] ...
                                                =   rs_flow(N, model_params, J, Q_byte, RF_bytes(i), WL, energy_ratios, num_trials); 
        % collect result
        params.RF_byte                          =   RF_bytes(i);
        params.Q_byte                           =   Q_byte;
        params.total_storage_byte               =   (RF_bytes(i)*J + Q_byte);
        results{i}.params                       =   params;
end

%% save results -----------------------------------------------------------

save([project_root filesep 'results' filesep 'test_sweep_rs_rf_size_' datestr(datetime, 'yymmdd-HHMMSS')], 'meta', 'results');
