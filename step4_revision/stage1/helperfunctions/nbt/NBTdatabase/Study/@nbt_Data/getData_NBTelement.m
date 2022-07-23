function DataObj = getData_NBTelement(DataObj,GrpObj,StatObj)
global NBTstudy
%In this case we load the data directly from the NBTelements in base.
%We loop over DataObj.biomarkers and generate a cell
numBiomarkers       = length(DataObj.biomarkers);

if ~isa(GrpObj,'nbt_DiffGroup') % regular group
    DataObj = prepareDataObj(DataObj,GrpObj);
    DataObj = fetchDataObj(DataObj);
else
    Group1 = NBTstudy.groups{GrpObj.groupDifference(1)};
    Group2 = NBTstudy.groups{GrpObj.groupDifference(2)};
    DataObj = prepareDataObj(DataObj, Group1);
    DataObj2 = nbt_Data;
    DataObj2.biomarkers = DataObj.biomarkers;
    DataObj2.biomarkerIdentifiers = DataObj.biomarkerIdentifiers;
    DataObj2.subBiomarkers = DataObj.subBiomarkers;
    DataObj2.classes = DataObj.classes;
    DataObj2 = prepareDataObj(DataObj2, Group2);
    
    if(~isequal(DataObj.uniqueSubjectList{1}, DataObj2.uniqueSubjectList{1}))
        disp('Difference group: Subject lists do not match - matching');
        
        matchedUniqueSubjects = intersect(DataObj.uniqueSubjectList{1},DataObj2.uniqueSubjectList{1});
        [~, subjectIndices1] = ismember(matchedUniqueSubjects,DataObj.uniqueSubjectList{1});
        [~, subjectIndices2] = ismember(matchedUniqueSubjects,DataObj2.uniqueSubjectList{1});
        
        for j=1:size(DataObj.uniqueSubjectList,1)
            % match unique subject list
            DataObj.uniqueSubjectList{j,1} = matchedUniqueSubjects;
            DataObj2.uniqueSubjectList{j,1} = matchedUniqueSubjects;
            
            % match subject list
            DataObj.subjectList{j,1} = DataObj.subjectList{j,1}(subjectIndices1);
            DataObj2.subjectList{j,1} = DataObj2.subjectList{j,1}(subjectIndices2);
            
            % match pool list
            DataObj.pool{j,1} = DataObj.pool{j,1}(subjectIndices1);
            DataObj2.pool{j,1} = DataObj2.pool{j,1}(subjectIndices2);
        end
        
    end
    %     % check pairing of groups
    %     for mm=1:length(DataObj2.subjectList)
    %         if(~isequal(DataObj.subjectList{mm},DataObj2.subjectList{mm}))
    %             error('NBT: Difference group. SubjectLists do not match')
    %         end
    %     end
    DataObj  = fetchDataObj(DataObj,DataObj2);
