function DataObj = prepareDataObj(DataObj,GrpObj)
for bID=1:length(DataObj.biomarkers);
    biomarker = DataObj.biomarkers{bID};
    
    %then we generate the NBTelement call.
    NBTelementCall = ['nbt_GetData(' biomarker ',{'] ;
    %loop over Group parameters
    if (~isempty(GrpObj.parameters))
        groupParameters = fields(GrpObj.parameters);
        for gP = 1:length(groupParameters)
            NBTelementCall = [NBTelementCall groupParameters{gP} ',{' ];
            for gPP = 1:length(GrpObj.parameters.(groupParameters{gP}))-1
                NBTelementCall = [NBTelementCall '''' GrpObj.parameters.(groupParameters{gP}){gPP} ''','];
            end
            gPP = length(GrpObj.parameters.(groupParameters{gP}));
            NBTelementCall = [NBTelementCall '''' GrpObj.parameters.(groupParameters{gP}){gPP} '''};'];
        end
    end
    %then we loop over biomarker identifiers -
    % should be stored as a cell in a cell
    
    bIdentifiers = DataObj.biomarkerIdentifiers{bID};
    
    if(~isempty(bIdentifiers))
        % we need to add biomarker identifiers
        for bIdent = 1:size(bIdentifiers,1)
            if(ischar(bIdentifiers{bIdent,2} ))
                if strcmp(bIdentifiers{bIdent,1},'Signals')
                    NBTelementCall = [NBTelementCall  bIdentifiers{bIdent,1} ',' '''' bIdentifiers{bIdent,2} '''' ';'];
                else
                    NBTelementCall = [NBTelementCall  biomarker '_' bIdentifiers{bIdent,1} ',' '''' bIdentifiers{bIdent,2} '''' ';'];
                end
            else
                NBTelementCall = [NBTelementCall  biomarker '_' bIdentifiers{bIdent,1} ',' num2str(bIdentifiers{bIdent,2}) ';'];
            end
        end
    end
    NBTelementCall = NBTelementCall(1:end-1); % to remove ';'
    %layz eval
    NBTelementCall = [NBTelementCall '},[],1);'];
    snb = strfind(NBTelementCall,',');
    subNBTelementCall = NBTelementCall(snb(1):snb(end-1)-1);
    [DataObj.dataStore{bID,1}, DataObj.pool{bID,1},  DataObj.poolKey{bID,1}] = evalin('base', NBTelementCall);
    assignin('base', 'tmpPool', DataObj.pool)
    assignin('base', 'tmpPoolKey', DataObj.poolKey)
    
    try
        %warning('temporary workaround to match subject from different projects')
        %workaround for matching subjects from different projects.
        ProjectList = evalin('base',['nbt_returnData(Project, tmpPool{' num2str(bID) '}, tmpPoolKey{' num2str(bID) '});']);
        SubjectList = evalin('base',['nbt_returnData(Subject, tmpPool{' num2str(bID) '}, tmpPoolKey{' num2str(bID) '});']);
        uniqueSubjectList = cell(length(SubjectList),1);
        for jj = 1:length(SubjectList)
            %% HACK, FIXME, SH: 07/06/2018. In case there is no project for each individual subject we take the first for everyone
            if size(ProjectList, 2) == 1
                uniqueSubjectList{jj} =  [ProjectList{1} '.' num2str(SubjectList(jj))];
            else
                uniqueSubjectList{jj} =  [ProjectList{jj} '.' num2str(SubjectList(jj))];
            end
        end
        DataObj.uniqueSubjectList{bID,1} =  uniqueSubjectList;
        DataObj.subjectList{bID,1} = SubjectList; 
    catch me
        %Only one Subject?
        disp('Assuming only One subject?');
        [DataObj.subjectList{bID,1}] = evalin('base', 'constant{nbt_searchvector(constant , {''Subject''}),2};');
    end
end
end



