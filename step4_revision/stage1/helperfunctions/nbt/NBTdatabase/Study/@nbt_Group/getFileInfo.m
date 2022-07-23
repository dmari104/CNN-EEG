function [FileInfo, GrpObj] = getFileInfo(GrpObj)
%This function loads FileInfo
if isempty(GrpObj.databaseLocation)
    GrpObj.databaseLocation = uigetdir([],'Select folder with NBT Signals');
end
path = GrpObj.databaseLocation;
d = dir(GrpObj.databaseLocation);

%--- scan files in the folder
%--- for files copied from a mac
startindex = 0;
for i = 1:length(d)
    if  d(i).isdir || strcmp(d(i).name(1),'.') || strcmp(d(i).name(1:2),'..') || strcmp(d(i).name(1:2),'._')
        startindex = i+1;
    end
end
%---
pro=1;
disp('Please wait: NBT is checking the files in your folder...')
FileInfo = cell(floor((length(d)-startindex)/3),7);
for i = startindex:length(d)
    if isempty(strfind(d(i).name,'analysis')) && ~isempty(strfind(d(i).name,'info')) && ~isempty(strfind(d(i).name(end-3:end),'.mat')) && isempty(strfind(d(i).name,'statistics'))
        index = strfind(d(i).name,'.');
        index2 = strfind(d(i).name,'_');
        
        % Load info file  
        clear SubjectInfo
        load([path filesep d(i).name],'SubjectInfo');
        
        %% FileInfo collects data for further selection
        FileInfo(pro,1) = {[SubjectInfo.fileName '_analysis.mat']};%contains filename
        FileInfo(pro,2) = {SubjectInfo.projectInfo(1:end-4)}; %ProjectID
        FileInfo(pro,3) = {num2str(SubjectInfo.subjectID)}; %SubjectID
        FileInfo(pro,4) = {SubjectInfo.conditionID}; %ConditionID
        subjectInfoFields = fields(SubjectInfo.info);
        for sf = 1:length(subjectInfoFields)
            FileInfo(pro,sf+4) = {SubjectInfo.info.(subjectInfoFields{sf})};
        end
        pro=pro+1;
    end
end
end