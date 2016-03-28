close all; clear; clc; 

%% parameter config -------------------------------------------------------

% word length [in bytes]
WL                                          =   2;
% number of PEs
J                                           =   [256 512 1024];     % [128 256 512 1024];
% batch size
N                                           =   [1 16 64];          % [1 16 64 128];
% CNN model name. (1) alexnet, (2) vgg16
model_name                                  =   'alexnet';
% ID of the CNN layer
layer_id                                    =   [1 2 3 4 5 6 7 8];  % alexnet: 1-8, vgg: 1-16;
% RF size for default area [bytes]
RF_byte_default                             =   512;
% times to run optimization to avoid local minima
num_trials                                  =   300;

%% setup project ---------------------------------------------------------------

project_root = project_setup();

%% parallel computation setup --------------------------------------------------

% enable the use of multicores
enable_multicores                           =   1;

curr_parpool = gcp('nocreate');
if isempty(curr_parpool) && enable_multicores
    parpool('local');
end

%% pack simulation info --------------------------------------------------------

meta.model_name                             =   model_name;
meta.J                                      =   J;
meta.N                                      =   N;
meta.layer_id                               =   layer_id;
meta.RF_byte_default                        =   RF_byte_default;
meta.WL                                     =   WL;

%% run all flows ---------------------------------------------------------------

if enable_multicores
    total_num_threads                       =   length(J) * length(N) * length(layer_id);
    % results cell
    results                                 =   cell(1, total_num_threads);
    fprintf('\n\n');    
    parfor par_th= 1:total_num_threads
        k                                   =   floor( (par_th-1)/(length(J) * length(N)) ) + 1;
        j                                   =   floor( ((par_th - (k-1)*length(J)*length(N))-1)/length(J) ) + 1;
        i                                   =   par_th - (k-1)*length(J)*length(N) - (j-1)*length(J);
        fprintf('  Thread #%d (%d, %d, %d) Running... <J = %d, N = %d, AlexNet Layer ID = %d>\n', par_th, i, j, k, J(i), N(j), layer_id(k));
        
        A                                   =   get_total_storage_area(J(i), J(i)*RF_byte_default, RF_byte_default);
        results{par_th}                     =   run_all_flows(J(i), A, N(j), model_name, layer_id(k), WL, num_trials);
    end
    results                                 =   reshape(results, [length(J) length(N) length(layer_id)]);
else
    % results cell
    results                                 =   cell(length(J), length(N), length(layer_id));
    for i = 1:length(J)
        A                                   =   get_total_storage_area(J(i), J(i)*RF_byte_default, RF_byte_default);
        for j = 1:length(N)
            for k = 1:length(layer_id)
                results{i, j, k}            =   run_all_flows(J(i), A, N(j), model_name, layer_id(k), WL, num_trials);
            end
        end
    end
end

save([project_root filesep 'results' filesep 'test_flow_comparison_' datestr(datetime, 'yymmdd-HHMMSS')], 'meta', 'results');
