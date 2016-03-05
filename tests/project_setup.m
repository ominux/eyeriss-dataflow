function    project_setup()

    project_root   =   fileparts(mfilename('fullpath'));

    addpath([project_root filesep '../' filesep 'cnn_dataflows']);
    addpath([project_root filesep '../' filesep 'cnn_models']);
    addpath([project_root filesep '../' filesep 'helpers']);
    addpath([project_root filesep '../' filesep 'misc']);
end
