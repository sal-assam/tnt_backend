function startpage

%   Copyright 2007 The MathWorks, Inc. 
%   $Revision: 1.1.6.2 $  $Date: 2011/01/28 18:50:33 $

if usejava('desktop')
    dt = com.mathworks.mde.desk.MLDesktop.getInstance();
    frame = dt.getMainFrame();
    sp = com.mathworks.mde.webintegration.startpage.StartPageFactory.getStartPage();
    if sp.isEnabled()
        sp.showStartPage(frame);
    else
        disp(getString(message('MATLAB:startpage:StartPageFeatureNotEnabled')))
    end
else
        disp(getString(message('MATLAB:startpage:StartPageFeatureNotAvailable')))
end