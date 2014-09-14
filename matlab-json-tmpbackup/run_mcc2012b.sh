#!/bin/sh
# Script for execution of deployed MATLAB applications
#
# Sets up the MCR environment for the current $ARCH and executes 
# the specified command.

# Explicitly define the location of the MATLAB C-libraries:
MCRROOT=/share/apps/MATLAB/R2012b

MWE_ARCH="glnxa64"

LD_LIBRARY_PATH=.:${MCRROOT}/runtime/glnxa64
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/bin/glnxa64
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/os/glnxa64
MCRJRE=${MCRROOT}/sys/java/jre/glnxa64/jre/lib/amd64
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/native_threads
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/server
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/client
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}
XAPPLRESDIR=${MCRROOT}/X11/app-defaults

export LD_LIBRARY_PATH;
export XAPPLRESDIR;

# Run application specified by input arguments:
$*

