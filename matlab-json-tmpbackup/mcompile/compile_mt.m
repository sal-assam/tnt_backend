% Wrapper function for MATLAB C-compiling an m-file.
% The input mfile is the name of the mfile.

function compile(mfile)

tmp = getenv('DISPLAY');
setenv('DISPLAY'); % Reset the display variable for mcc.

% Trim off the '.m' if it is included.
if mfile(end-1:end) == '.m'
  mfile = mfile(1:end-2);
end;

disp(['Compiling w/ multithreading support: ' mfile '...']);

% Run the Matlab C Compiler (mcc).
eval(['mcc -v -N -R -nojvm -I /share/apps/MATLAB/MPS_library -m ' mfile]); % Use eval() since mcc must be ran from the command line.
% (SJD) Options:: -v: verbose, -R nojvm: don't include java, -N: use on clear out path, -m: standalone
% (SJD) multithreading support is enabled by default, the compile.m script now passes an option to turn it off.
% When using multithreading, the job ought to be submitted such that it gets a whole node to itself.


disp('Tidying up output files ...');
% Delete unnecessary files resulting from the compilation
[status currdir] = system('rm readme.txt');
[status currdir] = system('rm mccExcludedFiles.log');
[status currdir] = system(['rm run_' mfile '.sh']);
[status currdir] = system(['rm ' mfile '_mcc_component_data.c']);
[status currdir] = system(['rm ' mfile '_main.c']);
[status currdir] = system(['rm ' mfile '.prj']);

disp('Creating shell scripts ...');
% Create shell script for running the resulting executable.
% Define lines of the script:
line{1} = '#!/bin/bash';
line{2} = '# Execution wrapper script';
line{3} = '# Combine stdout and sterr into one output file:';
line{4} = '#$ -j y';
line{5} = '# Use "bash" shell:';
line{6} = '#$ -S /bin/bash';
line{7} = '# Change the output directory for stdout:';
line{8} = '#$ -o sge_output';
line{9} = '# Name the job:';
line{10} = ['#$ -N ' mfile];
line{11} = '# Use current directory as working root:';
line{12} = '#$ -cwd';
line{13} = '# Set default memory request (2.25G*8 = 18G):';
line{14} = '#$ -l h_vmem=2.25G';
line{15} = '# Send mail: n=none, b=begin, e=end, a=abort, s=suspend';
line{16} = '#$ -m n ';
line{17} = '#$ -M your_address@physics.ox.ac.uk';
line{18} = '# Since multi-threaded, by default use -pe threads';
line{19} = '#$ -pe threads 8';
line{20} = ' ';
line{21} = ['/share/apps/MATLAB/run_mcc2012b.sh ' pwd '/' mfile ' $*'];

filename = [mfile '.sh'];
fid = fopen(filename,'w');
for loop=1:length(line)
  fprintf(fid,'%s\n',line{loop});
end;
fclose(fid);

[status currdir] = system(['chmod 764 ' filename]); % Make the script executable.

clear fid line;

% Create shell script for loading the executing script on to the cluster.
% Define lines of the script:
line{1} = '#!/bin/bash';
line{2} = '# Cluster loading wrapper script';
line{3} = ' ';
line{4} = 'echo Loading job';
line{5} = ['qsub ' filename ' $*']; 
line{6} = ['qstat -ne -u ' getenv('USER')];

filename = ['load.sh'];
fid = fopen(filename,'w');
for loop=1:length(line)
  fprintf(fid,'%s\n',line{loop});
end;
fclose(fid);

[status currdir] = system(['chmod 764 load.sh']); % Make the script executable.
[status currdir] = system('mkdir -p sge_output'); % Create an sge_ouput directory if needed.

setenv('DISPLAY',tmp);
disp('Compilation finished.');

