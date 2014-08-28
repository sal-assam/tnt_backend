function mat2json(matoutpath,jsoninpath,jsonoutpath,calculation_id)

addpath([pwd,'/jsonlab']);

% Load initial json structure
loadname = [jsoninpath '/' calculation_id '.json'];
pms = loadjson(loadname);
% Load the expectation value terms
exops = pms.calculation.setup.expectation_values.operators;
% Load which calculations have been carried out
dotebd = pms.calculation.setup.system.calculate_time_evolution;
dodmrg = pms.calculation.setup.system.calculate_ground_state;

% Load results of calculations
loadname = [matoutpath '/' calculation_id '.mat'];
load(loadname);


if (dodmrg)
    % Load energy per iteration
    data.groundstate.energy.iterations = length(E);
    data.groundstate.energy.vals = E;
    
    for loop=1:length(exops)
        
        data.groundstate.operators{loop}.operator_id = exops{loop}.operator_id;
        newlb = strrep(exops{loop}.function_description,' ','_');
        
        data.groundstate.operators{loop}.two_site = exops{loop}.two_site;
        eval(['data.groundstate.operators{loop}.vals.re = real(' newlb ');']);
        eval(['data.groundstate.operators{loop}.vals.im = imag(' newlb ');']);
        if (exops{loop}.two_site)
            data.groundstate.operators{loop}.exp_val_type = exops{loop}.exp_val_type;
        end
        data.groundstate.operators{loop}.function_description = exops{loop}.function_description;
        
    end
end

if (dotebd)
 
    for loop=1:length(exops)
        
        data.evolved.operators{loop}.operator_id = exops{loop}.operator_id;
        data.evolved.operators{loop}.two_site = exops{loop}.two_site;
        if (exops{loop}.two_site)
            data.evolved.operators{loop}.exp_val_type = exops{loop}.exp_val_type;
        end
        data.evolved.operators{loop}.function_description = exops{loop}.function_description;
        newlb = strrep(exops{loop}.function_description,' ','_');
        
        for loopt=1:length(extimes) 
            strloop = num2str(loopt);
            tval.time_step = loopt;
            tval.time = extimes(loopt);
            eval(['tval.re = real(' newlb '_' strloop ');']);
            eval(['tval.im = imag(' newlb '_' strloop ');']);

            data.evolved.operators{loop}.vals{loopt} = tval;
        end
        
        
    end
end

savename = [jsonoutpath '/' calculation_id '.json'];
savejson('data',data,savename);

end