
function prms = tnt_sin(params,N)

A_0 = params(1);
A = params(2);
k = params(3);
phi = params(4);

prms = A_0 + A*sin(k*(1:N) + phi);

end
