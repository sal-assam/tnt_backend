#!/bin/bash
 
NAME="tnt_backend_app"                                  # Name of the application
DJANGODIR=/home/tntweb/tnt_backend             # Django project directory
SOCKFILE=/home/tntweb/tnt_backend/run/gunicorn.sock  # we will communicte using this unix socket
#USER=hello                                        # the user to run as
#GROUP=webapps                                     # the group to run as
NUM_WORKERS=3                                     # how many worker processes should Gunicorn spawn
DJANGO_SETTINGS_MODULE=tnt_backend.settings             # which settings file should Django use
DJANGO_WSGI_MODULE=tnt_backend.wsgi                     # WSGI module name
 
echo "Starting $NAME as `whoami`"
 
# Activate the virtual environment
#cd $DJANGODIR
#source ../bin/activate
export DJANGO_SETTINGS_MODULE=$DJANGO_SETTINGS_MODULE
echo DJANGO_SETTINGS_MODULE
echo $DJANGO_SETTINGS_MODULE

export PYTHONPATH=$DJANGODIR:$PYTHONPATH
echo PYTHONPATH
echo $PYTHONPATH

# Create the run directory if it doesn't exist
RUNDIR=$(dirname $SOCKFILE)
test -d $RUNDIR || mkdir -p $RUNDIR
 
# Start your Django Unicorn
# Programs meant to be run under supervisor should not daemonize themselves (do not use --daemon)
exec /home/tntweb/.virtualenvs/tnt/bin/gunicorn ${DJANGO_WSGI_MODULE}:application \
  --name $NAME \
  --workers $NUM_WORKERS \
  --bind=unix:$SOCKFILE \
  --log-level=debug \
  --log-file=-
