function p = pathdef
%PATHDEF Search path defaults.
%   PATHDEF returns a string that can be used as input to MATLABPATH
%   in order to set the path.

  
%   Copyright 1984-2007 The MathWorks, Inc.
%   $Revision: 1.4.2.2 $ $Date: 2007/06/07 14:45:14 $


% DO NOT MODIFY THIS FILE.  IT IS AN AUTOGENERATED FILE.  
% EDITING MAY CAUSE THE FILE TO BECOME UNREADABLE TO 
% THE PATHTOOL AND THE INSTALLER.

p = [...
%%% BEGIN ENTRIES %%%
        '<PLEASE FILL IN ONE DIRECTORY PER LINE>:',...
%%% END ENTRIES %%%
     ...
];

p = [userpath,p];
