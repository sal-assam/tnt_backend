function prms = tnt_quadratic(a,b,j_c,N)

prms = a+b*((1:N)-j_c).^2;

end