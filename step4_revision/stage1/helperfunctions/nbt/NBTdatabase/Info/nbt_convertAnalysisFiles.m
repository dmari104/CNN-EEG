% This function is converting analysis files to the new format of analysis files (NBTv0.5.0-alpha) 
% Copyright (C) 2014 Neuronal Oscillations and Cognition group, Department of Integrative Neurophysiology, Center for Neurogenomics and Cognitive Research, Neuroscience Campus Amsterdam, VU University Amsterdam.
%
% Part of the Neurophysiological Biomarker Toolbox (NBT)
%
%
function nbt_convertAnalysisFiles(startpath,signalName)

if isempty(signalName)
    everyFile = cell2mat(inputdlg('Do you want to define a different signal attached for each biomarker? {y/n}: ' ));
    if strcmp(everyFile(1),'y')
    else
        if strcmp(everyFile(1),'n')
            signalName = cell2mat(inputdlg('Please type SignalInfoName (e.g. RawSignalInfo): ' ));
        else
            disp('please either input y or n')
            return
        end
    end
end
firstTime = 1;
d = dir(startpath);
for j=3:length(d)
    if (d(j).isdir )
        nbt_convertAnalysisFiles([startpath filesep d(j).name ],signalName);
    else
        b  = strfind(d(j).name,'mat');
        cc = strfind(d(j).name,'analysis');
        
        if (~isempty(b)  && ~isempty(cc))
            % here comes the conversion
            oldBiomarkers = load(d(j).name);
            oldBiomarkerFields = fields(oldBiomarkers);
            if ~isempty(signalName)
                sigInfo = load([d(j).name(1:end-12) 'info.mat']);
                SubjectInfo = sigInfo.SubjectInfo;
                eval([signalName 'Info = sigInfo.' signalName 'Info;']);
            end
            
            for i=1:length(oldBiomarkerFields)
                
                if(isa(oldBiomarkers.(oldBiomarkerFields{i}),'nbt_CoreBiomarker'))
                    if(isa(oldBiomarkers.(oldBiomarkerFields{i}),'nbt_SignalBiomarker'))
                        
                        if(isa(oldBiomarkers.(oldBiomarkerFields{i}),'nbt_amplitude'))
                            if firstTime
                                disp('Amplitude hack for frequency Range - Assumes amplitude_lf_hf form');
                                firstTime = 0;
                            end
                            x = oldBiomarkerFields{i};
                            y = strfind(x,'_');
                            freqRange = [str2num(x(y(1)+1:y(2)-1)) str2num(x(y(2)+1:y(3)-1))];
                            eval(['oldBiomarkers.' oldBiomarkerFields{i} '.FrequencyRange = freqRange;']);
                        end
                        
                        eval([ oldBiomarkerFields{i} '= convertBiomarker( oldBiomarkers.(oldBiomarkerFields{i}),d(j).name);']);
                        
                        if isempty(signalName)
                            signalName = cell2mat(inputdlg(['Please type SignalInfoName (e.g. RawSignalInfo) for : ' oldBiomarkerFields{i}]));
                            sigInfo = load([d(j).name(1:end-12) 'info.mat']);
                            SubjectInfo = sigInfo.SubjectInfo;
                            eval([signalName ' = sigInfo.' signalName ';']);
                        end
                        eval([ oldBiomarkerFields{i} '= nbt_UpdateBiomarkerInfo(' oldBiomarkerFields{i} ',' signalName 'Info);']);
                        
%                         % check if field frequencyRange exists in the biomarker object
%                         eval([ 'freqRng = isempty(' oldBiomarkerFields{i} '.frequencyRange);' ]);
%                         
%                         if (freqRng == 1)
%                         % hack for filling the freq range field
%                             if (~isempty(strfind(oldBiomarkerFields{i},'alpha'))) || (~isempty(strfind(oldBiomarkerFields{i},'8_13')))
%                                 eval([oldBiomarkerFields{i} '.frequencyRange = [8 13];']);
%                             end
% 
%                             if (~isempty(strfind(oldBiomarkerFields{i},'beta'))) || (~isempty(strfind(oldBiomarkerFields{i},'13_30')))
%                                 eval([oldBiomarkerFields{i} '.frequencyRange = [13 30];']);
%                             end
% 
%                             if (~isempty(strfind(oldBiomarkerFields{i},'gamma'))) || (~isempty(strfind(oldBiomarkerFields{i},'30_45')))
%                                 eval([oldBiomarkerFields{i} '.frequencyRange = [30 45];']);
%                             end
% 
%                             if (~isempty(strfind(oldBiomarkerFields{i},'delta'))) || (~isempty(strfind(oldBiomarkerFields{i},'1_4')))
%                                 eval([oldBiomarkerFields{i} '.frequencyRange = [1 4];']);
%                             end
% 
%                             if (~isempty(strfind(oldBiomarkerFields{i},'theta'))) || (~isempty(strfind(oldBiomarkerFields{i},'4_8')))
%                                 eval([oldBiomarkerFields{i} '.frequencyRange = [4 8];']);
%                             end
%                         end
                        
                        eval([signalName 'Info.listOfBiomarkers = [' signalName 'Info.listOfBiomarkers ; {''' oldBiomarkerFields{i} '''}];']);
                        
                        save(d(j).name,(oldBiomarkerFields{i}),'-append')
                    else
                        eval([ oldBiomarkerFields{i} '= convertBiomarker( oldBiomarkers.(oldBiomarkerFields{i}),d(j).name);']);
                        eval(['SubjectInfo.listOfBiomarkers = [SubjectInfo.listOfBiomarkers ; {''' oldBiomarkerFields{i} '''}];']);
                        
                        save(d(j).name,(oldBiomarkerFields{i}),'-append')
                    end
                end
                
            end
            save([d(j).name(1:end-12) 'info.mat'],[signalName 'Info'],'SubjectInfo','-append')
        end
    end
end
end