function mat2json(matoutpath,jsoninpath,jsonoutpath,imageoutputpath,calculation_id)

if (~isdeployed)
    addpath([pwd,'/jsonlab']);
end

% Load initial json structure
loadname = [jsoninpath '/' calculation_id '.json'];
pms = loadjson(loadname);
% Load the expectation value terms
exops = pms.calculation.setup.expectation_values.operators;
% Load which calculations have been carried out
dotebd = pms.calculation.setup.system.calculate_time_evolution;
dodmrg = pms.calculation.setup.system.calculate_ground_state;

% Load system size
L = pms.calculation.setup.system.system_size;

% Load results of calculations
loadname = [matoutpath '/' calculation_id '.mat'];
load(loadname);

if (strcmp(pms.calculation.setup.system.system_type.name,'bosonic'))
    load('cmap_bosons.mat');
else
    load('cmap_spins.mat');
end

% Formats for graph plotting
line_style = '-';
line_width = 0.5;
line_color = [90.2, 46.3, 0]/100;
marker = 'o';
marker_size = 4;
marker_edge_color = [90.2, 46.3, 0]/100;
marker_face_color = [0.4,0.4,0.4];
axesfontsize = 14;

NameArray = {'LineStyle','LineWidth','Color','Marker','MarkerSize','MarkerEdgeColor','MarkerFaceColor'};
ValueArray = {line_style,line_width,line_color,marker,marker_size,marker_edge_color,marker_face_color};

if (dodmrg)
    % Load energy per iteration
    data.groundstate.energy.iterations = length(E)-1;
    data.groundstate.energy.vals = E;
    prec = pms.calculation.setup.system.log_ground_state_precision
    
    fmtstr = ['%',num2str(max([floor(log10(abs(E(end)))) 1])+prec),'.',num2str(prec-1),'f']
    
    fname = [imageoutputpath '/' calculation_id '_energy_gs.png'];
    currtit = ['Convergence to energy density ',num2str(E(end)/L,fmtstr)];
    disp(['Saving image "', currtit, '"']);
    figure('Visible','off');
    h = semilogy(E-E(end));
    set(h,NameArray,ValueArray);
    set(gca,'XTick',1:length(E));
    set(gca,'XTickLabel',0:(length(E)-1));
    set(gca,'FontSize',axesfontsize);
    xlabel('Iteration');
    ylabel('E - E_{gs}');
    title(currtit);
    set(gcf, 'visible','off'); 
    saveas(gcf,fname);
    close gcf; clear gcf;
    
    for loop=1:length(exops)
        if (exops{loop}.operator_id > 0)
            data.groundstate.operators{loop}.operator_id = exops{loop}.operator_id;
            newlb = strrep(exops{loop}.function_description,' ','_');
            newlb = strrep(newlb,'-','_');
            
            if (exist(newlb,'var'))
                eval(['datasetall = ' newlb ';']);
                
                data.groundstate.operators{loop}.two_site = exops{loop}.two_site;
                data.groundstate.operators{loop}.vals.re = real(datasetall);
                data.groundstate.operators{loop}.vals.im = imag(datasetall);
                if (exops{loop}.two_site)
                    data.groundstate.operators{loop}.exp_val_type = exops{loop}.exp_val_type;
                end
                data.groundstate.operators{loop}.function_description = exops{loop}.function_description;
                errstr='';
            else
                datasetall = zeros(1,L);
                errstr='\newline !!Early exit due to error in calculation!!';
            end
            
            fname = [imageoutputpath '/' calculation_id '_' num2str(exops{loop}.operator_id) '_gs.png'];
            if (exops{loop}.complex)
                currtit = ['Ground state expectation of real(' exops{loop}.function_description, ')'];
            else
                currtit = ['Ground state expectation of ' exops{loop}.function_description];
            end
            disp(['Saving image "', currtit, '"']);
            figure('Visible','off');
            if ((exops{loop}.two_site) && strcmp(exops{loop}.exp_val_type,'all other pairs'))
                h = image(0:(L-1),0:(L-1),real(datasetall),'CDataMapping','scaled');
                ylabel('Site number');
                axis square;
                axis xy;
                colormap(tntcmap);
                colorbar;
                caxis auto;
            else
                currtit = [currtit, ', sum = ', num2str(sum(datasetall))];
                h = plot(0:(length(datasetall)-1),real(datasetall));
                ylabel(exops{loop}.function_description);
                set(h,NameArray,ValueArray);
            end
            set(gca,'FontSize',axesfontsize);
            xlabel('Site number');
            title(currtit);
            set(gcf, 'visible','off');
            saveas(gcf,fname);
            close gcf; clear gcf;
        end
    end
end

