function model_params = get_alexnet_params(layer_id)
    % G:        number of groups
    % H/W:      input fmap height/width (padded)
    % R/S:      filter height/width
    % U:        stride size
    % C:        number of channels
    % M:        number of filters
    % E/F:      output fmap height/width
    % alpha_v:  E/H
    % alpha_h:  F/W
    % P: padding on each side
    
    if      layer_id == 1
        model_params.H      =   227;
        model_params.W      =   model_params.H;
        model_params.R      =   11;
        model_params.S      =   model_params.R;
        model_params.U      =   4;
        model_params.C      =   3;
        model_params.M      =   96;
        model_params.G      =   1;
        model_params.P      =   0;
    elseif  layer_id == 2
        model_params.H      =   31;
        model_params.W      =   model_params.H;
        model_params.R      =   5;
        model_params.S      =   model_params.R;
        model_params.U      =   1;
        model_params.C      =   48;
        model_params.M      =   128;
        model_params.G      =   2;
        model_params.P      =   2;
    elseif  layer_id == 3
        model_params.H      =   15;
        model_params.W      =   model_params.H;
        model_params.R      =   3;
        model_params.S      =   model_params.R;
        model_params.U      =   1;
        model_params.C      =   256;
        model_params.M      =   384;
        model_params.G      =   1;
        model_params.P      =   1;
    elseif  layer_id == 4
        model_params.H      =   15;
        model_params.W      =   model_params.H;
        model_params.R      =   3;
        model_params.S      =   model_params.R;
        model_params.U      =   1;
        model_params.C      =   192;
        model_params.M      =   192;
        model_params.G      =   2;
        model_params.P      =   1;
    elseif  layer_id == 5
        model_params.H      =   15;
        model_params.W      =   model_params.H;
        model_params.R      =   3;
        model_params.S      =   model_params.R;
        model_params.U      =   1;
        model_params.C      =   192;
        model_params.M      =   128;
        model_params.G      =   2;
        model_params.P      =   1;
    elseif  layer_id == 6
        model_params.H      =   6;
        model_params.W      =   model_params.H;
        model_params.R      =   6;
        model_params.S      =   model_params.R;
        model_params.U      =   1;
        model_params.C      =   256;
        model_params.M      =   4096;
        model_params.G      =   1;
        model_params.P      =   0;
    elseif  layer_id == 7
        model_params.H      =   1;
        model_params.W      =   model_params.H;
        model_params.R      =   1;
        model_params.S      =   model_params.R;
        model_params.U      =   1;
        model_params.C      =   4096;
        model_params.M      =   4096;
        model_params.G      =   1;
        model_params.P      =   0;
    elseif  layer_id == 8
        model_params.H      =   1;
        model_params.W      =   model_params.H;
        model_params.R      =   1;
        model_params.S      =   model_params.R;
        model_params.U      =   1;
        model_params.C      =   4096;
        model_params.M      =   1000;
        model_params.G      =   1;
        model_params.P      =   0;
    else
        error('Incorrect layer ID. Valid range: [1 8].');
    end

    % output fmap height/width
    model_params.E          =   (model_params.H + model_params.U - model_params.R) / model_params.U; 
    model_params.F          =   (model_params.W + model_params.U - model_params.S) / model_params.U;
    % alpha_v = E/H, alpha_h = F/W
    model_params.alpha_v    =   model_params.E/model_params.H;
    model_params.alpha_h    =   model_params.F/model_params.W;

end
