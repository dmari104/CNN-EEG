classdef nbt_DiffGroup < nbt_Group
    properties
        groupDifference % [group1 group2] if it is a difference group group1-group2
        groupDifferenceType % subtraction, absolute difference, L2 difference...
    end  
    
    methods
        function obj=nbt_DiffGroup(obj) %constructor
        end
        
        function DiffGroup = defineGroup(DiffGroup,group_ind)
           global NBTstudy
            DiffGroup.grpNumber = length(NBTstudy.groups) + 1;
            DiffGroup.groupDifference = group_ind;
            DiffGroup.biomarkerList = NBTstudy.groups{group_ind(1)}.biomarkerList;
            DiffGroup.chanLocs = NBTstudy.groups{group_ind(1)}.chanLocs;
            DiffGroup.ref = NBTstudy.groups{group_ind(1)}.ref;
            DiffGroup.listRegData = NBTstudy.groups{group_ind(1)}.listRegData;
            
            input_data = nbt_SelectOptionsData();
            input_data.Statement = 'Which kind of difference?';
            input_data.Options = {'regular','absolute','squared'};
            result = nbt_input(input_data);
            DiffGroup.groupDifferenceType = result{1};
            
            nameg1 = NBTstudy.groups{group_ind(1)}.groupName;   
            nameg2 = NBTstudy.groups{group_ind(2)}.groupName;
            DiffGroup.groupName = [nameg1 ' minus ' nameg2];
            DiffGroup.parameters = [NBTstudy.groups{group_ind(1)}.parameters; NBTstudy.groups{group_ind(2)}.parameters];
            % Put the group in the NBTstudy object
            NBTstudy.groups{end+1} = DiffGroup;
        end
    end
end

