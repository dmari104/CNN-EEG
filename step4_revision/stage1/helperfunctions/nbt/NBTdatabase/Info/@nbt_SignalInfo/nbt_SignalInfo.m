%% SignalInfo object class constructor
% SignalInfo  = nbt_SignalInfo
%
% See also:
%   nbt_CreateInfoObject

%--------------------------------------------------------------------------
% Copyright (C) 2014  Simon-Shlomo Poil
% Part of the Neurophysiological Biomarker Toolbox (NBT)
%--------------------------------------------------------------------------


classdef nbt_SignalInfo
    properties
        subjectInfo                 %Pointer to SubjectInfo file (typical the same file)
        signalName                  %The name of the signal
        signalID                    %A unique ID genearated by nbt_makeNBTDID;
        signalSHA256                %The SHA256 hash of the Signal
        signalOrigin                % Filename (path) of the raw signal or previous signal RawSignal> CleanSignal >ICASignal.
        researcherID                % Researcher ID
        signalType                  % EEG or other type of Signal
        signalLink                  % To link to planar signals in MEG
        signalUnit                  % The unit of the signal, the signal should scaled to this unit during import (default: microvolts for EEG signals)
        signalLength                % Signal length in seconds.
        signalGrade                 % Grading of signal quality: From 1 to 5; 1 is very poor, 5 is very good.
        signalSRgrade               % Seven Point Rating scale
        frequencyRange              %If the signal has be filtered the frequencyRange in [lp hp] format
        filterSettings              % Struct with filtersettings.
        cleaningSettings            % Struct with cleaning settings
        timeOfRecording             % time and date of recording in YYYYMMDD-HHMMSS format.
        originalSamplingFrequency   %The recorded sampling frequency
        notes                       %For additional notes about the signal
        badChannels                 %Logical list of bad channels 1 for bad, 0 for good.
        nonEEGch                    % List of non EEG channels
        eyeCh                       % List of Eye channels
        reference                   % Reference channel
        lastUpdate                  % When the Signal was saved
        log                         % For log of changes to the signal
        interface                   %A struct with info relevant for interfacing with other toolboxes
        nbtVersion                  % The NBT version using nbt_getVersion
        nbtScriptVersion
        listOfBiomarkers
    end
    
    properties(Dependent)
        convertedSamplingFrequency
    end
    
    properties(Access=private)
        privconverted_sample_frequency
    end
    
    methods
        function SignalInfo = nbt_SignalInfo(Input)
            narginchk(0,1)
            if(exist('Input','var'))
                fname = fields(SignalInfo);
                for i=1:length(fname)
                    SignalInfo.(fname{i}) = Input.(fname{i});
                end
            else
                if(isempty(SignalInfo.nbtVersion))
                    SignalInfo.nbtVersion = nbt_getVersion;
                end
                if(isempty(SignalInfo.signalID))
                    SignalInfo.signalID = nbt_MakeNBTDID;
                end
                SignalInfo.lastUpdate = datestr(now);
            end
        end
        
        function obj=update(obj)
            obj.lastUpdate = datestr(now);
            obj.nbtVersion = nbt_getVersion;
        end
        
        %we support only setting .convertedSamplingFrequency
        function obj = set.convertedSamplingFrequency(obj, value)
            if(isempty(obj.originalSamplingFrequency))
                obj.originalSamplingFrequency = value;
            end
            obj.privconverted_sample_frequency = value;
        end
        
        function v = get.convertedSamplingFrequency(obj)
            v = obj.privconverted_sample_frequency;
        end
        
        function Biomarker = SetBadChannelsToNaN(Info,Biomarker)
            Biomarker(:,find(Info.badChannels)) = nan(size(Biomarker,1),length(find(Info.badChannels)));
        end
        
        function yesno = checkHash(SignalInfo, Signal)
            yesno = false;
            if(~isempty(SignalInfo.signalSHA256))
                yesno = strcmp(nbt_getHash(single(Signal)),SignalInfo.signalSHA256);
            end
        end
        
        function check(SignalInfo, RawSignalInfo, fileName, SignalName) %function to check the format of the SignalInfo
            % check subjectInfo
            pathIdx = strfind(fileName,filesep);
            fileName = fileName(pathIdx(end)+1:end);
            nbt_stringCheck(SignalInfo.subjectInfo,fileName(1:end-9), 'SignalInfo: subjectInfo not correct')
            %signalName
            nbt_stringCheck(SignalInfo.signalName,SignalName,'SignalInfo: signalName not correct')
            %NBTDID
            if(~isempty(RawSignalInfo.signalID))
                nbt_stringCheck(SignalInfo.signalID,RawSignalInfo.signalID, 'SignalInfo: signalID not correct')
            end
            %sampling frequency
            if(isempty(SignalInfo.convertedSamplingFrequency))
                error('SignalInfo: Sampling frequency missing')
            end
        end
    end
end