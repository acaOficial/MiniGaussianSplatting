function setup_paths()
    root = fileparts(mfilename('fullpath'));
    addpath(fullfile(root));
    addpath(fullfile(root, 'utils'));
    addpath(fullfile(root, '..', 'cpp'));
end
