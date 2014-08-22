% Creates all the spatial variation functions required for generating an initialisation
% script.

% Number of functions currently defined
numfunc = 14;

% strings representing function names. The functions themselves are stored
% in the tnt_funcs directory.
funcs = cell(numfunc,1);

funcs{1} = 'tnt_constant';
funcs{2} = 'tnt_linear';
funcs{3} = 'tnt_quadratic';
funcs{4} = 'tnt_sin';
funcs{5} = 'tnt_step';

save('spat_funcs.mat','funcs');
