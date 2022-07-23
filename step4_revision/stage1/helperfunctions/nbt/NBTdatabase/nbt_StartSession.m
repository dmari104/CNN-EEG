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
function StartSession(varargin)

disp('NBTdatabase: Starting new session')
stopflag = 0;
SaveDir = uigetdir('C:\','Select Subject folder');
cd ([SaveDir])
load SubjectInfo.mat
disp('Please check that the following information is correct:')
disp('Suject ID:')
disp(SubjectInfo.subjectID)
disp('Project ID:')
disp(SubjectInfo.projectID)


disp('NBTdatabase: Session Ready')
while stopflag ~=1
    
    [res userdata err structout] = inputgui( 'geometry', { [1 1] }, ...
        'geomvert', [2], 'uilist', { ...
        { 'style', 'text', 'string', [ 'NBTdatabase Session: What do you want to do?' 10 10 ] }, ...
        { 'style', 'listbox', 'string', 'Enter new log|End session' 'tag' 'choice' } }, 'title', 'NBT - NBTdatabase' );
    
    switch structout.choice
        case 1 % new log
            try
            index = length(SubjectInfo.Info.log)+1;
            catch
                SubjectInfo.Info.log =[];
                index = 1;
            end
            
            SubjectInfo.Info.log(index).Filename = input('Log for filename: ','s');
            SubjectInfo.Info.log(index).message = input('Log message ','s');
            SubjectInfo.Info.log(index).time = datestr(now);
             cd ([SaveDir])
            save SubjectInfo.mat SubjectInfo
            disp('Log saved')
        case 2 % end session
            stopflag = 1;
    end   
end
end





