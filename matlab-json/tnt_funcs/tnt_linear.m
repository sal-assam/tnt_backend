function prms = tnt_linear(params,N,step_mult)

a = params(1);
b = params(2);

prms = a + b*step_mult*((1:N)-1);

end