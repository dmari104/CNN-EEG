% This method returns an InfoCell which, e.g., can be used to fill the boxes in the
% defineGroup GUI.
function [InfoCell, BioCell, IdentCell] = getSubjectInfo(GrpObj)

%First we determine which database is used.
switch GrpObj.databaseType
    case 'NBTelement' %NBTelement database in base.
        [InfoCell, BioCell, IdentCell] = getSubjectInfo_NBTelement(GrpObj,0);
    case 'File' %File based database.
        [InfoCell, BioCell, IdentCell] = getSubjectInfo_NBTelement(GrpObj,1);
end
end