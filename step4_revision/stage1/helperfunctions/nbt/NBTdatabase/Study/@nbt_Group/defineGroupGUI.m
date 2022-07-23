function GrpObj = defineGroupGUI(GrpObj, InfoCell)

%defineGroupGUI returns a nbt_Group object based on the selection made in
%the GUI


%Define "Define Group" window
GroupSelection = figure('Units','pixels', 'name','NBT: Define Group' ,'numbertitle','off','Position',[390.0000  456.7500  1000  320], ...
    'MenuBar','none','NextPlot','new','Resize','off');
GroupSelection=nbt_movegui(GroupSelection);

g = gcf;
Col = get(g,'Color');
Gp1 = uipanel(GroupSelection,'Title','Conditions','FontSize',10,'Units','pixels','Position',[10 100 150 200],'BackgroundColor','w','fontweight','bold');
listBox1 = uicontrol(Gp1,'Style','listbox','Units','pixels',...
    'Position',[1 1 140 180],...
    'BackgroundColor','white',...
    'Max',10,'Min',1, 'String', InfoCell{4,2},'Value',[]);
Gp2 = uipanel(GroupSelection,'Title','Subjects','FontSize',10,'Units','pixels','Position',[170 100 150 200],'BackgroundColor','w','fontweight','bold');
listBox2 = uicontrol(Gp2,'Style','listbox','Units','pixels',...
    'Position',[1 1 140 180],...
    'BackgroundColor','white',...
    'Max',10,'Min',1, 'String', InfoCell{2,2},'Value',[]);
Gp4 = uipanel(GroupSelection,'Title','Project','FontSize',10,'Units','pixels','Position',[490 100 150 200],'BackgroundColor','w','fontweight','bold');
listBox4 = uicontrol(Gp4,'Style','listbox','Units','pixels',...
    'Position',[1 1 140 180],...
    'BackgroundColor','white',...
    'Max',10,'Min',1, 'String', InfoCell{1,2},'Value',[]);
Gp5 = uipanel(GroupSelection,'Title','Gender','FontSize',10,'Units','pixels','Position',[650 100 150 200],'BackgroundColor','w','fontweight','bold');
listBox5 = uicontrol(Gp5,'Style','listbox','Units','pixels',...
    'Position',[1 1 140 180],...
    'BackgroundColor','white',...
    'Max',10,'Min',1, 'String', InfoCell{5,2},'Value',[]);
% sort age
if ~isempty(InfoCell{6,2})
    readagetmp = sort(InfoCell{6,2});
    for i = 1:length(readagetmp)
        readage{i} = readagetmp(i);
    end
    clear readagetmp;
end

%
Gp6 = uipanel(GroupSelection,'Title','Age','FontSize',10,'Units','pixels','Position',[810 100 150 200],'BackgroundColor','w','fontweight','bold');
listBox6 = uicontrol(Gp6,'Style','listbox','Units','pixels',...
    'Position',[1 1 140 180],...
    'BackgroundColor','white',...
    'Max',10,'Min',1, 'String', readage,'Value',[]);

text_ui7= uicontrol(GroupSelection,'Style','text','Position',[700 70 200 20],'string','Write a name for the Group','fontsize',10);
text_ui8= uicontrol(GroupSelection,'Style','edit','Position',[700 50 200 20],'string','','fontsize',10);

plotButton = uicontrol(GroupSelection,'Style','pushbutton','Units','pixels','Position',[920 30 40 40], 'String','OK','callback', @groupdefinition);

uiwait(GroupSelection) %now we wait for the user to select parameters - GroupSelection is closed by groupdefinition below

% --- callback function - nested function
    function groupdefinition(src,evt)
        set(plotButton,'String', 'Busy...');
        
        %the following simply gets the selections from the GUI and add them
        %to the nbt_Group object
        ConditionList_index = get(listBox1,'Value');
        if ~isempty(ConditionList_index)
            ConditionList = get(listBox1,'String');
            GrpObj.conditionID = ConditionList(ConditionList_index);
        end
        
        SubjectList_index = get(listBox2,'Value');
        if ~isempty(SubjectList_index)
           SubjectList = get(listBox2,'String');
           GrpObj.subjectID = SubjectList(SubjectList_index);
        end
        
        ProjectList_index = get(listBox4,'Value');
        if ~isempty(ProjectList_index)
           ProjectList = get(listBox4,'String');
           GrpObj.projectID = ProjectList(ProjectList_index);
        end

        GenderList_index = get(listBox5,'Value');
        if ~isempty(GenderList_index)
           GenderList = get(listBox5,'String');
           GrpObj.gender = GenderList(GenderList_index);
        end
        
        AgeList_index = get(listBox6,'Value');
        if ~isempty(AgeList_index)
           AgeList = get(listBox6,'String');
           GrpObj.age = AgeList(AgeList_index);
        end

        
        GrpObj.groupName = get(text_ui8,'String');
        if(isempty(GrpObj.groupName))
            set(plotButton,'String', 'OK');
            disp('Please write a group name to continue');
            return
        end
       close(GroupSelection) 
    end
end