#!/bin/bash

DIR_TNT=/share/apps/tnt/dev-release

DIR_JSON_IP=/home/tntweb/tnt_backend/matlab-json/json_input
DIR_JSON_OP=/home/tntweb/tnt_backend/matlab-json/json_output
DIR_MAT_IP=/home/tntweb/tnt_backend/matlab-json/matlab_input
DIR_MAT_OP=/home/tntweb/tnt_backend/matlab-json/matlab_output
DIR_IMG_OP=/home/tntweb/tnt_backend/pngoutput

# Set the environment variables required for the simulation
. /share/apps/tnt/scripts/set_tnt_vars.sh

LOGFNAME=${2}

# Run matlab to generate initialisation files
echo $'generating initialisation file...' >> $LOGFNAME
cd /home/tntweb/tnt_backend/matlab-json/
./json2mat.sh ${DIR_JSON_IP} ${DIR_MAT_IP} ${1}
cd /home/tntweb/tnt_backend/shellscripts/

CMDLINE="-i ${DIR_MAT_IP}/${1}.mat -d ${DIR_MAT_OP}/${1} -o $LOGFNAME"

echo $'starting TNT library code...' >> $LOGFNAME
STARTTIME=$(date +%s)
${DIR_TNT}/bin/tnt_web_new $CMDLINE
ENDTIME=$(date +%s)
echo "It took $(($ENDTIME - $STARTTIME)) seconds to complete this task"

# Run matlab to generate output json file
echo $'generating JSON output file and images..' >> $LOGFNAME

cd /home/tntweb/tnt_backend/matlab-json/
./mat2json.sh ${DIR_MAT_OP} ${DIR_JSON_IP} ${DIR_JSON_OP} ${DIR_IMG_OP} ${1}
cd /home/tntweb/tnt_backend/shellscripts/

echo $'calculation complete' >> $LOGFNAME