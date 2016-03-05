function [G, H, R, U, C, M, E, alpha, P] = get_vgg16_params(layer_id)

    % H: input fmap size (width = height)
    % R: filter size (width = height)
    % U: stride size
    % C: number of channels
    % M: number of filters
    % G: number of groups
    % P: padding on each side
    
    if      layer_id == 1
        H                           =   226;
        R                           =   3;
        U                           =   1;
        C                           =   3;
        M                           =   64;
        G                           =   1;
        P                           =   1;
    elseif  layer_id == 2
        H                           =   226;
        R                           =   3;
        U                           =   1;
        C                           =   64;
        M                           =   64;
        G                           =   1;
        P                           =   1;
    elseif  layer_id == 3
        H                           =   114;
        R                           =   3;
        U                           =   1;
        C                           =   64;
        M                           =   128;
        G                           =   1;
        P                           =   1;
    elseif  layer_id == 4
        H                           =   114;
        R                           =   3;
        U                           =   1;
        C                           =   128;
        M                           =   128;
        G                           =   1;
        P                           =   1;
    elseif  layer_id == 5
        H                           =   58;
        R                           =   3;
        U                           =   1;
        C                           =   128;
        M                           =   256;
        G                           =   1;
        P                           =   1;
    elseif  layer_id == 6
        H                           =   58;
        R                           =   3;
        U                           =   1;
        C                           =   256;
        M                           =   256;
        G                           =   1;
        P                           =   1;
    elseif  layer_id == 7
        H                           =   58;
        R                           =   3;
        U                           =   1;
        C                           =   256;
        M                           =   256;
        G                           =   1;
        P                           =   1;
    elseif  layer_id == 8
        H                           =   30;
        R                           =   3;
        U                           =   1;
        C                           =   256;
        M                           =   512;
        G                           =   1;
        P                           =   1;
    elseif  layer_id == 9
        H                           =   30;
        R                           =   3;
        U                           =   1;
        C                           =   512;
        M                           =   512;
        G                           =   1;
        P                           =   1;
    elseif  layer_id == 10
        H                           =   30;
        R                           =   3;
        U                           =   1;
        C                           =   512;
        M                           =   512;
        G                           =   1;
        P                           =   1;
    elseif  layer_id == 11
        H                           =   16;
        R                           =   3;
        U                           =   1;
        C                           =   512;
        M                           =   512;
        G                           =   1;
        P                           =   1;
    elseif  layer_id == 12
        H                           =   16;
        R                           =   3;
        U                           =   1;
        C                           =   512;
        M                           =   512;
        G                           =   1;
        P                           =   1;
    elseif  layer_id == 13
        H                           =   16;
        R                           =   3;
        U                           =   1;
        C                           =   512;
        M                           =   512;
        G                           =   1;
        P                           =   1;
    else
        error('Incorrect layer ID. Valid range: [1 13].');
    end

    % output fmap size (width = height)
    E                                           =   (H + U - R) / U;  
    % alpha = E/H
    alpha                                       =   E/H;

end