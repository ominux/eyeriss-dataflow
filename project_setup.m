function    project_setup()

    project_root   =   fileparts(mfilename('fullpath'));

    addpath([project_root filesep 'cnn_dataflows']);
    addpath([project_root filesep 'cnn_models']);
    addpath([project_root filesep 'helpers']);
    addpath([project_root filesep 'misc']);
end
