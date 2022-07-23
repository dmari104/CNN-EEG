function ProjectInfo = importSubjectInfoFromXLS(XLSfilename,ProjectInfo)
%import subject info from external XLS sheet
if(~exist('ProjectInfo','var'))
   ProjectInfo = nbt_Info; 
end

[dummy,dummy,rawXLS] = xlsread(XLSfilename);
disp('b')

end