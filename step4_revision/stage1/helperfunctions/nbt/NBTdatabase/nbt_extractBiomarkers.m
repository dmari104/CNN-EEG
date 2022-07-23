function [BiomarkerObjects,Biomarkers, BiomarkersFullList]=nbt_extractBiomarkers(s)
BiomarkerObjects = cell(0,0);
narginchk(0,1)
if(~exist('s','var'))
    s=evalin('caller','whos');
    counter=1;
    for ii=1:length(s)
        try
        Sclass = superclasses(s(ii).class);
        if ismember('nbt_QBiomarker',Sclass)           
            index = find(ismember(Sclass,'nbt_QBiomarker'));
            Sclass = Sclass(index);
        else
            Sclass = Sclass(1);
        end
        if(strcmp(Sclass{1,1}(end-8:end),'Biomarker'))
            BiomarkerObjects = [BiomarkerObjects, s(ii).name];
            Biomarkers{counter}=evalin('caller',[s( ii ).name,'.biomarkers;']);
            counter=counter+1;
        end
        catch
        end
    end
else
    load(s)
    s = whos;
    counter=1;
    
    % temporary adjustement
    for ii=1:length(s)
        try
            Sclass = superclasses(s(ii).class);
            Sclass = Sclass(1);
            if(strcmp(Sclass{1,1}(end-8:end),'Biomarker') && ~strcmp(s(ii).class,'nbt_questionnaire'))
                BiomarkerObjects    = [BiomarkerObjects, s(ii).name];
                try
                    Biomarkers{counter} = eval([s( ii ).name,'.biomarkers;']);
                catch
                    Biomarkers{counter} = eval([s( ii ).name,'.biomarkers;']);
                end
                counter=counter+1;
            end
        catch
        end
    end 
end

if(nargout>2)
 in = 1;
    for i = 1:length(BiomarkerObjects)
        for m = 1:length(Biomarkers{1,i})
            BiomarkersFullList{in,1} = strcat(BiomarkerObjects{i}, strcat( '.', Biomarkers{1,i}{m}));
            in = in + 1;
        end
        if(isempty(Biomarkers{1,i}))
            BiomarkersFullList{in,1} = BiomarkerObjects{i};
            in = in + 1;
        end
    end
end
end