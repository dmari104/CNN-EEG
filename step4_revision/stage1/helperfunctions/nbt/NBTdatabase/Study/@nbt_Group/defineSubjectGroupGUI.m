function GrpObj = defineSubjectGroupGUI(GrpObj, InfoCell, BioCell, IdentCell)
%defineGroupGUI returns a nbt_Group object based on the selection made in
%the GUI

InfoCellList = InfoCell(:,1)'; 


% %First we ask the user which parameters to use. 
 ParameterSelection = figure('Units','pixels', 'name','NBT: Define parameters' ,'numbertitle','off','Position',[390.0000  456.7500  400  320], ...
     'MenuBar','none','NextPlot','new','Resize','off');
 PSPanel = uipanel(ParameterSelection,'Title','Select Parameters','FontSize',7,'Units','pixels','Position',[10 10 300 300],'BackgroundColor','w','fontweight','bold');
 listBoxP = uicontrol(PSPanel,'Style','listbox','Units','pixels',...
             'Position',[1 1 295 280],...
            'BackgroundColor','white',...
             'Max',10,'Min',1, 'String', InfoCellList,'Value',[]);
%Ok button         
uicontrol(ParameterSelection,'Style','pushbutton','Units','pixels','Position',[320 10 40 40], 'String','OK','callback', @closeWindow);
uiwait(ParameterSelection) %now we wait for the user to select parameters - GroupSelection is closed by groupdefinition below      
         
         

%Define "Define Group" window
GroupSelection = figure('Units','pixels', 'name','NBT: Define Group' ,'numbertitle','off','Position',[390.0000  456.7500  1000  320], ...
    'MenuBar','none','NextPlot','new','Resize','off');
GroupSelection=nbt_movegui(GroupSelection);

g = gcf;
Col = get(g,'Color');

noPanels = size(InfoCell,1);

if noPanels > 6
    p = get(GroupSelection,'Position');
    set(GroupSelection,'Position',[p(1) p(2)/2 p(3) p(4)*2]);
    
    panelWidth = floor((980 / 5));
    
    Gp = zeros(noPanels,1);
    listBox = zeros(noPanels,1);
    for i = 1:5
        startX = 10 + (panelWidth*(i-1));
        Gp(i) = uipanel(GroupSelection,'Title',InfoCell{i,1},'FontSize',7,'Units','pixels','Position',[startX 100+p(4) panelWidth-20 200],'BackgroundColor','w','fontweight','bold');
        listBox(i) = uicontrol(Gp(i),'Style','listbox','Units','pixels',...
            'Position',[1 1 panelWidth-20 180],...
            'BackgroundColor','white',...
            'Max',10,'Min',1, 'String', InfoCell{i,2},'Value',[]);
    end
    
    
    for i = 6:noPanels
        startX = 10 + (panelWidth*(i-6));
        Gp(i) = uipanel(GroupSelection,'Title',InfoCell{i,1},'FontSize',7,'Units','pixels','Position',[startX 100 panelWidth-20 200],'BackgroundColor','w','fontweight','bold');
        listBox(i) = uicontrol(Gp(i),'Style','listbox','Units','pixels',...
            'Position',[1 1 panelWidth-20 180],...
            'BackgroundColor','white',...
            'Max',10,'Min',1, 'String', InfoCell{i,2},'Value',[]);
    end
    
    
    
else
    panelWidth = floor((980 / noPanels));
    
    Gp = zeros(noPanels,1);
    listBox = zeros(noPanels,1);
    for i = 1:noPanels
        startX = 10 + (panelWidth*(i-1));
        Gp(i) = uipanel(GroupSelection,'Title',InfoCell{i,1},'FontSize',7,'Units','pixels','Position',[startX 100 panelWidth-20 200],'BackgroundColor','w','fontweight','bold');
        listBox(i) = uicontrol(Gp(i),'Style','listbox','Units','pixels',...
            'Position',[1 1 panelWidth-20 180],...
            'BackgroundColor','white',...
            'Max',10,'Min',1, 'String', InfoCell{i,2},'Value',[]);
    end
    
    
end

text_ui7= uicontrol(GroupSelection,'Style','text','Position',[700 70 200 20],'string','Write a name for the Group','fontsize',10);
text_ui8= uicontrol(GroupSelection,'Style','edit','Position',[700 50 200 20],'string','','fontsize',10);

plotButton = uicontrol(GroupSelection,'Style','pushbutton','Units','pixels','Position',[920 30 40 40], 'String','OK','callback', {@groupdefinition,noPanels, BioCell, IdentCell});
uiwait(GroupSelection) %now we wait for the user to select parameters - GroupSelection is closed by groupdefinition below

% --- callback function - nested function
    function groupdefinition(src,evt,noPanels, BioCell, IdentCell)
        drawnow
        set(plotButton,'String', 'Busy...');
        
        %the following simply gets the selections from the GUI and add them
        %to the nbt_Group object
        
        for ii = 1:noPanels
            picked = get(listBox(ii),'Value');
            if ~isempty(picked)
                elementName = get(Gp(ii),'Title');
                pickedLabels = get(listBox(ii),'String');
                eval(['GrpObj.parameters.' elementName ' = [];']);
                for j = 1:length(picked)
                    eval(['GrpObj.parameters.' elementName ' = [GrpObj.parameters.' elementName '; pickedLabels(picked(j))];']);
                end
            end
        end
        
        GrpObj.groupName = get(text_ui8,'String');
        GrpObj.biomarkerList = BioCell;
        GrpObj.identList = IdentCell;

        if(isempty(GrpObj.groupName))
            set(plotButton,'String', 'OK');
            disp('Please write a group name to continue');
            return
        end
        close(GroupSelection)
        drawnow
    end

    function closeWindow(src,evt)
        %we recontruct the InfoCell depending on the parameters selected.
        selectionListP = get(listBoxP,'Value');
        idx = 0;
        for s=selectionListP
            idx = idx+1;
            InfoCelltmp{idx,1} = InfoCell{s,1};
            InfoCelltmp{idx,2} = InfoCell{s,2};
        end
        InfoCell = InfoCelltmp;
       close(ParameterSelection)
    end

end