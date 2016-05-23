function prms = tnt_quadratic(params,N)

a = params(1);
b = params(2);
j_c = params(3);


prms = a+b*((1:N)-j_c-1).^2;

end