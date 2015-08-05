function [H, R, U, C, M, E, alpha] = get_alexnet_params(layer_id)

    % H: input fmap size (width = height)
    % R: filter size (width = height)
    % U: stride size
    % C: number of channels
    % M: number of filters
    
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
    else
        error('Incorrect layer ID. Valid range: [1 5].');
    end

    % output fmap size (width = height)
    E                                           =   (H + U - R) / U;  
    % alpha = E/H
    alpha                                       =   E/H;

end