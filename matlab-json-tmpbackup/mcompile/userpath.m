function p = userpath(inArg)
%USERPATH User environment path.
%   USERPATH returns a path string containing the user specific portion of
%   the path (if it exists). The userpath is the first folder or folders in
%   the list of folders returned by PATHDEF and thus affects the search path. 
%
%   The userpath consists of a primary path, and on certain platforms, 
%   also contains a secondary path. The primary path is only one folder, but
%   the secondary path can contain multiple folders.
%
%   The default primary userpath is platform specific: on Windows,
%   it is the user's "Documents" (or "My Documents" on WinXP) folder
%   appended with "MATLAB".  On the Mac, it is the user's
%   "Documents" folder ($home/Documents) appended with "MATLAB".
%   On Unix, it is the user's $home appended by Documents and
%   MATLAB; if there is no $home/Documents directory, the default
%   primary userpath will not be used.
%
%   The secondary userpath is available only on UNIX and Mac and is taken 
%   from the MATLABPATH environment variable.
%
%   USERPATH(path) changes the current value of the primary userpath to the 
%   folder passed in. It updates the current MATLAB path, and this
%   new primary userpath will persist across MATLAB sessions. 
%
%   USERPATH('reset') resets the primary userpath to the default.  It updates
%   the current MATLAB path, and this new primary userpath will persist across
%   MATLAB sessions. 
%
%   USERPATH('clear') removes the primary userpath.  It updates the current
%   MATLAB path, and this new primary userpath will persist across MATLAB sessions.  
%
%   See also PATHDEF.

%   Copyright 1984-2011 The MathWorks, Inc. 
%   $Revision: 1.9.2.9 $ $Date: 2012/02/14 03:31:48 $

% Validate number of arguments
narginchk(0, 1);

% because ISPC is not available during MATLAB startup
isComputerPc = strncmp(computer,'PC',2);

% If found, process argument and return.  
if nargin == 1 
    if strcmp(inArg, 'reset') == 1
        resetUserPath;
    elseif strcmp(inArg, 'clear') == 1
        clearUserPath;
    else
        setUserPath(inArg);
    end
    return
 end

% append the user work directory to the path
p = system_dependent('getuserworkfolder');
if exist(p,'dir')
     if isAbsolute(p)
         if isComputerPc
             p(end+1) = ';';
         else
             p(end+1) = ':';
         end
     else
         if isComputerPc
             warning(message('MATLAB:userpath:invalidUserpath'));
         end
         p = '';
     end
else 
     if ~isempty(p)
        if isComputerPc
            warning(message('MATLAB:userpath:invalidUserpath'));
        end
        p = '';
     end
end
if ~isComputerPc
    mlp = getenv('MATLABPATH');
    if ~isempty( mlp )
        p = [p, mlp, ':'];
    end
    % Remove any redundant toolbox/local
    p = strrep(p,[matlabroot '/toolbox/local:'],'');
    p = strrep(p,'::',':');
end

function resetUserPath
oldUserPath = system_dependent('getuserworkfolder');
rmpathWithoutWarning(oldUserPath);
defaultUserPath = system_dependent('getuserworkfolder', 'default');
addpath(defaultUserPath);
s = Settings;
matlabNode = s.matlab;
if (matlabNode.isSet('UserPath','user'))
    matlabNode.unset('UserPath', 'user');
end

 
function setUserPath(newPath)
if exist(newPath, 'dir')
    % Insure that p is an absolute path
    if isAbsolute(newPath)
        oldUserPath = system_dependent('getuserworkfolder');
        rmpathWithoutWarning(oldUserPath);
        addpath(newPath);
        s = Settings;
        matlabNode = s.matlab;
        set(matlabNode, 'UserPath', newPath);
    else
        error(message('MATLAB:userpath:invalidInput'));
    end
else
    error(message('MATLAB:userpath:invalidInput'));
end

function clearUserPath
oldUserPath = system_dependent('getuserworkfolder');
rmpathWithoutWarning(oldUserPath);
s = Settings;
matlabNode = s.matlab;
set(matlabNode, 'UserPath', '');



function rmpathWithoutWarning(pathToDelete)
if ~isempty(pathToDelete)
    [lastWarnMsg, lastWarnId] = lastwarn;
    oldWarningState = warning('off','MATLAB:rmpath:DirNotFound');
    rmpath(pathToDelete);
    warning(oldWarningState.state,'MATLAB:rmpath:DirNotFound')
    lastwarn(lastWarnMsg, lastWarnId);
end

function status = isAbsolute(file)

% because ISPC is not available during MATLAB startup
isComputerPc = strncmp(computer,'PC',2);

if isComputerPc
   status = ~isempty(regexp(file,'^[a-zA-Z]*:\/','once')) ...
            || ~isempty(regexp(file,'^[a-zA-Z]*:\\','once')) ...
            || strncmp(file,'\\',2) ...
            || strncmp(file,'//',2);
else
   status = strncmp(file,'/',1);
end
