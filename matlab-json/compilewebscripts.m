% Call this script to add files needed for compiling matlab scripts needed
% for runtnt.sh

addpath('/home/alassam/tnt_backend/matlab-json/mcompile:'); 
addpath('/home/alassam/tnt_backend/matlab-json/mcompile/classpath/:');
addpath('/home/alassam/tnt_backend/matlab-json/mcompile/template/:');
addpath('/home/alassam/tnt_backend/matlab-json/mcompile/path/:'); 

tntwebcompile json2mat  
tntwebcompile mat2json 