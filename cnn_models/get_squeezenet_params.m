function model_params = get_squeezenet_params(layer_id)
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
    
    if      layer_id == 1   % conv1
        model_params.H      =   227;
        model_params.R      =   7;
        model_params.U      =   2;
        model_params.C      =   3;
        model_params.M      =   96;
        model_params.P      =   0;
    elseif  layer_id == 2   % fire2-s
        model_params.H      =   55;
        model_params.R      =   1;
        model_params.U      =   1;
        model_params.C      =   96;
        model_params.M      =   16;
        model_params.P      =   0;
    elseif  layer_id == 3   % fire2-e1
        model_params.H      =   55;
        model_params.R      =   1;
        model_params.U      =   1;
        model_params.C      =   16;
        model_params.M      =   64;
        model_params.P      =   0;
    elseif  layer_id == 4   % fire2-e3
        model_params.H      =   57;
        model_params.R      =   3;
        model_params.U      =   1;
        model_params.C      =   16;
        model_params.M      =   64;
        model_params.P      =   1;
    elseif  layer_id == 5   % fire3-s
        model_params.H      =   55;
        model_params.R      =   1;
        model_params.U      =   1;
        model_params.C      =   128;
        model_params.M      =   16;
        model_params.P      =   0;
    elseif  layer_id == 6   % fire3-e1
        model_params.H      =   55;
        model_params.R      =   1;
        model_params.U      =   1;
        model_params.C      =   16;
        model_params.M      =   64;
        model_params.P      =   0;
    elseif  layer_id == 7   % fire3-e3
        model_params.H      =   57;
        model_params.R      =   3;
        model_params.U      =   1;
        model_params.C      =   16;
        model_params.M      =   64;
        model_params.P      =   1;
    elseif  layer_id == 8   % fire4-s
        model_params.H      =   55;
        model_params.R      =   1;
        model_params.U      =   1;
        model_params.C      =   128;
        model_params.M      =   32;
        model_params.P      =   0;
    elseif  layer_id == 9   % fire4-e1
        model_params.H      =   55;
        model_params.R      =   1;
        model_params.U      =   1;
        model_params.C      =   32;
        model_params.M      =   128;
        model_params.P      =   0;
    elseif  layer_id == 10  % fire4-e3
        model_params.H      =   57;
        model_params.R      =   3;
        model_params.U      =   1;
        model_params.C      =   32;
        model_params.M      =   128;
        model_params.P      =   1;
    elseif  layer_id == 11  % fire5-s    
        model_params.H      =   27;
        model_params.R      =   1;
        model_params.U      =   1;
        model_params.C      =   256;
        model_params.M      =   32;
        model_params.P      =   0;
    elseif  layer_id == 12  % fire5-e1
        model_params.H      =   27;
        model_params.R      =   1;
        model_params.U      =   1;
        model_params.C      =   32;
        model_params.M      =   128;
        model_params.P      =   0;
    elseif  layer_id == 13  % fire5-e3
        model_params.H      =   29;
        model_params.R      =   3;
        model_params.U      =   1;
        model_params.C      =   32;
        model_params.M      =   128;
        model_params.P      =   1;
    elseif  layer_id == 14  % fire6-s
        model_params.H      =   27;
        model_params.R      =   1;
        model_params.U      =   1;
        model_params.C      =   256;
        model_params.M      =   48;
        model_params.P      =   0;
    elseif  layer_id == 15  % fire6-e1
        model_params.H      =   27;
        model_params.R      =   1;
        model_params.U      =   1;
        model_params.C      =   48;
        model_params.M      =   192;
        model_params.P      =   0;
    elseif  layer_id == 16  % fire6-e3
        model_params.H      =   29;
        model_params.R      =   3;
        model_params.U      =   1;
        model_params.C      =   48;
        model_params.M      =   192;
        model_params.P      =   1;
    elseif  layer_id == 17  % fire7-s
        model_params.H      =   27;
        model_params.R      =   1;
        model_params.U      =   1;
        model_params.C      =   384;
        model_params.M      =   48;
        model_params.P      =   0;
    elseif  layer_id == 18  % fire7-e1
        model_params.H      =   27;
        model_params.R      =   1;
        model_params.U      =   1;
        model_params.C      =   48;
        model_params.M      =   192;
        model_params.P      =   0;
    elseif  layer_id == 19  % fire7-e3
        model_params.H      =   29;
        model_params.R      =   3;
        model_params.U      =   1;
        model_params.C      =   48;
        model_params.M      =   192;
        model_params.P      =   1;
    elseif  layer_id == 20  % fire8-s
        model_params.H      =   27;
        model_params.R      =   1;
        model_params.U      =   1;
        model_params.C      =   384;
        model_params.M      =   64;
        model_params.P      =   0;
    elseif  layer_id == 21  % fire8-e1
        model_params.H      =   27;
        model_params.R      =   1;
        model_params.U      =   1;
        model_params.C      =   64;
        model_params.M      =   256;
        model_params.P      =   0;
    elseif  layer_id == 22  % fire8-e3
        model_params.H      =   29;
        model_params.R      =   3;
        model_params.U      =   1;
        model_params.C      =   64;
        model_params.M      =   256;
        model_params.P      =   1;
    elseif  layer_id == 23  % fire9-s
        model_params.H      =   13;
        model_params.R      =   1;
        model_params.U      =   1;
        model_params.C      =   512;
        model_params.M      =   64;
        model_params.P      =   0;
    elseif  layer_id == 24  % fire9-e1
        model_params.H      =   13;
        model_params.R      =   1;
        model_params.U      =   1;
        model_params.C      =   64;
        model_params.M      =   256;
        model_params.P      =   0;
    elseif  layer_id == 25  % fire9-e3
        model_params.H      =   15;
        model_params.R      =   3;
        model_params.U      =   1;
        model_params.C      =   64;
        model_params.M      =   256;
        model_params.P      =   1;
    elseif  layer_id == 26  % conv10
        model_params.H      =   13;
        model_params.R      =   1;
        model_params.U      =   1;
        model_params.C      =   512;
        model_params.M      =   1000;
        model_params.P      =   0;
    else
        error('Incorrect layer ID. Valid range: [1 26].');
    end
    
    model_params.W      =   model_params.H;
    model_params.S      =   model_params.R;
    
    % output fmap height/width
    model_params.E          =   (model_params.H + model_params.U - model_params.R) / model_params.U; 
    model_params.F          =   (model_params.W + model_params.U - model_params.S) / model_params.U;
    % alpha_v = E/H, alpha_h = F/W
    model_params.alpha_v    =   model_params.E/model_params.H;
    model_params.alpha_h    =   model_params.F/model_params.W;
    
    model_params.G      =   1;
end
