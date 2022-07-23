function reclist = list_recordings(infolder)

    subfolders = list_dirs(infolder);
    reclist = {};
    
    if ~isempty(subfolders)
        for folder = 1:size(subfolders, 2)
            files = sh_rdir(fullfile(infolder, subfolders{folder}), ...
                {'.mat'}, {'analysis', 'info', 'BiomarkerBase', ...
                'ASDvsTDC', 'NBTelementBase', 'NBTstudy', 'BED', '_RocheLeap'}, 1);
            reclist = [reclist, files];
        end
    else
        reclist = sh_rdir(fullfile(infolder), ...
                {'.mat'}, {'analysis', 'info', 'BiomarkerBase', ...
                'ASDvsTDC', 'NBTelementBase', 'NBTstudy', 'BED', '_RocheLeap'}, 1);
    end

end