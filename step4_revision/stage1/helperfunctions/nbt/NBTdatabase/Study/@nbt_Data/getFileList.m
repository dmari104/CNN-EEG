function fileList = getFileList(DataObj)
% setting base parameters.
assignin('base', 'tmpPool', DataObj.pool)
assignin('base', 'tmpPoolKey', DataObj.poolKey)

%% Construct the file names
%projectIds
ProjectIDs = evalin('base',['nbt_returnData(Project, tmpPool{1},tmpPoolKey{1});']);
%SubjectIds
SubjectIDs = evalin('base',['nbt_returnData(Subject, tmpPool{1},tmpPoolKey{1});']);
strToAdd = '000';
SubjectStrIDs = cell(length(SubjectIDs),1);
for mm=1:length(SubjectIDs)
    SubStr = num2str(SubjectIDs(mm));
    lToAdd = 3 - length(SubStr);
    SubjectStrIDs{mm,1} =  ['S' strToAdd(1:lToAdd) SubStr];
end
%DateofRec
try
    DateOfRec = evalin('base',['nbt_returnData(NBTe_dateOfRecording, tmpPool{1},tmpPoolKey{1});']);
catch %in case no dates are given
    DateOfRec = 'yyyymmdd';
end
%ConditionIDs
ConditionIDs = evalin('base',['nbt_returnData(Condition, tmpPool{1},tmpPoolKey{1});']);

for j=1:length(ProjectIDs)
    fileList{j} = strcat(ProjectIDs{j},'.',SubjectStrIDs{j},'.',DateOfRec{j},'.',ConditionIDs{j},'_analysis.mat');
end

evalin('base','clear tmpPool');
evalin('base','clear tmpPoolKey')
end
