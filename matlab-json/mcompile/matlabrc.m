%MATLABRC Master startup M-file.
%   MATLABRC is automatically executed by MATLAB during startup.
%   It establishes the MATLAB path, sets the default figure size,
%   and sets a few uicontrol defaults.
%
%   On multi-user or networked systems, the system manager can put
%   any messages, definitions, etc. that apply to all users here.
%
%   MATLABRC also invokes a STARTUP command if the file 'startup.m'
%   exists on the MATLAB path.

%   Copyright 1984-2011 The MathWorks, Inc.

if isdeployed || ismcc
    % Turn off warnings about built-in not being visible.
    warning off MATLAB:predictorNoBuiltinVisible
end

if ismcc || ~isdeployed
    % Try to catch a potential search path issue if PATHDEF.M throws an error
    % or when USEJAVA.M is called. USEJAVA is not a builtin and only builtins
    % are guaranteed to be available during initialization.

    try
        % Set up path.
        oldPath = matlabpath;

        % We check for a RESTOREDEFAULTPATH_EXECUTED variable to check whether
        % RESTOREDEFAULTPATH was run. If it was, we don't want to use PATHDEF,
        % since it may have been the culprit of the faulty path requiring us to
        % recover using RESTOREDEFAULTPATH.
        if exist('pathdef','file') && ~exist('RESTOREDEFAULTPATH_EXECUTED','var')
            matlabpath(pathdef);
        end
    
        % Avoid running directly out of the bin/arch directory as this is
        % not supported.
        if ispc,
            pathToBin = [matlabroot,filesep,'bin',filesep,computer('arch')];
            if isequal(pwd, pathToBin),
                cd (matlabroot);
            end;
        end;
    
        % Display helpful hints.
        % If the MATLAB Desktop is not running, then use the old message, since
        % the Help menu will be unavailable.
        if ~ismcc
            if ~usejava('Desktop')
                disp(' ')
                disp(getString(message('MATLAB:matlabrc:ToGetStartedMessage')))
                disp(getString(message('MATLAB:matlabrc:ProductInformationMessage')))
                disp(' ')
            end
        end
    catch exc
        %Show the error that occurred, in case that helps:
    	disp(exc.message);
        % When modifying this code, you can only use builtins
        warning(message('MATLAB:matlabrc:SuspectedPathProblem'));
        % The initial path was $MATLAB/toolbox/local, so ensure we still have it
        if strncmp(computer,'PC',2)
            osPathsep = ';';
        else
            osPathsep = ':';
        end
        matlabpath([oldPath osPathsep matlabpath])
    end
end

try
    % Create and initialize MATLAB root
    % NOTE: Any settings on MATLAB root (0) must be done after this line
    graphics.internal.initializeMATLABRoot();

    % Initialize Handle Graphics including default paper size settings.
    hgrc
catch exc
   warning(message('MATLAB:matlabrc:InitHandleGraphics', exc.identifier, exc.message));
end

try
    % The RecursionLimit forces MATLAB to throw an error when the specified
    % function call depth is hit.  This protects you from blowing your stack
    % frame (which can cause MATLAB and/or your computer to crash).  Set the
    % value to inf if you don't want this protection.
    set(0,'RecursionLimit',500)
catch exc
   warning(message('MATLAB:matlabrc:RecursionLimit', exc.identifier, exc.message));
end

% Set default warning level to WARNING BACKTRACE.  See help warning.
warning backtrace

% Do not initialize the desktop or the preferences panels for deployed 
% applications, which have no desktop.
if ~isdeployed
    try
        % For the 'edit' command, to use an editor defined in the $EDITOR
        % environment variable, the following line should be uncommented
        % (UNIX only)

        %system_dependent('builtinEditor','off')

        if usejava('mwt')
            initprefs %% init java prefs system if java is present
            initdesktoputils  %% init desktop setup code if java is present
        end
    catch exc
        warning(message('MATLAB:matlabrc:InitJava', exc.identifier, exc.message));
    end
end

try
    % Text-based preferences
    NumericFormat = system_dependent('getpref','GeneralNumFormat2');
    % if numeric format is empty, check the old (pre-R14sp2) preference 
    if (isempty(NumericFormat))
        NumericFormat = system_dependent('getpref','GeneralNumFormat');
    end
    if ~isempty(NumericFormat)
        eval(['format ' NumericFormat(2:end)]);
    end
    NumericDisplay = system_dependent('getpref','GeneralNumDisplay');
    if ~isempty(NumericDisplay)
        format(NumericDisplay(2:end));
    end
    if (strcmp(system_dependent('getpref','GeneralEightyColumns'),'Btrue'))
        feature('EightyColumns',1);
    end

    % Map previous Recycling preference to settings
    s = Settings;
    matlabNode = s.matlab;
    % only set the user level setting if it hasn't already been set.
    if (~matlabNode.isSet('DeleteFilesPermanently', 'user'))
        % get the value of this pref from matlab.prf (default is false)
        prefValue = system_dependent('getpref','GeneralDeleteFunctionRecycles');
        if (~isempty(prefValue) && strcmp(prefValue,'Btrue'))
            % if was overridden to be true, so set the value in settings to false.
            matlabNode.set('DeleteFilesPermanently', false);
        else
            matlabNode.set('DeleteFilesPermanently', true);
        end
    end
catch exc
   warning(message('MATLAB:matlabrc:InitPreferences', exc.identifier, exc.message)); 
end

% add default profiler filters
try
  files = { 'profile.m', 'profview.m', 'profsave.m', 'profreport.m', 'profviewgateway.m' };
  for i = 1:length(files)
    fname = which(files{i});
    % if we can't find the profiler files on the path, try the
    % "default" location.
    if strcmp(fname, '')
      fname = fullfile(matlabroot,'toolbox','matlab','codetools',files{i});
    end
    callstats('pffilter', 'add', fname);
  end
catch exc
    warning(message('MATLAB:matlabrc:ProfilerFilters'));
end

% Clean up workspace.
clear
try
    % Enable/Disable selected warnings by default
    warning on  MATLAB:namelengthmaxExceeded
    warning off MATLAB:mir_warning_unrecognized_pragma
  
    if ismcc
        warning off MATLAB:dispatcher:nameConflict
    end

    warning off MATLAB:JavaComponentThreading
    warning off MATLAB:JavaEDTAutoDelegation
    
    % Random number generator warnings
    warning off MATLAB:RandStream:ReadingInactiveLegacyGeneratorState
    warning off MATLAB:RandStream:ActivatingLegacyGenerators

    % Debugger breakpoint suppressed by Desktop
    warning off MATLAB:Debugger:BreakpointSuppressed
    
    warning off MATLAB:class:InvalidDynamicPropertyName
    warning off MATLAB:class:DynPropDuplicatesMethod
    
catch exc
   warning(message('MATLAB:matlabrc:DisableWarnings', exc.identifier, exc.message));
end

% We don't run startup.m from here in deployed apps--it's run from mclmcr.cpp
% because deployed apps call javaaddpath after running matlabrc.m, which clears
% the global workspace.
if ismcc || ~isdeployed
    try
        % Execute startup M-file, if it exists.
        if (exist('startup','file') == 2) ||...
                (exist('startup','file') == 6)
            startup
        end
    catch exc
        warning(message('MATLAB:matlabrc:Startup', exc.identifier, exc.message)); 
    end
end

% Defer echo until startup is complete
if strcmpi(system_dependent('getpref','GeneralEchoOn'),'BTrue')
    echo on
end