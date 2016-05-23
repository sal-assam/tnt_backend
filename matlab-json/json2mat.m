function json2mat(jsonpath,matpath,calculation_id)
%INIT_JSON2MAT Turns the json file with the id given into a matlab
%initialisation file for loading into the tnt software.

if (~isdeployed)
    addpath([pwd,'/jsonlab']);
    addpath([pwd,'/tnt_funcs']);
end

% Load the file containing all the operators and spatial functions
load('operators.mat','operators');

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

% Initialise flags
U1symm_ground = 0;
U1symm_dyn = 0;
modifybasestate = 0;
calc_ol_gs = 0;
calc_ol_is = 0;
calc_energy = 0;
usegsfortebd = 0;

if (strcmp(sys.system_type.name,'bosonic'))
    
    nmax = sys.system_type.extra_info.bosonic_truncation;
    qnums = 0:nmax;

    basisOp = operators{1,nmax}{1};
    d = nmax;
elseif (strcmp(sys.system_type.name,'spin'))

    TwoS = sys.system_type.extra_info.spin_magnitude;
    qnums = TwoS:-2:-TwoS;

    basisOp = operators{3,TwoS}{1};
    d = TwoS;
end

% Leg labels for the operators (all operators will have the same leg labels
oplabels = [3,4];
if (dodmrg)
    U1symm_ground = sys.number_conservation.ground.apply_qn;
    U1symm_num = sys.number_conservation.ground.qn;
    
    precision = 10^(-1*sys.log_ground_state_precision);
    
    % Load the Hamiltonian terms for time evolution
    terms = pms.calculation.setup.hamiltonian.ground.terms;

    %initialise number of each type of term to zero
    h_numnn_g = 0; h_numos_g = 0;
    for loop=1:length(terms)
        
        opid = terms{loop}.operator_id;
        
        num_func_params = size(terms{loop}.spatial_function.parameters,2);
        spat_args = zeros(num_func_params,1);
        % load spatial functions for operator
        for k=1:num_func_params
            spat_args(k) = str2double(terms{loop}.spatial_function.parameters{k}.value);
        end
        
        if (terms{loop}.two_site)
            % Call function to get parameters
            spat_params = fhandles{terms{loop}.spatial_function.id}(spat_args,L-1,1);
            for tms = 1:size(operators{opid,d},2)
                % update number of operators
                h_numnn_g = h_numnn_g + 1;
                
                % load operators
                eval(['h_opnnL_g_',num2str(h_numnn_g),'= operators{opid,d}{1,tms};']);
                eval(['h_opnnR_g_',num2str(h_numnn_g),'= operators{opid,d}{2,tms};']);
                
                % assign spatial values to position array
                h_prmnn_g(h_numnn_g,1:L-1) = spat_params; %#ok<SAGROW>
            end
        else
            % L terms needed for onsite operators
            spat_params = fhandles{terms{loop}.spatial_function.id}(spat_args,L,1);
            
            for tms = 1:size(operators{opid,d})
                h_numos_g = h_numos_g + 1;
                eval(['h_opos_g_',num2str(h_numos_g),'= operators{opid,d}{tms};']);
                
                % assign spatial values to position array
                h_prmos_g(h_numos_g,1:L) = spat_params; %#ok<SAGROW,*AGROW>
            end
        end
    end
end

% Variables only needed if performing a tebd calculation
if (dotebd)

    % set initial configuration
    basestate = pms.calculation.setup.initial_state.base_state.initial_base_state_id;
    if (0 == basestate)
        usegsfortebd = 1;
        dodmrg = 1;
    else
        init_config = create_base_states(basestate,L);
    end
    
    % Set simulation parameters
    numsteps = sys.time.num_time_steps;
    dt = sys.time.time_step;
    bigstep = sys.time.num_expval_time_steps;
    U1symm_dyn = 0;%sys.number_conservation.dynamic.apply_qn;
    
    % Load the Hamiltonian terms for time evolution
    terms = pms.calculation.setup.hamiltonian.dynamic.terms;

    %initialise number of each type of term to zero
    h_numnn_d = 0; h_numos_d = 0;
    for loop=1:length(terms)
        
        opid = terms{loop}.operator_id;
        
        % load temporal function for operator
        if (isfield(terms{loop},'temporal_function')&&(terms{loop}.temporal_function.id ~= 0))
            num_func_params = size(terms{loop}.temporal_function.parameters,2);
            temp_args = zeros(num_func_params,1)
            for k=1:num_func_params
                temp_args(k) = str2double(terms{loop}.temporal_function.parameters{k}.value)
            end
            temp_params = fhandles{terms{loop}.temporal_function.id}(temp_args,numsteps,dt)
        else
            temp_params = ones(1,numsteps);
        end
        
        num_func_params = size(terms{loop}.spatial_function.parameters,2);
        spat_args = zeros(num_func_params,1);
        % load spatial functions for operator
        for k=1:num_func_params
            spat_args(k) = str2double(terms{loop}.spatial_function.parameters{k}.value);
        end
        
        if (terms{loop}.two_site)
            % Call function to get parameters
            spat_params = fhandles{terms{loop}.spatial_function.id}(spat_args,L-1,1);
            for tms = 1:size(operators{opid,d},2)
                % update number of operators
                h_numnn_d = h_numnn_d + 1;
                
                % load operators
                eval(['h_opnnL_d_',num2str(h_numnn_d),'= operators{opid,d}{1,tms};']);
                eval(['h_opnnR_d_',num2str(h_numnn_d),'= operators{opid,d}{2,tms};']);
                
                % assign spatial values to position array
                h_prmnn_d(h_numnn_d,1:L-1) = spat_params; %#ok<SAGROW>
                h_prmnn_t(h_numnn_d,1:numsteps) = temp_params; %#ok<SAGROW>
            end
        else
            % L terms needed for onsite operators
            spat_params = fhandles{terms{loop}.spatial_function.id}(spat_args,L,1);
            
            for tms = 1:size(operators{opid,d})
                h_numos_d = h_numos_d + 1;
                eval(['h_opos_d_',num2str(h_numos_d),'= operators{opid,d}{tms};']);
                
                % assign spatial values to position array
                h_prmos_d(h_numos_d,1:L) = spat_params; %#ok<SAGROW,*AGROW>
                h_prmos_t(h_numos_d,1:numsteps) = temp_params; %#ok<SAGROW,*AGROW>
            end
        end
    end
    
    % Determine whether an overlap calculation is required
    
    if (dodmrg)
        calc_ol_gs = pms.calculation.setup.expectation_values.calculate_overlap_with_ground;
    end
    calc_ol_is = pms.calculation.setup.expectation_values.calculate_overlap_with_initial;
    calc_energy = pms.calculation.setup.expectation_values.calculate_dynamic_energy;
    
end
    
      
% Set operators to apply to initial base state
modifiers = pms.calculation.setup.initial_state.applied_mpos;
mod_renorm = pms.calculation.setup.initial_state.renormalise;

%initialise number of each type of term to zero
if (~isempty(modifiers))
    modifybasestate = 1;
    mod_num_mpo = length(modifiers);
    for modloop = 1:mod_num_mpo
        
        if (strcmp(modifiers{modloop}.type,'product'))
            modifypmpo(modloop) = 1;
            count = 1; % counter of number of operators to apply
        else
            modifypmpo(modloop) = 0;
            mod_num(modloop) = length(modifiers{modloop}.applied_operators);
        end
        
        currmod = modifiers{modloop}.applied_operators;
        
        
        for loop=1:length(modifiers{modloop}.applied_operators)

            num_func_params = size(currmod{loop}.spatial_function.parameters,2);
            spat_args = zeros(num_func_params,1);
            % load spatial functions for operator
            for k=1:num_func_params
                spat_args(k) = str2double(currmod{loop}.spatial_function.parameters{k}.value);
            end


            % L terms needed for onsite operators
            spat_params = fhandles{currmod{loop}.spatial_function.id}(spat_args,L,1);
            
            % The current operator
            opid = currmod{loop}.operator_id;

            % Now different behaviour depending on whether this is a PMPO or an MPO. 

            % For a PMPO, round function to integer values, and use to determine how many times each operator will be applied to the base state
            % Use this to generate arrays of sitenumbers for each operator
            if (modifypmpo(modloop))
                
                if ((opid == 17) || (opid == 18) || (opid == 32)) % special case for phase terms - non-integer values allowed
                    % Loop through parameters
                    for j = 1:L
                        % Take the power of the operator
                        eval(['mod_op_',num2str(modloop),'_',num2str(j),'= operators{opid,d}{1}^spat_params(j);']);
                    end
                    % phase term on every site
                    eval(['mod_sitenum_',num2str(modloop),' = 0:(L-1);']);
                    mod_num(modloop) = L;
                else
                    % Make parameters a positive integer
                    spat_params = abs(round(spat_params));
                    
                    % Loop through parameters
                    for j = 1:L
                        % Loop through number of times this operator is being applied
                        for k=1:spat_params(j)
                            % Add an entry for each time the operator is being applied
                            eval(['mod_op_',num2str(modloop),'_',num2str(count),'= operators{opid,d}{1};']);
                            
                            % assign spatial values to position array (offset by 1 for C array numbering)
                            eval(['mod_sitenum_',num2str(modloop),'(count) = j-1;']);
                            
                            count = count+1;
                        end
                    end
                    mod_num(modloop) = count-1;
                end
            else
                % For an MPO, just take the operators with list of parameters for each site
                eval(['mod_op_',num2str(modloop),'_',num2str(loop),'= operators{opid,d}{1};']);

                % assign spatial values to position array
                eval(['mod_prm_',num2str(modloop),'(loop,1:L) = spat_params;']);
            end
        end
    end
end

% Load the expectation value terms
exops = pms.calculation.setup.expectation_values.operators;

%initialise number of each type of term to zero
ex_numnn = 0; ex_numcs = 0; ex_numap = 0; ex_numos = 0;
for loop=1:length(exops)
    opid = exops{loop}.operator_id;
    

	newlb = strrep(exops{loop}.function_description,' ','_');
	newlb = strrep(newlb,'-','_');
	
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
clear pms sys terms loop opid tms spat_args spat_prms num_func_params exops d funcs k operators spat_params spatcall TwoS fhandles newlb

% save the initialisation file using the calculation id
savename = [matpath '/' calculation_id '.mat'];
save(savename);

end
% Parameter variables to load in C:
%   dotebd (0 or 1) Y
%   dodmrg (0 or 1) Y
%   usegsfortebd (0 or 1) - if set dodmrg is always set Y
%   modifybasestate (0 or 1) Y
%   chi (integer) Y
%   L (integer) Y
%   ex_numos (integer) Y
%   ex_numnn (integer) Y
%   ex_numcs (integer) Y
%   ex_numap (integer) Y

% Arrays to load in C:
% oplabels (integer array) Y

% Nodes to load in C
% basisOp (always only one) Y
% ex_opos_<i> (node array of size ex_numos) Y
% ex_opnn_<i> (node array of size 2*ex_numnn) Y
% ex_opcs_<i> (node array of size 2*ex_numcs) Y
% ex_opap_<i> (node array of size 2*ex_numap) Y

% Strings to load in C
% calculation_id Y
% ex_oposlabel_<i> (string array of size ex_numos) Y
% ex_opnnlabel_<i> (string array of size ex_numnn) Y
% ex_opcslabel_<i> (string array of size ex_numcs) Y 
% ex_opaplabel_<i> (string array of size ex_numap) Y

% To load only if there is quantum number conservation enforced.
% qnums Y

% to load only if dodmrg=1
% U1symm_ground (integer) Y
% U1symm_num (integer) Y
% h_numos_g (integer) Y
% h_numnn_g (integer) Y
% precision (double)
% h_opos_g_<i> (node array of size h_numos_g) Y
% h_opnnL_g_<i> (node array of size h_numnn_g) Y
% h_opnnR_g_<i> (node array of size h_numnn_g) Y
% h_prmnn_g (double array) Y
% h_prmos_g (double array) Y

% To load only if modifybasestate=1
% modifypmpo (0 or 1)
% mod_num (integer)
% mod_op_<i> (node array of size mod_num)
% mod_prm (double array - only if modifypmo==0)
% mod_sitenum (integer array - only if modifypmo==1)

% to load only if dotebd=1
% U1symm_dyn (integer) Y
% numsteps (integer) Y
% bigstep (integer) Y
% dt (double) Y
% init_config (string) - only if usegsfortebd=0 Y
% h_numos_d (integer) Y
% h_numnn_d (integer) Y
% h_opos_d_<i> (node array of size h_numos_d) D
% h_opnnL_d_<i> (node array of size h_numnn_d) Y
% h_opnnR_d_<i> (node array of size h_numnn_d) Y
% h_prmnn_d (double array) Y
% h_prmos_d (double array) Y

% to load only if both dotebd=1 and dodmrg=1
% calc_ol (0 or 1)





