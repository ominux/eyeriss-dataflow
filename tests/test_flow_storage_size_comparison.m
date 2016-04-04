close all; clear; clc;

%% parameters ------------------------------------------------------------------

% total number of PEs (J^2)
J                                          =   256;

% word length [in bytes]
WL                                          =   2;

%% setup project ---------------------------------------------------------------

project_root = project_setup();

%% default area ----------------------------------------------------------------

% default number of PEs
J_default                                   =   256;
% RF size for default area
RF_byte_default                             =   512;
% buffer size for default area
Q_byte_default                              =   J_default * RF_byte_default;
% total area (processing + storge) [um^2]
B                                           =   (J_default * get_pe_area()) + ...
                                                (J_default * get_storage_area_from_size(RF_byte_default)) + ...
                                                get_storage_area_from_size(Q_byte_default);
% total storage area (buff + RF) [um^2]
A                                           =   B - (J*get_pe_area());
                                            
%% flow area allocation --------------------------------------------------------

% RS dataflow
results.RS.RF_byte                          =   256 * WL;
results.RS.Q_byte                           =   get_buffer_size(A, J, results.RS.RF_byte);
% WS dataflow
results.WS.RF_byte                          =   1 * WL;
results.WS.Q_byte                           =   get_buffer_size(A, J, results.WS.RF_byte);
% OS SOC-MOP dataflow
results.OS_SOC_MOP.RF_byte                  =   (11*4 + 4 + 1) * WL; % (UR+U+1), R=11, U=4
results.OS_SOC_MOP.Q_byte                   =   get_buffer_size(A, J, results.OS_SOC_MOP.RF_byte);
% OS MOC-MOP dataflow
results.OS_MOC_MOP.RF_byte                  =   1 * WL;
results.OS_MOC_MOP.Q_byte                   =   get_buffer_size(A, J, results.OS_MOC_MOP.RF_byte);
% OS MOC-SOP dataflow
results.OS_MOC_SOP.RF_byte                  =   1 * WL;
results.OS_MOC_SOP.Q_byte                   =   get_buffer_size(A, J, results.OS_MOC_SOP.RF_byte);
% NLR dataflow
results.NLR.RF_byte                         =   0;
results.NLR.Q_byte                          =   get_buffer_size(A, J, results.NLR.RF_byte);

%% save output ------------------------------------------------------------

save([project_root filesep 'results' filesep 'test_flow_storage_size_comparison_' datestr(datetime, 'yymmdd-HHMMSS')], 'results');

