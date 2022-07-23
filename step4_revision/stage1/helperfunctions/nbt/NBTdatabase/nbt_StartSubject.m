% Copyright (C) 2010  Neuronal Oscillations and Cognition group, Department of Integrative Neurophysiology, Center for Neurogenomics and Cognitive Research, Neuroscience Campus Amsterdam, VU University Amsterdam.
%
% Part of the Neurophysiological Biomarker Toolbox (NBT)
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%
% See Readme.txt for additional copyright information.
%
function StartSubject()

%mkdir
SaveDir = uigetdir('C:\','Select Project folder');
cd ([SaveDir])
load ProjectInfo.mat
disp('*************************************************************')
disp(' NBTdatabase - Project information')
disp('*************************************************************')

disp('Project ID:')
disp(ProjectInfo.projectID)
disp('Project description:')
disp(eval(['ProjectInfo.Info.ProjectInfo.' ProjectInfo.projectID]))
disp('Conditions:')
disp(ProjectInfo.Info.ProjectInfo.condition)
disp('information last updated')
disp(ProjectInfo.LastUpdate)
disp('by')
disp(ProjectInfo.researcherID)
disp('*************************************************************')
disp('NBTdatabase: Starting new subject in this project')
SubjectInfo = nbt_Info;
disp('Please answer the following questions:')
SubjectInfo.projectID = ProjectInfo.projectID;
SubjectInfo.researcherID = input('What is your researcher ID?', 's');
SubjectInfo.subjectID = input('What is the subject ID of this subject?');
SubjectInfo.NBTDID = input('What is the NBTdatabase ID of this subject? [if empty a new ID will be generated]');
if(isempty(SubjectInfo.NBTDID))
    SubjectInfo.NBTDID = nbt_MakeNBTDID;
    disp('New NBTdatabase ID created')
    disp(SubjectInfo.NBTDID)
end
SubjectInfo.subject_gender = input('Gender:(m/f)','s');
SubjectInfo.subject_age = input('Age');
SubjectInfo.subject_headsize = input('Headsize');
SubjectInfo.subject_handedness = input('Handedness? (l/r)','s');
SubjectInfo.subject_medication = input('Any medication?', 's');
SubjectInfo.notes = input('Any additional notes about the subject?','s');
SubjectInfo.LastUpdate = datestr(now);
mkdir((['S' int2str(SubjectInfo.subjectID)]))
disp('NBTdatabase - Subject directory created')
disp((['S' int2str(SubjectInfo.subjectID)]));

cd (['S' int2str(SubjectInfo.subjectID)])
save SubjectInfo.mat SubjectInfo

end


