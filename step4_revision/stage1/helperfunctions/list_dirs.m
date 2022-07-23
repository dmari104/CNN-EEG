function dirNames = list_dirs(parentDir)

    % Get a list of all files and folders in a directory
    files = dir(parentDir);
    names = {files.name};
    dirFlags = [files.isdir] & ...
              ~strcmp(names, '.') & ~strcmp(names, '..');
    % Extract only those that are directories.
    dirNames = names(dirFlags);

end