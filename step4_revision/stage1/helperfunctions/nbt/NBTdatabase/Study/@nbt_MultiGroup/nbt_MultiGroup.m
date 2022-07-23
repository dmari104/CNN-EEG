% A multi group is a collection of groups. Makes it easier to compare
% repeated measure designs.

classdef nbt_MultiGroup < nbt_Group
    properties
        multiGroups %refers to the index in the nbt_Study object.
        pairedGroups %0 unapaired, 1 paired
        prePairingSubjectLists = []
    end
    
    methods
        function obj = nbt_MultiGroup
        end
        
        function DataStructure = getData(obj,StatObj)
            %Overloading getData of nbt_Group
            global NBTstudy
            %grpNumber refers to the ordering in the StatObj
            grpNumber = find(ismember(StatObj.groups, obj.grpNumber)==1);
            %Data cache
            if ~isempty(StatObj.data)
                try
                    DataObj = StatObj.data{grpNumber};
                    if(isempty(DataObj))
                        loadData(1);
                    end
                catch
                    loadData(1);
                end
            else
                loadData(1);
            end
            
            
            function loadData(SwitchRun)
                % we need to load n groups
                n_groups = length(obj.multiGroups);
                GroupsInStatObj = StatObj.groups;
                DataInStatObj = StatObj.data;
                isMultiMultiGroup = 0;
                for i=1:n_groups %here we expand the multiGroup
                    subGroup = NBTstudy.groups{obj.multiGroups(i)};
                    StatObj.groups = subGroup.grpNumber;
                    StatObj.data = [];
                    DataStructure{i} = getData(subGroup,StatObj);
                    if(isa(subGroup,'nbt_MultiGroup'))
                        isMultiMultiGroup = 1;
                    else
                        if(isMultiMultiGroup)
                            error('You cannot combined nbt_MultiGroups with normal groups')
                        end
                    end
                end
                StatObj.groups = GroupsInStatObj;
                StatObj.data = DataInStatObj;
                
                % check pairing of groups
                if(obj.pairedGroups)
                    if(isMultiMultiGroup)
                        pairMultiMultiGroups();
                    else
                        pairNormalGroups();
                    end
                end
                
                function pairMultiMultiGroups()
                    runagain = 0;
                    
                    % Before pairing we save the current SubjectLists
                    for ii=1:n_groups
                        subGroups{ii} = NBTstudy.groups{obj.multiGroups(ii)};
                        subGroupSize(ii) = length(subGroups{ii}.multiGroups);
                    end
                    subGroupSize = unique(subGroupSize);
                    if(length(subGroupSize)>1)
                        error('The paired nbt_multiGroups do not have equal number of sub-groups')
                    end
                    
                    if(SwitchRun ==1)
                        for ii=1:n_groups
                            for m=1:subGroupSize
                                try
                                    obj.prePairingSubjectLists{ii}{m} = NBTstudy.groups{subGroups{ii}.multiGroups(m)}.parameters.Subject;
                                catch
                                    obj.prePairingSubjectLists{ii}{m} = [];
                                end
                            end
                        end
                    end
                    
                    for ii=1:n_groups
                        for jj=ii+1:n_groups
                            %check if projectIDs are equal
                            try
                                if(~strcmp(NBTstudy.groups{subGroups{ii}.grpNumber}.parameters.Project,NBTstudy.groups{subGroups{jj}.grpNumber}.parameters.Project))
                                    warning('NBT: ProjectID does not match in multiGroup, pairing of groups based on subjectIDs')
                                end
                            catch
                                warning('NBT: No projectID defined for paired multiGroup. Groups may not be paired correctly')
                            end
                        end
                    end
                    
                    for mm=1:subGroupSize
                        for ii=1:n_groups
                            for jj=(ii+1):n_groups
                                %check if subjectLists are equal
                                if(~isequal(DataStructure{ii}{mm}.subjectList, DataStructure{jj}{mm}.subjectList))
                                    warning('The groups in your multiGroup do not have the same subjects');
                                    disp('Missing subjects:')
                                    
                                    disp(setxor(DataStructure{ii}{mm}.subjectList{1},DataStructure{jj}{mm}.subjectList{1}))
                                    
                                    % if(strcmp('y',input('Do you wish to solve this issue by only including common subjects? [y/n]','s')))
                                    %good we add a Subject parameter with the intersecting subjects.
                                    SubjectListCommon = intersect(DataStructure{ii}{mm}.subjectList{1},DataStructure{jj}{mm}.subjectList{1});
                                    SubjectListCommon = cellfun(@num2str,num2cell(SubjectListCommon),'UniformOutput',false);
                                    NBTstudy.groups{subGroups{ii}.multiGroups(mm)}.parameters.Subject = SubjectListCommon;
                                    NBTstudy.groups{subGroups{jj}.multiGroups(mm)}.parameters.Subject = SubjectListCommon;
                                    warning('Groups have been changed.')
                                    runagain =1;
                                    % end
                                end
                            end
                        end
                    end
                    
                    if(runagain) %in case of fixed subjectLists
                        loadData(2);
                        % re-store old Subject Lists
                        for ii=1:n_groups
                            subGroupSize(ii) = length(subGroups{ii}.multiGroups);
                            for m=1:subGroupSize(ii)
                                if(~isempty(obj.prePairingSubjectLists{ii}{m}))
                                    NBTstudy.groups{subGroups{ii}.multiGroups(m)}.parameters.Subject =  obj.prePairingSubjectLists{ii}{m};
                                else
                                    try
                                        NBTstudy.groups{subGroups{ii}.multiGroups(m)}.parameters = rmfield(NBTstudy.groups{subGroups{ii}.multiGroups(m)}.parameters,'Subject');
                                    catch
                                    end
                                end
                            end
                        end
                    end
                end
                
                
                function pairNormalGroups()
                    runagain = 0;
                    
                    % Before pairing we save the current SubjectLists
                    if(SwitchRun ==1)
                        for ii=1:n_groups
                            try
                                obj.prePairingSubjectLists{ii} = NBTstudy.groups{obj.multiGroups(ii)}.parameters.Subject;
                            catch
                                obj.prePairingSubjectLists{ii} = [];
                            end
                        end
                    end
                    
                    for ii=1:n_groups
                        for jj=ii+1:n_groups
                            %check if projectIDs are equal
                            try
                                if(~strcmp(NBTstudy.groups{obj.multiGroups(ii)}.parameters.Project,NBTstudy.groups{obj.multiGroups(jj)}.parameters.Project))
                                    warning('NBT: ProjectID does not match in multiGroup, pairing of groups based on subjectIDs')
                                end
                            catch
                                warning('NBT: No projectID defined for paired multiGroup. Groups may not be paired correctly')
                            end
                        end
                    end
                    SubjectListCommon = DataStructure{1}.subjectList;
                    for ii=2:n_groups
                        %check if subjectLists are equal
                        if(~isequal(SubjectListCommon, DataStructure{ii}.subjectList))
                            warning('The groups in your multiGroup do not have the same subjects');
                            disp('Missing subjects:')
                            
                            disp(setxor(SubjectListCommon{1},DataStructure{ii}.subjectList{1}))
                            
                            % if(strcmp('y',input('Do you wish to solve this issue by only including common subjects? [y/n]','s')))
                            %good we add a Subject parameter with the intersecting subjects.
                            SubjectListCommon{1} = intersect(SubjectListCommon{1},DataStructure{ii}.subjectList{1});
                            runagain =1;
                            % end
                        end
                    end
                    
                    if(runagain)
                        SubjectListCommon = cellfun(@num2str,num2cell(SubjectListCommon{1}),'UniformOutput',false);
                        for ii=1:n_groups
                            NBTstudy.groups{obj.multiGroups(ii)}.parameters.Subject = SubjectListCommon;
                        end
                        warning('Groups have been changed.')
                    end
                    
                    
                    if(runagain) %in case of fixed subjectLists
                        loadData(2);
                        % re-store old Subject Lists
                        for ii=1:n_groups
                            if(~isempty(obj.prePairingSubjectLists{ii}))
                                NBTstudy.groups{obj.multiGroups(ii)}.parameters.Subject =  obj.prePairingSubjectLists{ii};
                            else
                                try
                                    NBTstudy.groups{obj.multiGroups(ii)}.parameters = rmfield(NBTstudy.groups{obj.multiGroups(ii)}.parameters,'Subject');
                                catch
                                end
                            end
                        end
                    end
                end
                
            end
            StatObj.data{grpNumber} = DataStructure;
        end
    end
end