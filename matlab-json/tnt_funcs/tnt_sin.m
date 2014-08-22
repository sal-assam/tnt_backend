
function prms = tnt_sin(A_0,A,k,phi,N)

prms = A_0 + A*sin(k*(1:N) + phi);

end
