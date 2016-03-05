close all; clear; clc;

%% parameters ------------------------------------------------------------------

% total number of PEs (J^2)
J2                                          =   256;

% word length [in bytes]
WL                                          =   2;

%% default area ----------------------------------------------------------------

% default number of PEs
J2_default                                  =   256;
% RF size for default area
G_byte_default                              =   512;
% buffer size for default area
Q_byte_default                              =   J2_default * G_byte_default;
% total area (processing + storge) [um^2]
B                                           =   J2_default * get_pe_area() + ...
                                                J2_default * get_storage_area_from_size(G_byte_default) + ...
                                                get_storage_area_from_size(Q_byte_default);
% total storage area (buff + RF) [um^2]
A                                           =   B - J2 * get_pe_area();
                                            
%% flow area allocation --------------------------------------------------------

rs_G_byte                                   =   256 * WL;
rs_Q_byte                                   =   get_buffer_size(A, J2, rs_G_byte);


nlr_G_byte                                  =   0;
nlr_Q_byte                                  =   get_buffer_size(A, J2, nlr_G_byte);


os_ibm_G_byte                               =   1 * WL;
os_ibm_Q_byte                               =   get_buffer_size(A, J2, os_ibm_G_byte);


os_sdn_G_byte                               =   (11*4 + 4) * WL; % (UR+U), R=11, U=4
os_sdn_Q_byte                               =   get_buffer_size(A, J2, os_sdn_G_byte);


ws_G_byte                                   =   128 * WL;
ws_Q_byte                                   =   get_buffer_size(A, J2, ws_G_byte);

%% data write out --------------------------------------------------------------


ofile = fopen('results/flow_storage_area_comparison.txt', 'w');

fprintf(ofile, '%d, %d\n', rs_Q_byte, rs_G_byte);
fprintf(ofile, '%d, %d\n', nlr_Q_byte, nlr_G_byte);
fprintf(ofile, '%d, %d\n', os_ibm_Q_byte, os_ibm_G_byte);
fprintf(ofile, '%d, %d\n', os_sdn_Q_byte, os_sdn_G_byte);
fprintf(ofile, '%d, %d\n', ws_Q_byte, ws_G_byte);

fclose(ofile);

















