
% Info = nbt_CreateInfoObject(filename, FileExt, Fs, NBTSignalObject)
%
% Usage:
% nbt_CreateInfoObject(filename, FileExt)
% or
% nbt_CreateInfoObject(filename, FileExt, Fs)
% or
% nbt_CreateInfoObject(filename, FileExt, Fs, NBTSignalObject)
%
% See also:
%   nbt_Info

%--------------------------------------------------------------------------
% Copyright (C) 2008  Neuronal Oscillations and Cognition group,
% Department of Integrative Neurophysiology, Center for Neurogenomics and
% Cognitive Research, Neuroscience Campus Amsterdam, VU University Amsterdam.
%
% Part of the Neurophysiological Biomarker Toolbox (NBT)
%--------------------------------------------------------------------------

function [SignalInfo, SubjectInfo] = nbt_CreateInfoObject(filename, FileExt, Fs, SignalName, Signal)
disp('Creating Info objects')


if(isempty(Fs))
    Fs = input('Please, specify the sampling frequency? ');
end
if(isempty(SignalName))
    SignalName = input('Please, specify the signal name? ','s');
end
try
    IDdots = strfind(filename,'.');
    [SignalInfo, SubjectInfo] = generateObjects;
catch
    filename = input('Please write filename in correct format, <ProjectID>.S<SubjectID>.<Date in YYMMDD>.Condition ','s');
    IDdots = strfind(filename,'.');
    [SignalInfo, SubjectInfo] = generateObjects;
end


%nested function part
    function [SignalInfo, SubjectInfo] = generateObjects
        SubjectInfo = nbt_SubjectInfo;
        SignalInfo  = nbt_SignalInfo;
        if(~isempty(FileExt))
            SubjectInfo.fileName  = filename(1:(strfind(filename,FileExt)-2));  % Filename of the Signal file
            SignalInfo.subjectInfo = [SubjectInfo.fileName '_info.mat'];
            SubjectInfo.conditionID = filename((IDdots(3)+1):(IDdots(4)-1));
        else
            SubjectInfo.fileName  = filename;  % Filename of the Signal file
            SignalInfo.subjectInfo = [SubjectInfo.fileName];
            SubjectInfo.conditionID = filename((IDdots(3)+1):end);
        end
        SubjectInfo.projectInfo = [filename(1:(IDdots(1)-1)) '.mat' ]; %pointer to projectInfo.mat files
        SubjectInfo.subjectID = str2double(filename((IDdots(1)+2):(IDdots(2)-1)));  % The subject ID
        % The condition ID, e.g., ECR1
        SubjectInfo.fileNameFormat = '<ProjectID>.S<SubjectID>.<Date in YYYYMMDD>.Condition'; %Filename format, should always be in NBT format (but open for other format)
        SubjectInfo.info.dateOfRecording = filename((IDdots(2)+1):(IDdots(3)-1));
        
        SignalInfo.timeOfRecording =  filename((IDdots(2)+1):(IDdots(3)-1));
        SignalInfo.signalName = SignalName;                  %The name of the signal
        SignalInfo.signalID   = nbt_MakeNBTDID;                    %A unique ID genearated by nbt_makeNBTDID;
        try
           % if(length(Signal)< SignalInfo.convertedSamplingFrequency*300)
           %     SignalInfo.signalSHA256  =  nbt_getHash(single(Signal));             %The SHA256 hash of the Signal
           % end
        catch
            disp('NBT: SHA256 hash of signal is missing due to out of memory');
        end
        SignalInfo.nbtVersion   = nbt_getVersion;               % The NBT version using nbt_getVersion
        SignalInfo.convertedSamplingFrequency = Fs;
        SubjectInfo.lastUpdate = datestr(now);
        SignalInfo.lastUpdate  = datestr(now);
    end
end