if (dotebd)

	fname = [imageoutputpath '/' calculation_id '_0_evolved.png'];
	currtit = {'Truncation error (sum of squares of all discarded singular values) per time step.',['Sum over all time-steps = ',num2str(sum(truncerrs))]};
	extimesall = (1:length(truncerrs))*pms.calculation.setup.system.time.time_step;
	disp(['Saving image "Truncation Error"']);
	figure('Visible','off');
	semilogy(extimesall,truncerrs,'-k');
	set(gca,'FontSize',axesfontsize);
	xlabel('Time');
	ylabel('Truncation error per time step');
	title(currtit);
	set(gcf, 'visible','off'); 
	saveas(gcf,fname);
	close gcf; clear gcf;

    for loop=1:length(exops)

		twositestr='';
		
		data.evolved.operators{loop}.operator_id = exops{loop}.operator_id;
		data.evolved.operators{loop}.two_site = exops{loop}.two_site;
		if (exops{loop}.two_site)
			data.evolved.operators{loop}.exp_val_type = exops{loop}.exp_val_type;
			if (strcmp(exops{loop}.exp_val_type,'all other pairs'))
				twositestr=' for all pairs of sites';
			elseif (strcmp(exops{loop}.exp_val_type,'center all other'))
				twositestr=' for central site to all other sites';
			else
				twositestr=' for nearest neighbour pairs';
			end
		end
		data.evolved.operators{loop}.function_description = exops{loop}.function_description;
		newlb = strrep(exops{loop}.function_description,' ','_');
		newlb = strrep(newlb,'-','_');
		
		eval(['numcols = size(' newlb '_1,1)*size(' newlb '_1,2);']);
		datasetall = zeros(length(extimes),numcols);
		
		for loopt=1:length(extimes)
			strloop = num2str(loopt);
			tval.time_step = loopt;
			tval.time = extimes(loopt);
			eval(['datasetstep = ' newlb '_' strloop ';']);
			tval.re = real(datasetstep);
			tval.im = imag(datasetstep);
			
			data.evolved.operators{loop}.vals{loopt} = tval;
			datasetall(loopt,:) = datasetstep(:);
		end
		
		fname = [imageoutputpath '/' calculation_id '_' num2str(exops{loop}.operator_id) '_evolved.png'];
        if (exops{loop}.complex)
            currtit = ['Expectation of real(', exops{loop}.function_description ,')', twositestr,' as a function of time'];
        else
            currtit = ['Expectation of ', exops{loop}.function_description , twositestr,' as a function of time'];
        end
		disp(['Saving image "', currtit, '"']);
		figure('Visible','off');
        h = image(0:(numcols-1),extimes,real(datasetall),'CDataMapping','scaled');
		set(gca,'FontSize',axesfontsize);
		xlabel('Site number');
		ylabel('Time');
		title(currtit);
		axis square;
		colormap(tntcmap);
        caxis auto;
        axis xy;
		colorbar;
		set(gcf, 'visible','off');
		saveas(gcf,fname);
		close gcf; clear gcf;

    end
    
    loop = length(length(exops));
    
    % Now see if there are overlap values to plot
    if (exist('overlaps_gs','var'))
        fname = [imageoutputpath '/' calculation_id '_overlap_gs.png'];
        currtit = 'Overlap between ground state and evolved state';
        disp(['Saving image "', currtit, '"']);
        figure('Visible','off');
        h = plot(extimes,overlaps_gs);
        set(h,NameArray,ValueArray);
        set(gca,'FontSize',axesfontsize);
        xlabel('Time');
        ylabel('|\langle\psi_g|\psi_e\rangle|');
        title(currtit);
        set(gcf, 'visible','off'); 
        saveas(gcf,fname);
        close gcf; clear gcf;
        
        loop = loop+1;
        data.evolved.operators{loop}.function_description = 'overlap_gs';
        data.evolved.operators{loop}.operator_id = -1;
        data.evolved.operators{loop}.two_site = 0;
        for loopt=1:length(extimes) 
            strloop = num2str(loopt);
            tval.time_step = loopt;
            tval.time = extimes(loopt);
            tval.re = overlaps_gs(loopt);
            tval.im = 0;
            data.evolved.operators{loop}.vals{loopt} = tval;
        end
        
    end
    
    if (exist('overlaps_is','var'))
        fname = [imageoutputpath '/' calculation_id '_overlap_is.png'];
        currtit = 'Overlap between start state and evolved state';
        disp(['Saving image "', currtit, '"']);
        figure('Visible','off');
        h = plot(extimes,overlaps_is);
        set(h,NameArray,ValueArray);
        set(gca,'FontSize',axesfontsize);
        xlabel('Time');
        ylabel('|\langle\psi_s|\psi_e\rangle|');
        title(currtit);
        saveas(gcf,fname);
        close gcf; clear gcf;
        
        loop = loop+1;
        data.evolved.operators{loop}.function_description = 'overlap_is';
        data.evolved.operators{loop}.operator_id = -2;
        data.evolved.operators{loop}.two_site = 0;
        for loopt=1:length(extimes) 
            strloop = num2str(loopt);
            tval.time_step = loopt;
            tval.time = extimes(loopt);
            tval.re = overlaps_is(loopt);
            tval.im = 0;
            data.evolved.operators{loop}.vals{loopt} = tval;
        end
    end
    
    % Now see if there is energy to plot
    if (exist('energies','var'))
        fname = [imageoutputpath '/' calculation_id '_energies.png'];
        currtit = 'Energy of evolved state';
        disp(['Saving image "', currtit, '"']);
        figure('Visible','off');
        h = plot(extimes,energies);
        set(h,NameArray,ValueArray);
        set(gca,'FontSize',axesfontsize);
        xlabel('Time');
        ylabel('Energy');
        title(currtit);
        set(gcf, 'visible','off'); 
        saveas(gcf,fname);
        close gcf; clear gcf;
        
        loop = loop+1;
        data.evolved.operators{loop}.function_description = 'energy';
        data.evolved.operators{loop}.operator_id = -3;
        data.evolved.operators{loop}.two_site = 0;
        for loopt=1:length(extimes) 
            strloop = num2str(loopt);
            tval.time_step = loopt;
            tval.time = extimes(loopt);
            tval.re = energies(loopt);
            tval.im = 0;
            data.evolved.operators{loop}.vals{loopt} = tval;
        end
        
    end
end

savename = [jsonoutpath '/' calculation_id '.json'];
savejson('data',data,savename);

end
