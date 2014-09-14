function [bdag,b,n] = boson_operators(nmax)

% Build matrix version of basic spin operators :
bdag = diag(sqrt(1:nmax)',-1);
b = diag(sqrt(1:nmax)',1);
n = diag((0:nmax)',0);
