#!/bin/bash

#JOBNUM=`qstat -j "tntweb_${1}" | grep -w "job_number" | cut -c28-34 `

#JOBQUEUE=`qstat | grep -w "${JOBNUM}" | cut -c 73-90`

#ssh --noprofile  $JOBQUEUE "tail /home/tntweb/tnt_backend/shellscripts/logs/${1}.log"

tail -n 1 /home/tntweb/tnt_backend/shellscripts/logs/${1}.log