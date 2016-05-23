function prms = tnt_linear(params,N)

a = params(1);
b = params(2);

prms = a + b*((1:N)-1);

end