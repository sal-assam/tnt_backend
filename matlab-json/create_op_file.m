% Creates all the operators required for generating an initialisation
% script.

% First create the cell that will contain the operators.
% First dimension gives the id of the operator
% Second dimension gives 2S if it is a spin operator, or nmax if it is a
% boson operator

% Maximum physical dimension = 2S+1 or nmax+1
dmax = 6; 

% Number of operators currently defined
numop = 16;

operators = cell(numop,dmax-1);

% First create the spin operators for 2S = 1:(dmax-1).

for twoS = 1:(dmax-1)
    [sx,sy,sz,sp,sm] = spin_operators(twoS);
    
    % single site operators:
    % First initialise cells - size of cell array is number of terms in sum for this operator 
    for loop = 1:5
        operators{loop,twoS} = cell(1,1);
    end
    operators{1,twoS}{1} = sx;
    operators{2,twoS}{1} = sy;
    operators{3,twoS}{1} = sz;
    operators{4,twoS}{1} = sp;
    operators{5,twoS}{1} = sm;
    
    % two site operators:
    % First initialise cells - rows is number of sites, cols is number of
    % terms
    for loop = 6:16
        operators{loop,twoS} = cell(2,1);
    end
    operators{9,twoS} = cell(2,2);
    operators{10,twoS} = cell(2,2);
    
    % Now populate elements
    operators{6,twoS}{1} = sx; operators{6,twoS}{2} = sx; 
    operators{7,twoS}{1} = sy; operators{7,twoS}{2} = sy; 
    operators{8,twoS}{1} = sz; operators{8,twoS}{2} = sz;
    
    operators{9,twoS}{1,1} = sp; operators{9,twoS}{2,1} = sm; 
    operators{9,twoS}{1,2} = sm; operators{9,twoS}{2,2} = sp; 
    operators{10,twoS}{1,1} = 1i*sp; operators{10,twoS}{2,1} = 1i*sm; 
    operators{10,twoS}{1,2} = -1i*sm; operators{10,twoS}{2,2} = -1i*sp; 

    operators{11,twoS}{1} = sx; operators{11,twoS}{2} = sy; 
    operators{12,twoS}{1} = sy; operators{12,twoS}{2} = sx; 
    operators{13,twoS}{1} = sy; operators{13,twoS}{2} = sz; 
    operators{14,twoS}{1} = sz; operators{14,twoS}{2} = sy; 
    operators{15,twoS}{1} = sz; operators{15,twoS}{2} = sx; 
    operators{16,twoS}{1} = sx; operators{16,twoS}{2} = sz; 
end

save('operators.mat','operators');