% Wrapper function for MATLAB C-compiling an m-file.
% The input mfile is the name of the mfile.

function compile(mfile)

tmp = getenv('DISPLAY');
setenv('DISPLAY'); % Reset the display variable for mcc.

% Trim off the '.m' if it is included.
if mfile(end-1:end) == '.m'
  mfile = mfile(1:end-2);
end;

disp(['Compiling: ' mfile '...']);
disp(['(Use compile_mt to compile with multithreading support)']);

% Run the Matlab C Compiler (mcc).
eval(['mcc -v -N -R -nodisplay -I /home/tntweb/tnt_backend/matlab-json/jsonlab -I /home/tntweb/tnt_backend/matlab-json/tnt_funcs -R -singleCompThread -m ' mfile]); % Use eval() since mcc must be ran from the command line.
% (SJD) Options:: -v: verbose, -R nojvm: don't include java, -N: use on clear out path, -m: standalone
% (SJD) enabled -singleCompThread so that the underlying math libraries don't use as many threads as there are cores on the machine.  For multithreading, use compile-mt.m

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
line{13} = '# Set default memory request:';
line{14} = '#$ -l h_vmem=1.5G';
line{15} = '# Send mail: n=none, b=begin, e=end, a=abort, s=suspend';
line{16} = '#$ -m n ';
line{17} = '#$ -M your_address@physics.ox.ac.uk';
line{18} = ' ';
line{19} = [pwd '/run_mcc2012b.sh ' pwd '/' mfile ' $*'];

filename = [mfile '.sh'];
fid = fopen(filename,'w');
for loop=1:length(line)
  fprintf(fid,'%s\n',line{loop});
end;
fclose(fid);

[status currdir] = system(['chmod 764 ' filename]); % Make the script executable.

clear fid line;

setenv('DISPLAY',tmp);
disp('Compilation finished.');

