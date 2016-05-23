
function prms = tnt_rect(params,N)

A = params(1);
j_c = params(2);
w = params(3);

prms = zeros(1,N);

prms(max(floor(j_c-w/2+1),1):min(ceil(j_c+w/2+1),N)) = A;

end