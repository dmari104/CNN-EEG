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
function StartProject()

% This function should be used to create a new project, update project
% info, or read project info


% create new project
  SaveDir = uigetdir('C:\','Select Project folder');
  
  ProjectInfo = nbt_ProjectInfo;
 
  ProjectInfo.researcherID = input('Enter your researcher ID: ', 's');
  ProjectInfo.projectID = input('Enter project ID: ','s');
  eval(['ProjectInfo.info.ProjectInfo.' ProjectInfo.projectID ' = input(''Please enter a short project description, or link to a project description: '',''s'');'])
  
  disp('Please name your files using the format <ProjectID>.S<SubjectID>.<Date in YYMMDD>.Condition' )
 
  NumConditions = input('How many conditions do you have? :');
  ProjectInfo.numberOfConditions = NumCondtions;
  
  for i=1:NumConditions
      ConditionID = input('Write condition ID: ','s');
      eval(['ProjectInfo.info.ProjectInfo.condition.' ConditionID ' = input(''Please enter a short description of the condition : '',''s'');'])
  end
  
  ProjectInfo.numberOfSubjects = input('How many subjects do you have? :');
  
  ProjectInfo.lastUpdate = datestr(now);
  
  cd ([SaveDir])
  save ProjectInfo.mat ProjectInfo
end