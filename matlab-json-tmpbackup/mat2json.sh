#!/bin/bash
# Execution wrapper script
# Combine stdout and sterr into one output file:
#$ -j y
# Use "bash" shell:
#$ -S /bin/bash
# Change the output directory for stdout:
#$ -o sge_output
# Name the job:
#$ -N mat2json
# Use current directory as working root:
#$ -cwd
# Set default memory request:
#$ -l h_vmem=1.5G
# Send mail: n=none, b=begin, e=end, a=abort, s=suspend
#$ -m n 
#$ -M your_address@physics.ox.ac.uk
 
/home/tntweb/tnt_backend/matlab-json/run_mcc2012b.sh /home/tntweb/tnt_backend/matlab-json/mat2json $*
