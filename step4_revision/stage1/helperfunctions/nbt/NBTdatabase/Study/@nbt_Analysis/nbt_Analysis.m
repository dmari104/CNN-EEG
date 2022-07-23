classdef nbt_Analysis < handle
    
    properties
        groupStatHandle % e.g. @nanmedian or @median to produce group statistics.
        groups
        group %
        %group{x}.biomarkers
        %group{x}.subBiomarkers
        %group{x}.biomarkerIdentifiers
        %group{x}.class
        %biomarkerIdentifiers = cell(1,1);
        %subBiomarkers
        channels
        regions
        channelsRegionsSwitch
        uniqueBiomarkers
        data
        settings
        plotSwitch = 1;
        outputTransformationHandle % Function handle for transforming the data
        outputTransformationUnit   % Unit as a result of the output tranformation
    end
    
    methods
        function obj = nbt_Analysis()
            Settings=nbt_Study.getSettings;
            try
                obj.settings.impute = Settings.statistics.impute;
            catch
            end
        end
        
        function biomarkerNames = getBiomarkerNames(StatObj)
            for m=1:length(StatObj.group{1}.biomarkers)
                prefixIdx = strfind(StatObj.group{1}.biomarkers{m},'_');
                prefixIdx = prefixIdx(end);
                identFlag = true;
                for identLoop = 1:size(StatObj.group{1}.biomarkerIdentifiers{m},1)
                    if(strcmp(StatObj.group{1}.biomarkerIdentifiers{m}{identLoop},'frequencyRange'))
                        biomarkerNames{m} = [StatObj.group{1}.biomarkers{m}(prefixIdx+1:end) '.' StatObj.group{1}.subBiomarkers{m} ' : ' StatObj.group{1}.biomarkerIdentifiers{m}{identLoop,2}];
                        identFlag = false;
                    end
                end
                if(identFlag)
                    biomarkerNames{m} = [StatObj.group{1}.biomarkers{m}(prefixIdx+1:end) '.' StatObj.group{1}.subBiomarkers{m}];
                end
                biomarkerNames{m} = strrep(biomarkerNames{m},'_','.');
            end
        end
        
        % getData overload -> adding group data to a cell structure.
        function DataStructure = getData(StatObj)
            global NBTstudy
            DataStructure = cell(length(StatObj.groups),1);
            for n_group = 1:length(StatObj.groups)
                DataStructure{n_group} = NBTstudy.groups{StatObj.groups(n_group)}.getData(StatObj);
            end
        end
        
        %This function injects random data into a StatObject
        function StatObj = injectRandomData(StatObj, nrGroups, nrSubjects, nrBiomarkers, nrChannels)
            global NBTstudy
            NBTstudy = nbt_Study;
            %First generate nrGroups
            for m=1:nrGroups
                NBTstudy.groups{m} = nbt_Group;
                NBTstudy.groups{m}.grpNumber = m;
            end
            % add groups to StatObj
            StatObj.groups = 1:m;
            % generate Random data
            for m = 1:nrGroups
                Data = nbt_Data;
                for b = 1:nrBiomarkers
                    for s = 1:nrSubjects
                        BiomarkerData{s,1} =  randn(nrChannels,1);
                    end
                    Data.dataStore{b,1} = BiomarkerData;
                    Data.subjectList{b} = 1:nrSubjects;
                end
                Data.numSubjects = nrSubjects;
                Data.numBiomarkers = nrBiomarkers;
                StatObj.data{m} = Data;
            end
        end
        
        %Plot method -
        function AnalysisObj = Plot(AnalysisObj)
        end
    
    
        % Calculate methods
        
        function AnalysisObj = preCalculate(AnalysisObj)
        end
        function AnalysisObj = calculate(AnalysisObj)
        end
        function AnalysisObj = postCalculate(AnalysisObj)
        end
    end
end