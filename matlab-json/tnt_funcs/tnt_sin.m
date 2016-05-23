
function prms = tnt_sin(params,N,step_mult)

A_0 = params(1);
A = params(2);
k = params(3)*step_mult;
phi = params(4);

prms = A_0 + A*sin(k*((1:N) - 1) + phi);

end
