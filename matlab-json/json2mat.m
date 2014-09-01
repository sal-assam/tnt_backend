function json2mat(jsonpath,matpath,calculation_id)
%INIT_JSON2MAT Turns the json file with the id given into a matlab
%initialisation file for loading into the tnt software.

if (~isdeployed)
    addpath([pwd,'/jsonlab']);
    addpath([pwd,'/tnt_funcs']);
end

% Load the file containing all the operators and spatial functions
load('operators.mat','operators');
%load('spat_funcs.mat','funcs')

% Create function handles
fhandles = create_func_file();

% Load the correct json file
loadname = [jsonpath '/' calculation_id '.json'];
pms = loadjson(loadname);

% Load system parameters
sys = pms.calculation.setup.system;

dotebd = sys.calculate_time_evolution;
dodmrg = sys.calculate_ground_state;
chi = sys.chi;
L = sys.system_size;
U1symm = sys.number_conservation;

if (dotebd)
    numsteps = sys.num_time_steps;
    dt = sys.time_step;
end

if (strcmp(sys.system_type.name,'spin'))
    if (strcmp(sys.system_type.extra_info.spin_magnitude,'half'))
        TwoS = 1;
        qnums = [1,-1];
    else
        TwoS = 2;
        qnums = [2, 0, -2];
    end
    basisOp = operators{3,TwoS}{1};
    d = TwoS;
end

% Leg labels for the operators (all operators will have the same leg labels
oplabels = [3,4];

% Load the Hamiltonian terms
terms = pms.calculation.setup.hamiltonian.terms;

%initialise number of each type of term to zero
h_numnn = 0; h_numos = 0;
for loop=1:length(terms)
    opid = terms{loop}.operator_id;
    
    num_func_params = size(terms{loop}.spatial_function.parameters,2);
    spat_args = zeros(num_func_params);
    % load spatial functions for operator
    for k=1:num_func_params
        spat_args(k) = str2double(terms{loop}.spatial_function.parameters{k}.value);
    end
    
    if (terms{loop}.two_site)
        % Call function to get parameters
        spat_params = fhandles{terms{loop}.spatial_function.spatial_fn_id}(spat_args,L-1);
        for tms = 1:size(operators{opid,d},2)
            % update number of operators
            h_numnn = h_numnn + 1;
            
            % load operators
            eval(['h_opnnL_',num2str(h_numnn),'= operators{opid,d}{1,tms};']);
            eval(['h_opnnR_',num2str(h_numnn),'= operators{opid,d}{2,tms};']);
            
            % assign spatial values to position array
            h_prmnn(h_numnn,1:L-1) = spat_params; %#ok<SAGROW>
        end
    else
        % L terms needed for onsite operators
        spat_args = [spat_args,',L'];
        spatcall = [funcs{terms{loop}.spatial_function.spatial_fn_id},'( ', spat_args(2:end), ');'];
        % Call function to get parameters
        spat_params = eval(spatcall);
        
        for tms = 1:size(operators{opid,d})
            h_numos = h_numos + 1;
            eval(['h_opos_',num2str(h_numos),'= operators{opid,d}{tms};']);
            
            % assign spatial values to position array
            h_prmos(h_numos,1:L) = spat_params; %#ok<SAGROW,*AGROW>
        end
        
        
    end
end

% turn matrices of parameters to vectors
if (h_numnn), h_prmnn = h_prmnn(:); end
if (h_numos), h_prmos = h_prmos(:); end

% set initial configuration
init_config = create_base_states(pms.calculation.setup.initial_state.base_state.initial_base_state_id,L);

% TODO: Set operators to apply to initial base state

% Load the expectation value terms
exops = pms.calculation.setup.expectation_values.operators;

%initialise number of each type of term to zero
ex_numnn = 0; ex_numcs = 0; ex_numap = 0; ex_numos = 0;
for loop=1:length(exops)
    opid = exops{loop}.operator_id;
    newlb = strrep(exops{loop}.function_description,' ','_');
    
    if (exops{loop}.two_site)
        if (strcmp(exops{loop}.exp_val_type,'nearest neighbor'))
            for tms = 1:size(operators{opid,d},2)
                % update number of operators
                ex_numnn = ex_numnn + 1;
                
                % load operators
                eval(['ex_opnn_',num2str(2*ex_numnn-1),'= operators{opid,d}{1,tms};']);
                eval(['ex_opnn_',num2str(2*ex_numnn),'= operators{opid,d}{2,tms};']);
                eval(['ex_opnnlabel_',num2str(ex_numnn),'= newlb;']);
            end
        elseif (strcmp(exops{loop}.exp_val_type,'center all other'))
            for tms = 1:size(operators{opid,d},2)
                % update number of operators
                ex_numcs = ex_numcs + 1;
                
                % load operators
                eval(['ex_opcs_',num2str(2*ex_numcs-1),'= operators{opid,d}{1,tms};']);
                eval(['ex_opcs_',num2str(2*ex_numcs),'= operators{opid,d}{2,tms};']);
                eval(['ex_opcslabel_',num2str(ex_numcs),'= newlb;']);
            end
        else
            for tms = 1:size(operators{opid,d},2)
                % update number of operators
                ex_numap = ex_numap + 1;
                
                % load operators
                eval(['ex_opap_',num2str(2*ex_numap-1),'= operators{opid,d}{1,tms};']);
                eval(['ex_opap_',num2str(2*ex_numap),'= operators{opid,d}{2,tms};']);
                eval(['ex_opaplabel_',num2str(ex_numap),'= newlb;']);
            end
        end
        
    else
        for tms = 1:size(operators{opid,d})
            ex_numos = ex_numos + 1;
            eval(['ex_opos_',num2str(ex_numos),'= operators{opid,d}{tms};']);
            eval(['ex_oposlabel_',num2str(ex_numos),'= newlb;']);
        end
        
        
    end
end

% clear json structures and unimportant variables
clear pms sys terms loop opid tms spat_args spat_prms num_func_params exops d funcs k operators spat_params spatcall TwoS

% save the initialisation file using the calculation id
savename = [matpath '/' calculation_id '.mat'];
save(savename);

end
% Parameter variables to load in C:
%   dotebd (0 or 1)
%   dodmrg (0 or 1)
%   chi (iinteger)
%   L (integer)
%   h_numos (integer)
%   h_numnn (integer)
%   ex_numos (integer)
%   ex_numnn (integer)
%   ex_numcs (integer)
%   ex_numap (integer)

% Arrays to load in C:
% h_prmnn (double array)
% h_prmos (double array)
% oplabels (integer array)

% to load only if dotebd=1
%  numsteps (integer)
%  dt (double)

% Nodes to load in C
% basisOp (always only one)
% h_opos_<i> (node array of size h_numos)
% h_opnnL_<i> (node array of size h_numnn)
% h_opnnR_<i> (node array of size h_numnn)
% ex_opos_<i> (node array of size ex_numos)
% ex_opnn_<i> (node array of size 2*ex_numnn)
% ex_opcs_<i> (node array of size 2*ex_numcs)
% ex_opap_<i> (node array of size 2*ex_numap)

% Strings to load in C
% init_config
% calculation_id
% ex_oposlabel_<i> (string array of size ex_numos)
% ex_opnnlabel_<i> (string array of size ex_numnn)
% ex_opcslabel_<i> (string array of size ex_numcs)
% ex_opaplabel_<i> (string array of size ex_numap)

