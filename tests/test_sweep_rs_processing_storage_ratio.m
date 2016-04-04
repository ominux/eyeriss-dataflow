close all; clear; clc; 

%% parameter setup -------------------------------------------------------------

% word length [in bytes]
WL                                          =   2;
% batch size
N                                           =   16;
% layer ID of AlexNet
alexnet_layer_ids                           =   [1 2 3 4 5];
% number of PEs
Js                                          =   [32 64 96 128 160 192 224 256 288];
% RF size
RF_bytes                                    =   [1024 768 512 256];

% times to run optimization to avoid local minima
num_trials                                  =   500;

%% setup project ---------------------------------------------------------------

project_root = project_setup();

%% parallel computation setup --------------------------------------------------

curr_parpool = gcp('nocreate');
if isempty(curr_parpool)
    parpool('local');
end

%% default area ----------------------------------------------------------------

% number of PEs for default area
J_default                                   =   256;
% RF size for default area
RF_byte_default                             =   512;
% buffer size for default area
Q_byte_default                              =   J_default * RF_byte_default;
% default total area (processing + storage)
B                                           =   (J_default * get_pe_area()) + ...
                                                (J_default * get_storage_area_from_size(RF_byte_default)) + ...
                                                get_storage_area_from_size(Q_byte_default);

%% get energy ratio across memory hierarchies -----------------------------

energy_ratios                               =   get_energy_ratios();

%% meta data -------------------------------------------------------------------

meta.Js                                     =   Js;
meta.RF_bytes                               =   RF_bytes;
meta.WL                                     =   WL;
meta.N                                      =   N;
meta.alexnet_layer_ids                      =   alexnet_layer_ids;
meta.energy_ratios                          =   energy_ratios;

%% run flow --------------------------------------------------------------------

num_Js                                      =   numel(Js);
num_RF_bytes                                =   numel(RF_bytes);
num_threads                                 =   num_Js * num_RF_bytes;
% cell to store results
results                                     =   cell(1, num_threads);
% thread helper vectors
J_threads                                   =   repmat(Js, [1, num_RF_bytes]);
RF_byte_threads                             =   reshape(repmat(RF_bytes, [num_Js 1]), [num_threads 1])';

parfor i = 1:num_threads
    % get storage areas    
    J                                       =   J_threads(i);
    A                                       =   B - ( J * get_pe_area() );
    RF_byte                                 =   RF_byte_threads(i);
    Q_byte                                  =   get_buffer_size(A, J, RF_byte);
    % print thread info
    fprintf('  Thread #%d (J = %d, RF byte = %d, Q byte = %d) \n', i, J, RF_byte, Q_byte);
    if Q_byte == 0
        results{i}.num_ops                  =   0;
        results{i}.thruput                  =   0;
        results{i}.access                   =   0;
        results{i}.params                   =   0;
    else
        results{i}.params.J                 =   J;
        results{i}.params.RF_byte           =   RF_byte;
        results{i}.params.Q_byte            =   Q_byte;
        results{i}.num_ops                  =   0;
        results{i}.latency                  =   0;
        results{i}.access.memory.reads      =   0;
        results{i}.access.memory.writes     =   0;
        results{i}.access.buffer.reads      =   0;
        results{i}.access.buffer.writes     =   0;
        results{i}.access.array.wiring      =   0;
        results{i}.access.reg.reads         =   0;
        results{i}.access.reg.writes        =   0;
        for layer = alexnet_layer_ids
            % get current layer parameters
            model_params                    =   get_alexnet_params(layer);
            % run RS dataflow
            [curr_access, ~, ~, curr_thruput] ...   
                                            =   rs_flow(N, model_params, J, Q_byte, RF_byte, WL, energy_ratios, num_trials); 
            % collect data
            results{i}.num_ops              =   results{i}.num_ops + curr_access.alu;
            results{i}.latency              =   results{i}.latency + (curr_access.alu / curr_thruput.active_pes);
            results{i}.access.memory.reads  =   results{i}.access.memory.reads  + curr_access.memory.reads.total;
            results{i}.access.memory.writes =   results{i}.access.memory.writes + curr_access.memory.writes.total;
            results{i}.access.buffer.reads  =   results{i}.access.buffer.reads  + curr_access.buffer.reads.total;
            results{i}.access.buffer.writes =   results{i}.access.buffer.writes + curr_access.buffer.writes.total;
            results{i}.access.array.wiring  =   results{i}.access.array.wiring  + curr_access.array.wiring.total;
            results{i}.access.reg.reads     =   results{i}.access.reg.reads     + curr_access.reg.reads.total;
            results{i}.access.reg.writes    =   results{i}.access.reg.writes    + curr_access.reg.writes.total;
        end
        results{i}.thruput                  =   results{i}.num_ops/results{i}.latency;
    end
end

results                                     =   reshape(results, [num_Js num_RF_bytes]);

%% save results ----------------------------------------------------------------

save([project_root filesep 'results' filesep 'test_sweep_rs_processing_storage_ratio_' datestr(datetime, 'yymmdd-HHMMSS')], 'meta', 'results');
