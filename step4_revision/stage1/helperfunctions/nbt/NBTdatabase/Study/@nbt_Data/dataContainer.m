function DataObj = dataContainer(GrpObj)
DataObj = nbt_Data;
DataObj.dataStore = wrapDataContainer(GrpObj);
end


function dataStoreLink = wrapDataContainer(GrpObj)

%First we generate the basic structure.
%in case of NBTelement based storage (we simply load the database in base)
switch GrpObj.databaseType
    case 'NBTelement'
        Project         = evalin('base', 'Project');
        Subject         = evalin('base', 'Subject');
        Condition       = evalin('base', 'Condition');
        FrequencyBand   = evalin('base', 'FrequencyBand');
        Age             = evalin('base', 'Age');
        Gender          = evalin('base', 'Gender');
        
        disp('break')
        for l = 1:length(GrpObj.biomarker)
            [NBTelementName, Biomarker] = strtok(GrpObj.biomarker{l},'.');
            [FreqBand, Biomarker] = strtok(Biomarker, '.');
            Biomarker = Biomarker(2:end);
            if(isempty(Biomarker))
                Biomarker = FreqBand;
                FreqBand = [];
            end
            NBTelementCall = ['nbt_GetData(' NBTelementName ',{Project,{'];
            NBTelementCall = [NBTelementCall GrpObj.projectID ];
            SubjectList = nbt_expandCell(GrpObj.subjectID);
            NBTelementCall = [NBTelementCall '};Subject,['];
            for m=1:length(SubjectList)
                NBTelementCall = [NBTelementCall ' ' num2str(SubjectList(m)) ];
            end
            NBTelementCall = [NBTelementCall '];Condition, {''' GrpObj.conditionID{1,1}];
            try
                for m=2:size(GrpObj.conditionID,1)
                    NBTelementCall = [NBTelementCall ''',''' GrpObj.conditionID{m,1}];
                end
            catch
            end
            if(~isempty(FreqBand))
                NBTelementCall = [NBTelementCall '''} ;FrequencyBand,''' FreqBand '''},''' Biomarker ''');' ];
            else
                NBTelementCall = [NBTelementCall '''} },''' Biomarker ''');' ];
            end
            tmp = evalin('base', NBTelementCall);
        end
            
            
            case 'File'
                %in case of file based storage
                Project = nbt_NBTelement(1,'1',[]);
                Project = nbt_SetData(Project, GrpObj.projectID,{});
                
                Subject = nbt_NBTelement(2, '2.1', 1);
                Subject = nbt_SetData(Subject, GrpObj.subjectID,{Project});
                
                Condition = nbt_NBTelement(3, '3.2.1',2);
                FrequencyBand = nbt_NBTelement(4,'4.3.2.1',3);
                Age = nbt_NBTelement(5, '5.3.2.1', 3);
                Gender = nbt_NBTelement(6,'6.2.1', 2);
                NextID = 7;
                
        end
        
        
        
        
        
        %nested function
        function dataStore()
        disp('break')
        end
        
        dataStoreLink = @dataStore;
        
end
