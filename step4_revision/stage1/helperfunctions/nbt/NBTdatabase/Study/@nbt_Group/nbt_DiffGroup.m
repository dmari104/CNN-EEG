classdef nbt_DiffGroup < nbt_Group
    properties
        differenceGroups % [group1 group2] if it is a difference group group1-group2
        differenceType % subtraction, absolute difference, L2 difference...
    end    
end

