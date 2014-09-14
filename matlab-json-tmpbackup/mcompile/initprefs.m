function initprefs
%INITPREFS Runs all PREFSPANEL functions.
%   INITPREFS scans the MATLAB path for all files called prefspanel.m and
%   evaluates each in turn.  Each prefspanel.m file registers the preferences
%   panel for a given toolbox.
%
%   See also PREFSPANEL

%   Copyright 1984-2008 The MathWorks, Inc.
%   $Revision: 1.3.2.6 $  $Date: 2012/02/14 03:31:45 $

all_prefspanels = which('-all','prefspanel.m');
for i = 1:length(all_prefspanels)
    fid  = fopen(all_prefspanels{i}, 'rb');
    if fid ~= -1
        % set file pointer to EOF
        fseek(fid,0,1); 
        % get the number of bytes from start of file
        numBytes = ftell(fid); 
        % set file pointer back at start of file
        fseek(fid,0,-1); 
        % read file
        file=fread(fid,[1,numBytes],'char=>char');
        fclose(fid);
        idx = strfind(file, 'prefspanel');
        if ~isempty(idx)
        	file(1:(idx(1)+10)) = [];
        end
        try
            evaluation_fcn(file);            
        catch exc
            defwarn = warning;
            warning('on', 'MATLAB:initprefs:ShowErrorAsWarning')
            warning(message('MATLAB:initprefs:ShowErrorAsWarning', all_prefspanels{ i }, exc.message));
            warning(defwarn)
        end
    end
end

% This function prevents the prefspanel function from changeing variables
% in the workspace of initprefs
function evaluation_fcn(file)

eval(file);