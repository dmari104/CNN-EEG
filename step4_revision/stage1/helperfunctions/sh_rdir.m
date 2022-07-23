function filePaths = sh_rdir(currentPath, includes, excludes, includePath)
    % Index all items in folder
    items = dir(fullfile(currentPath));
    
    % Remove crap
    items = sh_removeParents(items);
    
    % Get number of items
    nItems = size(items, 1);
    
    % Iterate along all items and index the .mat files
    filePaths = [];
    for itemIdx = 1 : nItems
        if items(itemIdx).isdir && isempty(strfind(items(itemIdx).name, '_EXC'))
            % Run rdir for the subfolder
            filePaths = [filePaths, sh_rdir(fullfile(currentPath, items(itemIdx).name), includes, excludes, includePath)];
        else
            % Add the file to the list of files
            if sh_checkFileInclusion(items(itemIdx).name, includes, excludes)
                if includePath
                    filePaths{end+1} = fullfile(currentPath, items(itemIdx).name);
                else
                    filePaths{end+1} = items(itemIdx).name;
                end
            end
        end
    end
end