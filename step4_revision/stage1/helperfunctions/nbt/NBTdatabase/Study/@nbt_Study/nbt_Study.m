%nbt_Study is a collector object of the nbt_Stat and nbt_Group objects.
classdef nbt_Study
    properties
        data
        groups
        statAnalysis
        settings
        InfoCell
        BioCell
        IdentCell
    end
    
    methods
        function StudyObject = nbt_Study()
            StudyObject.settings.visual.mcpCorrection = 'binomial';
            StudyObject.settings.visual.FDRq = 0.05;
            StudyObject.settings.visual.plotQuality = 2;
            StudyObject.settings.visual.regionsSwitch = 0;
            StudyObject.settings.statistics.impute = false;
        end
    end
    
    methods (Static = true)
        listOfAvailbleTests = getStatisticsTests(index);
        
        function settings = getSettings
            %return the current settings.
            if(isempty(who('NBTstudy','global')))
                NBTstudy = nbt_Study;
            else
                global NBTstudy
            end
            settings = NBTstudy.settings;
        end
    end
end