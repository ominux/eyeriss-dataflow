function [G, H, R, U, C, M, E, alpha, P] = get_alexnet_params(layer_id)

    % H: input fmap size (padded, width = height)
    % R: filter size (width = height)
    % U: stride size
    % C: number of channels
    % M: number of filters
    % G: number of groups
    % P: padding on each side
    
    if      layer_id == 1
        H                           =   227;
        R                           =   11;
        U                           =   4;
        C                           =   3;
        M                           =   96;
        G                           =   1;
        P                           =   0;
    elseif  layer_id == 2
        H                           =   31;
        R                           =   5;
        U                           =   1;
        C                           =   48;
        M                           =   128;
        G                           =   2;
        P                           =   2;
    elseif  layer_id == 3
        H                           =   15;
        R                           =   3;
        U                           =   1;
        C                           =   256;
        M                           =   384;
        G                           =   1;
        P                           =   1;
    elseif  layer_id == 4
        H                           =   15;
        R                           =   3;
        U                           =   1;
        C                           =   192;
        M                           =   192;
        G                           =   2;
        P                           =   1;
    elseif  layer_id == 5
        H                           =   15;
        R                           =   3;
        U                           =   1;
        C                           =   192;
        M                           =   128;
        G                           =   2;
        P                           =   1;
    elseif  layer_id == 6
        H                           =   6;
        R                           =   6;
        U                           =   1;
        C                           =   256;
        M                           =   4096;
        G                           =   1;
        P                           =   0;
    elseif  layer_id == 7
        H                           =   1;
        R                           =   1;
        U                           =   1;
        C                           =   4096;
        M                           =   4096;
        G                           =   1;
        P                           =   0;
    elseif  layer_id == 8
        H                           =   1;
        R                           =   1;
        U                           =   1;
        C                           =   4096;
        M                           =   1000;
        G                           =   1;
        P                           =   0;
    else
        error('Incorrect layer ID. Valid range: [1 8].');
    end

    % output fmap size (width = height)
    E                                           =   (H + U - R) / U;  
    % alpha = E/H
    alpha                                       =   E/H;

end