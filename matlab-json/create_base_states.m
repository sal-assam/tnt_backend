function configstr = create_base_states(state_id,L)
%CREATE_BASE_STATES % Creates all the start states required for generating an initialisation
% script.

configstr='';

if (state_id == 1)
    for loop=1:L
        configstr=[configstr,'1'];
    end
end

if (state_id == 2)
    for loop=1:L
        configstr=[configstr,'0'];
    end
end

if (state_id == 3)
    for loop=1:floor(L/2)
        configstr=[configstr,'0'];
    end
    for loop=(floor(L/2)+1):L
        configstr=[configstr,'1']; %#ok<*AGROW>
    end
end

if (state_id == 4)
    for loop=1:L
        configstr=[configstr,'1'];
    end
    for loop=1:2:L
        configstr(loop)='0';
    end
end

if (state_id == 5)
    for loop=1:L
        configstr=[configstr,'1'];
    end
end

if (state_id == 6)
    for loop=1:L
        configstr=[configstr,'0'];
    end
end

end

