function sh_checkFiles(filenames)
    for fileIdx = 1 : length(filenames)
        % Check if signal-file exists
        if ~exist(filenames{fileIdx}, 'file')
            disp(['Signal-file for ', filenames{fileIdx}, ' is missing.']);
        end
        
        % Check if info-file exists
        infoFilename = strrep(filenames{fileIdx}, '.mat', '_info.mat');
        if ~exist(infoFilename, 'file')
            disp(['Info-file for ', filenames{fileIdx}, ' is missing.']);
        end
        
        % Check if analysis-file exists
        analysisFilename = strrep(filenames{fileIdx}, '.mat', '_info.mat');
        if ~exist(analysisFilename, 'file')
            disp(['Analysis-file for ', filenames{fileIdx}, ' is missing.']);
        end
        
        % Check if both ECR and EOR files exist
        filename = fliplr(strtok(fliplr(filenames{fileIdx}), '/'));
        [~, tail] = strtok(filename, '.');
        [~, tail] = strtok(tail, '.');
        [~, tail] = strtok(tail, '.');
        [conditionName, ~] = strtok(tail, '.');
        
        if ~isempty(strfind(conditionName, 'ECR'))
            EORFilename = strrep(filenames{fileIdx}, 'ECR', 'EOR');
            if ~exist(EORFilename, 'file')
                disp(['EOR-condition for ', filenames{fileIdx}, ' is missing.']);
            end
        end
        
        if ~isempty(strfind(conditionName, 'EOR'))
            EORFilename = strrep(filenames{fileIdx}, 'EOR', 'ECR');
            if ~exist(EORFilename, 'file')
                disp(['ECR-condition for ', filenames{fileIdx}, ' is missing.']);
            end
        end
    end
end