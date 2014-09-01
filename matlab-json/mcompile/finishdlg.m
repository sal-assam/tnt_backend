%FINISHDLG  Display a dialog to cancel quitting
%   Change the name of this file to FINISH.M and 
%   put it anywhere on your MATLAB path. When you 
%   quit MATLAB this file will be executed.

%   Copyright 1984-2000 The MathWorks, Inc. 
%   $Revision: 1.6.2.1 $  $Date: 2011/01/28 18:50:29 $

Yes = getString(message('MATLAB:finishdlg:Yes'));
No = getString(message('MATLAB:finishdlg:No'));
button = questdlg(getString(message('MATLAB:finishdlg:ReadyToQuit')), ...
                  getString(message('MATLAB:finishdlg:ExitingDialogTitle')),Yes,No,No);
switch button
  case Yes,
    disp(getString(message('MATLAB:finishdlg:ExitingMATLAB')));
      %Save variables to matlab.mat
      save 
  case No,
    quit cancel;
end
