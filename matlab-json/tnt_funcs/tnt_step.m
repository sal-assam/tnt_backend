

function prms = tnt_step(A,j_s,N)

prms = zeros(1:N);

prms(ceil(j_s):N) = A;

end