%% ProjectInfo object class constructor
% ProjectInfo=nbt_ProjectInfo
%
%

classdef nbt_ProjectInfo
    properties
        projectID
        researcherID
        numberOfSubjects
        numberOfConditions
        notes
        info
        lastUpdate
    end
      
    methods
        function ProjectInfo = nbt_ProjectInfo(ProjectInfo)
            ProjectInfo.lastUpdate = datestr(now);
        end
    end
end