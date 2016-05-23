function prms = tnt_gaussian(params,N,step_mult)

A = params(1);
j_c = params(2);
w = params(3);


prms = A*exp(-((1:N)-1-j_c).^2/(2*w^2));

end