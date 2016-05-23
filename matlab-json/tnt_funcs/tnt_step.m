
function prms = tnt_step(params,N,step_mult)

A = params(1);
j_s = round(params(2)/step_mult);

prms = zeros(1,N);

c = max(j_s+1,1);

prms(ceil(j_s):N) = A;

end