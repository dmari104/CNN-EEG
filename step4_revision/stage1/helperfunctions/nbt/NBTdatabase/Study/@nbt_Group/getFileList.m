function fileList = getFileList(GrpObj)
%return filenames of group members
DataObj = nbt_Data;
DataObj.biomarkers{1} = 'Condition'; %just a dummy.
DataObj.biomarkerIdentifiers = cell(1,1);
DataObj = prepareDataObj(DataObj,GrpObj);

fileList = getFileList(DataObj);
end