end

    function DataObj = fetchDataObj(DataObj,DataObj2)
        narginchk(1,2) %if we have two DataObjecs we have difference Group
        switch GrpObj.databaseType
            case 'NBTelement'
                switch nargin
                    case 1 % normal group
                        assignin('base', 'tmpPool', DataObj.pool)
                        assignin('base', 'tmpPoolKey', DataObj.poolKey)
                        for bId = 1:numBiomarkers
                            [DataObj.dataStore{bId,1}, ~, ~, DataObj.units{bId,1}, DataObj.biomarkerMetaInfo{bId,1}] = evalin('base',['nbt_returnData(' DataObj.biomarkers{bId} ', tmpPool{' num2str(bId) '}, tmpPoolKey{' num2str(bId) '},' '''' DataObj.subBiomarkers{bId} '''' ');']);
                            checkSizeOfData(DataObj)
                        end
                        evalin('base','clear tmpPool');
                        evalin('base','clear tmpPoolKey')
                    case 2 % difference group
                        assignin('base', 'tmpPool', DataObj.pool)
                        assignin('base', 'tmpPoolKey', DataObj.poolKey)
                        assignin('base', 'tmpPool2', DataObj2.pool)
                        assignin('base', 'tmpPoolKey2', DataObj2.poolKey)
                        for bId = 1:numBiomarkers
                            [DataObj.dataStore{bId,1}, ~, ~, DataObj.units{bId,1}, DataObj.biomarkerMetaInfo{bId,1}] = evalin('base',['nbt_returnData(' DataObj.biomarkers{bId} ', tmpPool{' num2str(bId) '}, tmpPoolKey{' num2str(bId) '},' '''' DataObj.subBiomarkers{bId} '''' ', tmpPool2{' num2str(bId) '}, tmpPoolKey2{' num2str(bId) '},' ''''  GrpObj.groupDifferenceType '''' ');']);
                            checkSizeOfData(DataObj)
                        end
                        evalin('base','clear tmpPool');
                        evalin('base','clear tmpPoolKey')
                        evalin('base','clear tmpPool2');
                        evalin('base','clear tmpPoolKey2')
                end
            case 'File'
                switch nargin
                    case 1 % normal group
                        assignin('base', 'tmpPool', DataObj.pool)
                        assignin('base', 'tmpPoolKey', DataObj.poolKey)
                        DataObj=returnDatafromFile(DataObj);
                        checkSizeOfData(DataObj)
                        evalin('base','clear tmpPool');
                        evalin('base','clear tmpPoolKey')
                    case 2 % difference group
                        assignin('base', 'tmpPool', DataObj.pool)
                        assignin('base', 'tmpPoolKey', DataObj.poolKey)
                        assignin('base', 'tmpPool2', DataObj2.pool)
                        assignin('base', 'tmpPoolKey2', DataObj2.poolKey)
                        DataObj=returnDatafromFile(DataObj, DataObj2, GrpObj.groupDifferenceType);
                        checkSizeOfData(DataObj)
                        evalin('base','clear tmpPool');
                        evalin('base','clear tmpPoolKey')
                        evalin('base','clear tmpPool2');
                        evalin('base','clear tmpPoolKey2')
                end
        end
        
        
        for bID = 1:numBiomarkers
            if ~strcmp(DataObj.classes{bID},'nbt_QBiomarker')
                if (StatObj.channelsRegionsSwitch == 2) % regions
                    try
                        DataObj.dataStore{bID} = cellfun(@calcRegions,DataObj.dataStore{bID},'UniformOutput',0);
                    catch me
                        warning([num2str(bID) ' this biomarker is broken - probably means regions were not defined..']);
                    end
                    
                end
            end
        end
        
        
        function checkSizeOfData(DataObj)
            if (length(DataObj.dataStore{bId,1}) ~= length(DataObj.uniqueSubjectList{bId,1}))
                warning('Repeated data for unique subjects')
            end
        end
    end

    function newData=calcRegions(data)
        regions = GrpObj.listRegData;
        
        [size1 size2] = size(data);
        if size1>1 && size2>1
            warning('temporary hack for CHDR data')
            newData(1,:) = data(regions(1).reg.channel_nr,regions(2).reg.channel_nr);
            newData(2,:) = data(regions(2).reg.channel_nr,regions(1).reg.channel_nr);
        else
            for rID=1:length(regions)
                if isa(data(regions(rID).reg.channel_nr,:),'cell')
                    dataTemp = cell2mat(data(regions(rID).reg.channel_nr,:));
                else
                    dataTemp = data(regions(rID).reg.channel_nr,:);
                end
                newData(rID,:) = nanmean(dataTemp);
                % newData(rID,:) = nanmean(data(regions(rID).reg.channel_nr,:));
            end
        end
    end
end


function DataObj=returnDatafromFile(DataObj,DataObj2, DiffFun)
narginchk(1,3)

if(nargin == 1)
    DataObj = loadData(DataObj);
else
    DiffFunH = nbt_getDiffFun(DiffFun);
    DataObj = loadData(DataObj);
    DataObj2 = loadData(DataObj2);
    for bId = 1:length(DataObj.biomarkers)
        DataObj.dataStore{bId,1} = cellfun(DiffFunH, DataObj.dataStore{bId,1},DataObj2.dataStore{bId,1},'UniformOutPut',false);
    end
end
    function DataObj=loadData(DataObj)
        fileNames = getFileList(DataObj);
        
        %% Then we load first file and find the name of the biomarker to load
        % using the unique identifiers
        [DataObj,BiomarkerLoadName]=sandboxLoad(DataObj,fileNames{1,1},[]);
        %% Then we start loading analysis files and check uniqueIDs
        %if unique IDs do not match we load the full file and search
        %
        for fIdx = 2:length(fileNames)
            [DataObj]=sandboxLoad(DataObj,fileNames{fIdx},BiomarkerLoadName);
        end
    end
end


function ident=changeSignalsName(ident)
for i=1:size(ident,1)
    if(strcmp(ident{i,1},'Signals'))
        ident{i,1} = 'signalName';
    end
end
end



function [DataObj, BiomarkerLoadName] = sandboxLoad(DataObj,fileName,BiomarkerLoadName)
if(isempty(BiomarkerLoadName))
    %we need to identify the load name
    load(fileName)
    %We load each biomarker, and test conditions
    
    for bId = 1:length(DataObj.biomarkers)
        objectName = DataObj.biomarkers{bId};
        objectName = objectName(6:end);
        SearchList = nbt_ExtractObject(objectName);
        Identifiers = changeSignalsName(DataObj.biomarkerIdentifiers{bId});
        for lbId = 1:length(SearchList)
            ToTest = eval(SearchList{lbId});
            ok =1;
            for Iidx = 1:size(Identifiers,1)
                if(~strcmp(num2str(ToTest.(Identifiers{Iidx,1})),Identifiers{Iidx,2}))
                    ok = 0;
                    break;
                end
            end
            if(ok)
                BiomarkerLoadName{bId} = SearchList{lbId};
                break;
            end
        end
    end
else
    for bId = 1:length(DataObj.biomarkers)
        load(fileName,BiomarkerLoadName{bId})
    end
end
for bId = 1:length(DataObj.biomarkers)
    if(isempty(DataObj.dataStore{bId,1})) %we need to insert data at the right subject spot
        subjIdx = 1;
        DataObj.dataStore{bId,1} = cell(0,0);
    else
        subjIdx = length(DataObj.dataStore{bId,1})+1;
    end
    DataObj.dataStore{bId,1}{subjIdx,1} = eval([BiomarkerLoadName{bId} '.(DataObj.subBiomarkers{bId});']);
    if(size(DataObj.dataStore{bId,1}{subjIdx,1},2) > size(DataObj.dataStore{bId,1}{subjIdx,1},1)) %to fix bug with biomarkers with wrong dimension
        DataObj.dataStore{bId,1}{subjIdx,1} = DataObj.dataStore{bId,1}{subjIdx,1}';
    end
    DataObj.units{bId,1} = eval([BiomarkerLoadName{bId} '.units;']);
    DataObj.biomarkerMetaInfo{bId} = eval([BiomarkerLoadName{bId} '.biomarkerMetaInfo;']);
end

end

