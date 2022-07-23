%% Info object class constructor
% Info=Info_Object(file_name,file_name_format,description_project,time_of_recording, ...
%                 original_sample_frequency,converted_sample_frequency,researcher_ID, subject_gender,subject_age, ...
%                 subject_headsize)
%
% See also:
%   nbt_CreateInfoObject

%--------------------------------------------------------------------------
% Copyright (C) 2008  Neuronal Oscillations and Cognition group,
% Department of Integrative Neurophysiology, Center for Neurogenomics and
% Cognitive Research, Neuroscience Campus Amsterdam, VU University Amsterdam.
%
% Part of the Neurophysiological Biomarker Toolbox (NBT)
%
%--------------------------------------------------------------------------


classdef nbt_Info
    properties
        SignalName
        projectID
        researcherID
        subjectID
        channelID
        NBTDID 
        condition
        frequencyRange
        file_name
        file_name_format
        fileType
        time_of_recording
        original_sample_frequency
        notes
        subject_gender
        subject_age
        subject_headsize
        subject_handedness
        subject_medication
        Interface
        BadChannels
        NBTgrade
        NonEEGch
        EyeCh
        reference
        Info
        LastUpdate
    end
    
    properties(Dependent)
        converted_sample_frequency
    end
    
    properties(Access=private)
       privconverted_sample_frequency 
    end
    
    methods
        function Info = nbt_Info(file_name, file_name_format, condition, ...
                time_of_recording, original_sample_frequency, converted_sample_frequency,...
                researcherID, subjectID, projectID, subject_gender, subject_age, ...
                subject_headsize, subject_handedness, subject_medication, notes)
            
            if nargin == 0
                file_name=[];
                file_name_format=[];
                time_of_recording=[];
                original_sample_frequency=[];
                converted_sample_frequency=[];
                researcherID=[];
                subject_gender=[];
                subject_age=[];
                subject_headsize=[];
                subject_handedness=[];
                subject_medication=[];
                notes=[];
                condition = [];
                subjectID = [];
                channelID = 0;
                projectID = [];
            end
            
            Info.file_name=file_name;
            Info.file_name_format= file_name_format;
            Info.condition = condition;
            Info.subjectID = subjectID;
            Info.channelID = 0;
            Info.projectID = projectID;
            Info.time_of_recording=time_of_recording;
            Info.original_sample_frequency=original_sample_frequency;
            Info.converted_sample_frequency=converted_sample_frequency;
            Info.researcherID=researcherID;
            Info.subject_gender=subject_gender;
            Info.subject_age=subject_age;
            Info.subject_headsize=subject_headsize;
            Info.subject_handedness=subject_handedness;
            Info.subject_medication=subject_medication;
            Info.notes=notes;
            Info.frequencyRange = [];
            Info.NBTDID = nbt_MakeNBTDID;
            Info.LastUpdate = datestr(now);
        end
        
        %we support only setting .convert_sample_frequency
        function obj = set.converted_sample_frequency(obj, value)
                if(isempty(obj.original_sample_frequency))
                    obj.original_sample_frequency = value;
                end
                obj.privconverted_sample_frequency = value;
        end
        
        function v = get.converted_sample_frequency(obj)
            v = obj.privconverted_sample_frequency;
        end
        
        function Biomarker = SetBadChannelsToNaN(Info,Biomarker)
            Biomarker(:,find(Info.BadChannels)) = nan(size(Biomarker,1),length(find(Info.BadChannels)));
        end 
    end
    methods(Static)
         InfoObject = importSubjectInfoFromXLS;
         InfoObject = importSubjectInfoFromCSV(filename,InfoObject);
    end
end