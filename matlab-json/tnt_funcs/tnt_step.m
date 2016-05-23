
function prms = tnt_step(params,N)

A = params(1);
j_s = params(2);

prms = zeros(1,N);

c = max(j_s+1,1);

prms(ceil(j_s):N) = A;

end