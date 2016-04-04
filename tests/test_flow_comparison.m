close all; clear; clc; 

%% parameter config -------------------------------------------------------

% word length [in bytes]
WL                                          =   2;
% number of PEs
Js                                          =   [256 512 1024];     % [128 256 512 1024];
% batch size
Ns                                          =   [1 16 64];          % [1 16 64 128];
% CNN model name. (1) alexnet, (2) vgg16
model_name                                  =   'alexnet';
% ID of the CNN layer
layer_ids                                   =   [1 2 3 4 5 6 7 8];  % alexnet: 1-8, vgg: 1-16;
% RF size for default area [bytes]
RF_byte_default                             =   512;
% times to run optimization to avoid local minima
num_trials                                  =   1;

%% setup project ----------------------------------------------------------

project_root = project_setup();

%% parallel computation setup ---------------------------------------------

curr_parpool = gcp('nocreate');
if isempty(curr_parpool)
    parpool('local');
end

%% get CNN model handle ---------------------------------------------------

if      strcmp(model_name, 'alexnet')
    get_model_params            =   @get_alexnet_params;
elseif  strcmp(model_name, 'vgg16')
    get_model_params            =   @get_vgg16_params;
else
    error(['cannot recognize model name: ' model_name]);
end

%% get energy ratio across memory hierarchies -----------------------------

energy_ratios                               =   get_energy_ratios();

%% pack simulation info ---------------------------------------------------

meta.model_name                             =   model_name;
meta.Js                                     =   Js;
meta.Ns                                     =   Ns;
meta.layer_ids                              =   layer_ids;
meta.RF_byte_default                        =   RF_byte_default;
meta.WL                                     =   WL;
meta.energy_ratios                          =   energy_ratios;

%% run all flows ---------------------------------------------------------------

num_Js                                      =   numel(Js);
num_Ns                                      =   numel(Ns);
num_layers                                  =   numel(layer_ids);
num_threads                                 =   num_Js * num_Ns * num_layers;
% results cell
results                                     =   cell(1, num_threads);
% thread helpers
J_threads                                   =   repmat(Js, [1, (num_Ns*num_layers)]);
N_threads                                   =   reshape(repmat(Ns, [num_Js num_layers]), [num_threads 1])';
layer_id_threads                            =   reshape(repmat(layer_ids, [(num_Js*num_Ns) 1]), [num_threads 1])';

fprintf('\n\n');
fprintf(['Running CNN model: ''' model_name '''']);
parfor i= 1:num_threads
    J                                       =   J_threads(i);
    N                                       =   N_threads(i);
    layer_id                                =   layer_id_threads(i);
    fprintf('  Thread #%d Running... <J = %d, N = %d, AlexNet Layer ID = %d>\n', i, J, N, layer_id);
    
    A                                       =   get_total_storage_area(J, J*RF_byte_default, RF_byte_default);
    results{i}                              =   run_all_flows(N, get_model_params(layer_id), A, J, WL, energy_ratios, num_trials);
end
results                                     =   reshape(results, [length(Js) length(Ns) length(layer_ids)]);

%% save output ------------------------------------------------------------

save([project_root filesep 'results' filesep 'test_flow_comparison_' datestr(datetime, 'yymmdd-HHMMSS')], 'meta', 'results');
