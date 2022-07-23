% This function imports subject information to the SubjectInfo Object from
% an XLS file
% Usage:
% nbt_importSubjectInfo(infoPath, XLSfilename, matchHandle, importParameters)
% 
% Input parameters:
%  infoPath         : the path of the info files
%  XLSfilename      : path and filename of the XLS file to import from
%  matchHandle      : A function handle to a match function, with input
%                     rawXLS and filename, should output row number in XLS
%                     with match.
%  importParameters : should be a cell, with 'identifiername; column in XLS
%                     sheet. I.e., {'subjectAge', 2;'subjectGender', 3} if
%                     the age is in column 2 and the Gender in column 3

%--------------------------------------------------------------------------
% Copyright (C) 2014 Simon-Shlomo Poil
%
% Part of the Neurophysiological Biomarker Toolbox (NBT)
%
%-------------------------------------------------------------------------


function [subjectsAdded,subjectsMissing]=nbt_importSubjectInfoMatch(infoPath, XLSfilename, matchHandle, importParameters)
%import XLS file
[dummy,dummy,rawXLS] = xlsread(XLSfilename);
subjectsMissing = [];
subjectsAdded = [];

fileTree = nbt_ExtractTree(infoPath, 'mat', 'info');
fileNames = cellfun(@nbt_extractFilename,fileTree,'UniformOutput',false);
%Identify the matching file to each subjectIndex
subjectIndex = matchHandle(rawXLS, fileNames);

for m = 1:length(fileTree)
    clear SubjectInfo
    disp(['Importing subject info from ' fileTree{1,m} ])
    load(fileTree{m},'SubjectInfo')
    
    if (isempty(subjectIndex{m}))
       subjectsMissing = [subjectsMissing; SubjectInfo.subjectID];
       disp('Subject not found or subject numbers not correct, in:') 
       disp(fileTree{1,m});
        for ip = 1:size(importParameters,1)
            SubjectInfo.info.(importParameters{ip,1}) = nan(1,1);
        end
    else
        subjectsAdded = [subjectsAdded; SubjectInfo.subjectID];
        for ip = 1:size(importParameters,1)
            SubjectInfo.info.(importParameters{ip,1}) = rawXLS{subjectIndex{m},importParameters{ip,2}};
        end
    end
    save(fileTree{m},'SubjectInfo','-append')
end
disp('Following subjects were missing or do not have consistent IDs')
disp(unique(subjectsMissing));
disp('Following subjects had infomation added successfully')
disp(unique(subjectsAdded));  
end