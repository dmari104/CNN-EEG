function  DataObj = getData(GrpObj,StatObj)
%Get data loads the data from a Database depending on the settings in the
%Group Object and the Statistics Object.
narginchk(1,2);

global NBTstudy
try
    NBTstudy = evalin('base','NBTstudy');
catch
    evalin('base','global NBTstudy');
    evalin('base','NBTstudy = nbt_Study;');
end


%grpNumber refers to the ordering in the StatObj
grpNumber = find(ismember(StatObj.groups, GrpObj.grpNumber)==1);

if isa(StatObj,'nbt_comparebiomarkers') StatObj.data = []; end

if ~isempty(StatObj.data)
    try
        DataObj = StatObj.data{grpNumber};
        if(isempty(DataObj))
            loadData();
        end
    catch
        loadData();
    end
else
    loadData();
end

    function loadData()
        %%% Get the data
        DataObj = nbt_Data;
        StatObj.data{grpNumber} = DataObj;
        
        if ~exist('StatObj','var')
            for i=1:length(GrpObj.biomarkerList)
                [DataObj.biomarkers{i}, DataObj.biomarkerIdentifiers{i}, DataObj.subBiomarkers{i}, DataObj.classes{i}, DataObj.units{i}] = nbt_parseBiomarkerIdentifiers(GrpObj.biomarkerList{i});
            end
        else
            DataObj.biomarkers = StatObj.group{grpNumber}.biomarkers;
            DataObj.subBiomarkers = StatObj.group{grpNumber}.subBiomarkers;
            DataObj.biomarkerIdentifiers = StatObj.group{grpNumber}.biomarkerIdentifiers;
            if(isfield(StatObj.group{grpNumber},'biomarkerIndex'))
                DataObj.biomarkerIndex = StatObj.group{grpNumber}.biomarkerIndex;
            end
            DataObj.classes = StatObj.group{grpNumber}.classes;
        end
        
        numBiomarkers       = length(DataObj.biomarkers);
        DataObj.dataStore   = cell(numBiomarkers,1);
        DataObj.pool        = cell(numBiomarkers,1);
        DataObj.poolKey     = cell(numBiomarkers,1);
        
        switch GrpObj.databaseType
            %switch database type - for clarity this switch is still here.
            case 'NBTelement'
                DataObj = getData_NBTelement(DataObj, GrpObj, StatObj);
            case 'File'
                DataObj = getData_NBTelement(DataObj,GrpObj, StatObj);
        end
        
        DataObj.numSubjects = length(DataObj.subjectList{1,1}); %we assume there not different number of subjects per biomarker!
        DataObj.numBiomarkers = size(DataObj.dataStore,1);
        
        % Output data transformation 
        if(~isempty(StatObj.outputTransformationHandle))
            for bId = 1:numBiomarkers
                if(isa(StatObj.outputTransformationHandle{bId}, 'function_handle'))
                    DataObj.dataStore{bId} = cellfun(StatObj.outputTransformationHandle{bId}, DataObj.dataStore{bId},'UniformOutPut',false);
                    DataObj.units{bId} = StatObj.outputTransformationUnit{bId};
                end
            end
        end
    end
end
