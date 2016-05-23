
function prms = tnt_delta(params,N)

A = params(1);
j_c = params(2);

prms = zeros(1,N);

c = min(j_c+1,N);
c = max(c,1);

prms(c) = A;

end