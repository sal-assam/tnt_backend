
function prms = tnt_delta(params,N,step_mult)

A = params(1);
j_c = round(params(2)/step_mult);

prms = zeros(1,N);

c = min(j_c+1,N);
c = max(c,1);

prms(c) = A;

end