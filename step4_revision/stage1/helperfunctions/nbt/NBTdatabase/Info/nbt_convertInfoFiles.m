% This function converts Info objects to the new SubjectInfo and SignalInfo
% objects (from NBT v0.5.0-alpha).
% Copyright (C) 2014 Simon-Shlomo Poil
%
% Part of the Neurophysiological Biomarker Toolbox (NBT)
%
%
function nbt_convertInfoFiles(startpath)
d = dir(startpath);
for j=3:length(d)
    if (d(j).isdir)
        nbt_convertInfoFiles([startpath filesep  d(j).name ]);
    else
        
            b  = strfind(d(j).name,'mat');
            cc = strfind(d(j).name,'info');
            
            if (~isempty(b) && ~isempty(cc))
                % here comes the conversion
                oldInfo = load(d(j).name);
                oldInfoFields = fields(oldInfo);
                %First we create the SubjectInfo
                SubjectInfo = nbt_SubjectInfo;
                
                try
                SubjectInfo.projectInfo = [oldInfo.(oldInfoFields{1}).projectID '.mat'];
                SubjectInfo.info.researcherID = oldInfo.(oldInfoFields{1}).researcherID;
                SubjectInfo.subjectID = oldInfo.(oldInfoFields{1}).subjectID;
                SubjectInfo.conditionID = oldInfo.(oldInfoFields{1}).condition;
                SubjectInfo.fileName = oldInfo.(oldInfoFields{1}).file_name;
                SubjectInfo.fileNameFormat = oldInfo.(oldInfoFields{1}).file_name_format;
                SubjectInfo.info = oldInfo.(oldInfoFields{1}).Info;
                SubjectInfo.info.dateOfRecording = oldInfo.(oldInfoFields{1}).time_of_recording;
                SubjectInfo.notes = oldInfo.(oldInfoFields{1}).notes;
                SubjectInfo.info.subjectGender = oldInfo.(oldInfoFields{1}).subject_gender;
                SubjectInfo.info.subjectAge = oldInfo.(oldInfoFields{1}).subject_age;
                SubjectInfo.info.subjectHeadsize = oldInfo.(oldInfoFields{1}).subject_headsize;
                SubjectInfo.info.subjectHandedness = oldInfo.(oldInfoFields{1}).subject_handedness;
                SubjectInfo.info.subjectMedication = oldInfo.(oldInfoFields{1}).subject_medication;
                
                SubjectInfo.lastUpdate = oldInfo.(oldInfoFields{1}).LastUpdate;
                catch
                    continue
                end
                save(d(j).name, 'SubjectInfo');
                
                %then we create the SignalInfo objects
                for i=1:length(oldInfoFields)
                    tmp = nbt_SignalInfo;
                    tmp.subjectInfo     = oldInfo.(oldInfoFields{i}).file_name;
                    tmp.signalName      = oldInfoFields{i}(1:end-4);
                    tmp.signalID        = oldInfo.(oldInfoFields{i}).NBTDID;
                    tmp.signalOrigin    = 'converted from old Info object';
                    tmp.researcherID    = oldInfo.(oldInfoFields{i}).researcherID;
                    tmp.signalType      = oldInfo.(oldInfoFields{i}).fileType;
                    tmp.frequencyRange  = oldInfo.(oldInfoFields{i}).frequencyRange;
                    tmp.timeOfRecording = oldInfo.(oldInfoFields{i}).time_of_recording;
                    tmp.originalSamplingFrequency = oldInfo.(oldInfoFields{i}).original_sample_frequency;
                    tmp.notes           = oldInfo.(oldInfoFields{i}).notes;
                    tmp.badChannels     = oldInfo.(oldInfoFields{i}).BadChannels;
                    tmp.nonEEGch        = oldInfo.(oldInfoFields{i}).NonEEGch;
                    tmp.eyeCh           = oldInfo.(oldInfoFields{i}).EyeCh;
                    tmp.reference       = oldInfo.(oldInfoFields{i}).reference;
                    tmp.lastUpdate      = oldInfo.(oldInfoFields{i}).LastUpdate;
                    tmp.interface       = oldInfo.(oldInfoFields{i}).Interface;
                    tmp.nbtVersion      = nbt_getVersion;
                    tmp.convertedSamplingFrequency = oldInfo.(oldInfoFields{i}).converted_sample_frequency;
                    eval([ oldInfoFields{i} '= tmp;']);
                    save(d(j).name,(oldInfoFields{i}),'-append')
            
                end
            end
    end
end
end