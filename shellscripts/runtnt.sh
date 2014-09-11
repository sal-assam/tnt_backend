#!/bin/bash

qsub queuedtnt.sh $*



# #!/bin/bash
# # Wrapper shell script for running the TNT backend code
# 
# DIR_TNT=/share/apps/tnt/v0.9.9beta
# 
# 
# DIR_JSON_IP=/home/tntweb/tnt_backend/matlab-json/json_input
# DIR_JSON_OP=/home/tntweb/tnt_backend/matlab-json/json_output
# DIR_MAT_IP=/home/tntweb/tnt_backend/matlab-json/matlab_input
# DIR_MAT_OP=/home/tntweb/tnt_backend/matlab-json/matlab_output
# DIR_IMG_OP=/home/tntweb/tnt_backend/pngoutput
# 
# # Set the environment variables required for the simulation
# . /share/apps/tnt/scripts/set_tnt_vars.sh
# 
# mkdir --parents $DIR_MAT_IP
# 
# # Run matlab to generate initialisation files
# echo "--------------------------------"
# echo "Generating MATLAB initialisation file"
# echo "--------------------------------"
# cd ../matlab-json/
# ./json2mat.sh ${DIR_JSON_IP} ${DIR_MAT_IP} ${1}
# cd ../shellscripts/
# 
# CMDLINE="-i ${DIR_MAT_IP}/${1}.mat -d ${DIR_MAT_OP}/${1}"
# 
# mkdir --parents $DIR_MAT_OP
# 
# echo "--------------------------------"
# echo "Running TNT code from initialisation file"
# echo "--------------------------------"
# STARTTIME=$(date +%s)
# ${DIR_TNT}/bin/tnt_web $CMDLINE
# ENDTIME=$(date +%s)
# echo "It took $(($ENDTIME - $STARTTIME)) seconds to complete this task"
# 
# mkdir --parents $DIR_JSON_OP
# mkdir --parents $DIR_IMG_OP
# 
# # Run matlab to generate output json file
# echo "--------------------------------"
# echo "Generating JSON output file and images"
# echo "--------------------------------"
# 
# cd ../matlab-json/
# ./mat2json.sh ${DIR_MAT_OP} ${DIR_JSON_IP} ${DIR_JSON_OP} ${DIR_IMG_OP} ${1}
# cd ../shellscripts
# 
