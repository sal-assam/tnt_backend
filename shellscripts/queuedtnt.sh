#!/bin/bash
# Wrapper shell script for running the TNT backend code
# Execution wrapper script
# Combine stdout and sterr into one output file:
#$ -j y
# Use "bash" shell:
#$ -S /bin/bash
# Change the output directory for stdout:
#$ -o sge_output
# Use current directory as working root:
#$ -cwd
# Send mail: n=none, b=begin, e=end, a=abort, s=suspend
#$ -m n 

/home/tntweb/tnt_backend/shellscripts/jobtnt.sh ${1} ${2} 1> /home/tntweb/tnt_backend/shellscripts/logs/${1}_out.log 2> /home/tntweb/tnt_backend/shellscripts/errors/${1}.err

