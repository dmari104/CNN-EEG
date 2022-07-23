%nbt_DeleteSignal - will delete the Signal in all files.
function nbt_DeleteSignal(SignalPath, SignalName)
d= dir (SignalPath);
for j=3:length(d)
    if (d(j).isdir )
        %
    else
        b = strfind(d(j).name,'mat');
        cc= strfind(d(j).name,'analysis');
        
        bbb = strfind(d(j).name,'mat');
        ccc= strfind(d(j).name,'info');
        
        if (length(b)~=0  && length(cc)~=0)
            deleteInfo([SignalPath  filesep d(j).name], SignalName);
        end
        
        if (length(bbb)~=0  && length(ccc)~=0)
            deleteSignal([SignalPath  filesep d(j).name], SignalName);
        end
    end
end

end
%nested functions
    function deleteInfo(fileName, SignalName)
        load(fileName)
        s = whos;
        for i=1:length(s)
            if(~strcmp(s(i).name,[SignalName 'Info']))
                save(fileName,s(i).name,'-append')
            end
        end
    end

    function deleteSignal(fileName, SignalName)
         load(fileName)
        s = whos;
        for i=1:length(s)
            if(~strcmp(s(i).name,SignalName))
                save(fileName,s(i).name,'-append')
            end
        end 
    end

