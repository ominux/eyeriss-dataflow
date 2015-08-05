function [H, R, U, C, M] = get_alexnet_params(layer_id)

H                               =   0;
R                               =   0;
U                               =   0;
C                               =   0;
M                               =   0;

if      layer_id == 1
    H                           =   227;
    R                           =   11;
    U                           =   4;
    C                           =   3;
    M                           =   96;
elseif  layer_id == 2
    H                           =   31;
    R                           =   5;
    U                           =   1;
    C                           =   48;
    M                           =   128;
elseif  layer_id == 3
    H                           =   15;
    R                           =   3;
    U                           =   1;
    C                           =   256;
    M                           =   384;
elseif  layer_id == 4
    H                           =   15;
    R                           =   3;
    U                           =   1;
    C                           =   192;
    M                           =   192;
elseif  layer_id == 5
    H                           =   15;
    R                           =   3;
    U                           =   1;
    C                           =   192;
    M                           =   128;
end
    
end