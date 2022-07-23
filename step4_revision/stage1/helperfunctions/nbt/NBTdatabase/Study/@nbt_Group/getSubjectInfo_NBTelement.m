function [InfoCell, BioCell, IdentCell]=getSubjectInfo_NBTelement(GrpObj,fileSwitch)
IdentCell = cell(0,0);
%Any Elements loaded?
s = evalin('base', 'whos');
k = 0;
for i = 1:length(s)
    if strcmp(s(i).class,'nbt_NBTelement');
        k = k+1;
        flds{k} = s(i).name;
    end
end
if k==0
    try
        disp('Loading NBTelementBase.mat...please wait...')
        evalin('base', ['load(' '''' pwd  filesep 'NBTelementBase.mat''' ')']);
    catch % in the case the NBTelement database does not exist
        disp('NBTeleementBase.mat not found...generating...')
        disp('NBT: Assuming your data is in current directory: importing from current directory')
        nbt_importGroupInfos(pwd,fileSwitch); %import data to NBTelements%
%         nbt_pruneElementTree;      %prune elements with only one level
        evalin('base', 'load(''NBTelementBase.mat'')');
    end
    nbt_primeNBTelementCache;
    s = whos('-file','NBTelementBase.mat');
    m = 1;
    for i = 1:length(s)
        if(strcmp(s(i).class, 'nbt_NBTelement'))
            flds{m} = s(i).name;
            m = m+1;
        end
    end
end
index = zeros(length(flds),1);
for i = 1:length(flds)
    index(i) = evalin('base',[flds{i} '.ElementID';]);
end

[~, inds] = sort(index);
nbtVersion = evalin('base','Project.nbtVersion');
if(~isempty(nbtVersion))
    if(isfield(nbtVersion,'importDate'))
        disp(['NBTelementBase import date:' nbtVersion.importDate ] );
    else
        disp('NBTelementBase import date: not set');
    end
    disp(['NBTelementBase load date: ' evalin('base','Project.loadDate')]);
end


%InfoCell = cell(length(inds),2);
k = 0;
n = 0;
m = 0;
for i = 1:length(inds)
    if evalin('base',[flds{inds(i)} '.Identifier';])
        m= m+1;
        IdentCell{m,1} = flds{inds(i)};
        IdentCell{m,2} = evalin('base',[flds{inds(i)} '.Data;']);
    else
        isBiomarker = evalin('base',[flds{inds(i)} '.isBiomarker;']);
        bios = evalin('base',[flds{inds(i)} '.Biomarkers;']);
        if ~isBiomarker;
            k= k+1;
            InfoCell{k,1} = flds{inds(i)};
            InfoCell{k,2} = evalin('base',[flds{inds(i)} '.Data';]);
        else
            %Its a biomarker
            
            %work out how many unique identifiers the biomarker has
            identStore = [];
            parent = evalin('base',[flds{inds(i)} '.Uplink']);
            parent = find(index==parent);
            while evalin('base',[flds{parent} '.Identifier == 1'])
                identStore = [identStore; parent];
                parent = evalin('base',[flds{parent} '.Uplink']);
                parent = find(index==parent);
            end
            noIdents = length(identStore);
            
            if noIdents >0
                %work out how many unique biomarkers there, by
                %looking at the ids
                ids = evalin('base',[flds{identStore(1)} '.ID']);
                
                % for id = 1:length(ids)
                %  stt = strsplit(ids{id},'.');
                %    [stt, idKeep] = strtok(ids,'.');
                %    idsStore = [idsStore stt];
                %      for j = 2:length(identStore)
                % idsStore(id,j) = str2num(stt);
                %          [stt, idKeep] = strtok(idKeep,'.');
                %         idsStore = [idsStore stt];
                %     end
                %end
                dotIndex = strfind(ids,'.');
                idsStore = cell(length(dotIndex),1);
                numS = length(identStore);
                for mm=1:length(dotIndex)
                    idsStore{mm}=ids{mm}(1:dotIndex{mm}(numS)-1);
                end
                
                uniqueIds = unique(idsStore);
                uniqueIds = cellfun(@(s) strsplit(s,'.'),uniqueIds,'UniformOutput',false);
                
                
                %Get names of identifiers
                nameIdent = [];
                for a = 1:noIdents
                    tmp = flds{identStore(a)};
                    if(~strcmp('Signals',tmp))
                        nameIdent{a} = tmp(length(flds{inds(i)}) + 1:end);
                    else
                        nameIdent{a} = '_Signals';
                    end
                end
                
                %construct overall biomarkers
                for j = 1:length(uniqueIds)
                    nm = [flds{inds(i)} '{'];
                    for a = 1:noIdents
                        nm = [nm nameIdent{a} '_' evalin('base',[flds{identStore(a)} '.Data{' uniqueIds{j}{a}  '};'])];
                    end
                    
                    for kk = 1:length(bios)
                        n = n+1;
                        BioCell{n} = [nm '}.' bios{kk}];
                    end
                end
            else
                for j = 1:length(bios)
                    n = n+1;
                    BioCell{n} = [flds{inds(i)} '.' bios{j}];
                end
            end
        end
    end
end
end