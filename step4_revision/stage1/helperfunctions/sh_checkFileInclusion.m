function includeFile = sh_checkFileInclusion(filename, includes, excludes)
    includeFile = 1;
    for includeStringIdx = 1 : length(includes)
        if isempty(strfind(filename, includes{includeStringIdx}))
            includeFile = 0;
        end
    end
    
    for excludeStringIdx = 1 : length(excludes)
        if ~isempty(strfind(filename, excludes{excludeStringIdx}))
            includeFile = 0;
        end
    end
end