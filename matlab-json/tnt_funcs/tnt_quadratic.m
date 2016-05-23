function prms = tnt_quadratic(params,N,step_mult)

a = params(1);
b = params(2);
j_c = params(3);

prms = a+b*step_mult*step_mult*((1:N)-j_c-1).^2;

end