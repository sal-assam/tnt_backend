% Creates all the spatial variation functions required for generating an initialisation
% script.

function fhandles = create_func_file()

% Number of functions currently defined
numfunc = 5;

% strings representing function names. The functions themselves are stored
% in the tnt_funcs directory.
fhandles = cell(1, numfunc);

fhandles{1} = @tnt_constant;
fhandles{2} = @tnt_linear;
fhandles{3} = @tnt_quadratic;
fhandles{4} = @tnt_sin;
fhandles{5} = @tnt_step;

end