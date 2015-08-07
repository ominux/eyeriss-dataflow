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
N                                           =   64;             % [1 16 64 128];
% layer ID of AlexNet
alexnet_layer_id                            =   [1 2 3 4 5];    % [1 2 3 4 5];
% number of PEs
J2                                          =   [128 256];

% number of PEs for default area
J2_default                                  =   256;
% RF size for default area
G_byte_default                              =   512;
% buffer size for default area
Q_byte_default                              =   J2_default * G_byte_default;
% default area
B                                           =   J2_default * get_pe_area() + ...
                                                J2_default * get_storage_area_from_size(G_byte_default) + ...
                                                get_storage_area_from_size(Q_byte_default);

% times to run optimization to avoid local minima
num_trials                                  =   300;

%% run flow --------------------------------------------------------------------