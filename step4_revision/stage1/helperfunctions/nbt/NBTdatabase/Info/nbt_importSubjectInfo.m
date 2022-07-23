% This function imports subject information to the SubjectInfo Object from
% an XLS file
% Usage:
% nbt_importSubjectInfo(infoPath, XLSfilename, subjectIDcolumn, importParameters)
% 
% Input parameters:
%  infoPath         : the path of the info files
%  XLSfilename      : path and filename of the XLS file to import from
%  subjectIDcolumn  : column number of the subjectIDs 
%  importParameters : should be a cell, with 'identifiername; column in XLS
%                     sheet. I.e., {'subjectAge', 2;'subjectGender', 3} if
%                     the age is in column 2 and the Gender in column 3

%--------------------------------------------------------------------------
% Copyright (C) 2014 Simon-Shlomo Poil
%
% Part of the Neurophysiological Biomarker Toolbox (NBT)
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%
% See Readme.txt for additional copyright information.
%-------------------------------------------------------------------------


function nbt_importSubjectInfo(infoPath, XLSfilename, subjectIDcolumn, importParameters)
%import XLS file
[dummy,dummy,rawXLS] = xlsread(XLSfilename);
%generate SubjectID index
ii = 1;
SubjectIDList = cell(size(rawXLS,1)-1,1);
for i=2:size(rawXLS,1)
    SubjectIDList{ii} = rawXLS{i,subjectIDcolumn};
    ii = ii+1;
end
subjectsMissing = [];
subjectsAdded = [];

fileTree = nbt_ExtractTree(infoPath, 'mat', 'info');
fileNames = cellfun(@nbt_extractFilename,fileTree,'UniformOutput',false);
%Identify the matching file to each subjectIndex


for m = 1:length(fileTree)
    clear SubjectInfo
    disp(['Importing subject info from ' fileTree{1,m} ])
    load(fileTree{m},'SubjectInfo')
    subjectIndex = nbt_searchvector(SubjectIDList,{fileNames{m}})+1;
    if (length(subjectIndex) ~=1)
       subjectsMissing = [subjectsMissing; SubjectInfo.subjectID];
       disp('Subject not found or subject numbers not correct, in:') 
       disp(fileTree{1,m});
        for ip = 1:size(importParameters,1)
            SubjectInfo.info.(importParameters{ip,1}) = nan(1,1);
        end
    else
        subjectsAdded = [subjectsAdded; SubjectInfo.subjectID];
        for ip = 1:size(importParameters,1)
            SubjectInfo.info.(importParameters{ip,1}) = rawXLS{subjectIndex,importParameters{ip,2}};
        end
    end
    save(fileTree{m},'SubjectInfo','-append')
end
disp('Following subjects were missing or do not have consistent IDs')
disp(unique(subjectsMissing));
disp('Following subjects had infomation added successfully')
disp(unique(subjectsAdded));
  
end