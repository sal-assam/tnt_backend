function [sx,sy,sz,sp,sm] = spin_operators(TwoS)

% physical dimension
d = TwoS + 1;

% spin
S = TwoS/2;

% z component of spin
m = S:-1:-S;

% Build matrix version of basic spin operators :
sz = diag(m);
sp = diag(sqrt((S-m(2:end)).*(S+m(2:end)+1)),1);
sm = diag(sqrt((S+m(1:(end-1))).*(S-m(1:(end-1))+1)),-1);

sx = 0.5*(sp+sm);
sy = -0.5*1i*(sp-sm);



