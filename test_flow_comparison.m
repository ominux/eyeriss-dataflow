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
% number of PEs
J2                                          =   [256 512];      % [128 256 512 1024];
% batch size
N                                           =   64;             % [1 16 64 128];
% layer ID of AlexNet
alexnet_layer_id                            =   [1 2 3 4 5];    % [1 2 3 4 5];
% RF size for default area
G_byte_default                              =   512;
% times to run optimization to avoid local minima
num_trials                                  =   300;

%% run all flows ---------------------------------------------------------------

if enable_multicores
    total_num_threads                       =   length(J2) * length(N) * length(alexnet_layer_id);
    % results cell
    results                                 =   cell(1, total_num_threads);
    fprintf('\n\n');    
    parfor par_th= 1:total_num_threads
        k                                   =   floor( (par_th-1)/(length(J2) * length(N)) ) + 1;
        j                                   =   floor( ((par_th - (k-1)*length(J2)*length(N))-1)/length(J2) ) + 1;
        i                                   =   par_th - (k-1)*length(J2)*length(N) - (j-1)*length(J2);
        fprintf('  Thread #%d (%d, %d, %d) Running... <J2 = %d, N = %d, AlexNet Layer ID = %d>\n', par_th, i, j, k, J2(i), N(j), alexnet_layer_id(k));
        
        A                                   =   get_total_storage_area(J2(i), J2(i)*G_byte_default, G_byte_default);
        results{par_th}                     =   run_all_flows(J2(i), A, N(j), alexnet_layer_id(k), WL, num_trials);
    end
    results                                 =   reshape(results, [length(J2) length(N) length(alexnet_layer_id)]);
else
    % results cell
    results                                 =   cell(length(J2), length(N), length(alexnet_layer_id));
    for i = 1:length(J2)
        A                                   =   get_total_storage_area(J2(i), J2(i)*G_byte_default, G_byte_default);
        for j = 1:length(N)
            for k = 1:length(alexnet_layer_id)
                results{i, j, k}            =   run_all_flows(J2(i), A, N(j), alexnet_layer_id(k), WL, num_trials);
            end
        end
    end
end

save('results/test_flow_comparison_results_256_512', 'results');

% fig4    = figure();
% axes4   = axes('Parent', fig4, 'XTickLabel',{'RS', 'UCLA', 'IBM', 'SDN', 'WS'}, 'FontSize', 20);
% hold on; grid on;
% bar(results{1, 1, 1}.energy);
% ylabel('Normalized Energy', 'fontsize', 20);
% axis tight;

