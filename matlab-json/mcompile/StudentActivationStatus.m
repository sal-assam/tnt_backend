function StudentActivationStatus

%   Copyright 2005-2007 The MathWorks, Inc. 

if isstudent 
    feature('launch_activation', 'forcecheck');
else
    disp(getString(message('MATLAB:StudentActivationStatus:OnlyAvailableInStudentVersion')));
end

