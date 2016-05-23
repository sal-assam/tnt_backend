#!/bin/bash

# Submit the job
# test qsub -N tntweb_${1} -j n -S /bin/bash -cwd -e errors/${1}.err -o logs/${1}.log -m n jobtnt.sh $*

LOGFNAME=/home/tntweb/tnt_backend/shellscripts/logs/${1}.log

echo $'waiting in calculation queue...' >> ${LOGFNAME}

qsub -N tntweb_${1} queuedtnt.sh ${1} ${LOGFNAME}

