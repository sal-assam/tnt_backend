import json

from subprocess import call, Popen

from shutil import copyfile

import os

import glob

from tnt_backend.settings import \
    BASE_DIR, \
    MEDIA_ROOT, \
    json_input_save_dir, \
    mat_input_save_dir, \
    json_output_save_dir, \
    mat_output_save_dir, \
    error_log_dir

from django.shortcuts import render

# Django rest framework imports
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from rest_framework.reverse import reverse

# Create your views here.
@api_view(('GET',))
def api_root(request, format=None):
	# The API 'root' providing info on available data sources

    return Response({

        ### START OF API CALLS FOR MANIPULATING AND QUERYING CALCULATIONS DEFINITIONS ###

        # 'progress_of_calculation': \
        # reverse('api:progress_of_calculation', \
        # request=request, \
        # format=format),

        ### END OF API CALLS FOR MANIPULATING AND QUERYING CALCULATIONS DEFINITIONS ###

    })

### START OF API CALLS FOR MANIPULATING AND QUERYING CALCULATIONS DEFINITIONS ###
@api_view(['GET'])
def progress_of_calculation(request, calculation_id):
    """
    Return info on the progress of a given calculation
    """

    print("Fetching status of calculation " + str(calculation_id))

    response = Response({'progress': 'unfinished'}, status=status.HTTP_200_OK)    # R1gt

    return response

@api_view(['GET'])
def results_of_calculation(request, calculation_id):
    """
    Return the JSON results for this calculation, if we can find them
    """

    print("Fetching results of calculation " + str(calculation_id))

    results_exist = False

    # The file path at which the results json file will exist
    calculation_results_json_path = BASE_DIR + json_output_save_dir + calculation_id + '.json'

    # The file path at which an error log file exists, if any
    calculation_error_path = BASE_DIR + error_log_dir + calculation_id + '.err'

    # Let's check if the calculation resulted in an error (this is indicated by a non-empty error file)
    if os.path.exists(calculation_error_path):

        if os.stat(calculation_error_path).st_size > 0:

            response = Response('Internal Error', status=status.HTTP_500_INTERNAL_SERVER_ERROR)

            return response

    # Check if the results file exists
    if os.path.exists(calculation_results_json_path):

        results_exist = True

    if not results_exist:

    	response = Response('Not found', status=status.HTTP_404_NOT_FOUND)    # R1gt

    else:

        results_json = open(calculation_results_json_path, 'r').read()
        results = json.loads(results_json)

        # Now we also want to return the names of the images for the expectation value calculations
        this_calculation_absolute_filenames = glob.glob(MEDIA_ROOT + calculation_id + '*')

        this_calculation_relative_filenames = ['http://bose.physics.ox.ac.uk:8080/media/' + filename.split('/')[-1] for filename in this_calculation_absolute_filenames]


        # We also want to return the MAT location of the MAT files for download...
        # First we need to copy the results MAT file to the MEDIA directory
        calculation_mat_results_file_path = BASE_DIR + mat_output_save_dir + calculation_id + '.mat'

        calculation_mat_results_media_root_filename = MEDIA_ROOT + calculation_id + '.mat'

        copyfile(calculation_mat_results_file_path, calculation_mat_results_media_root_filename)

        # Now we want to construct the URL at which these results can be found
        this_calculation_mat_results_URL = 'http://bose.physics.ox.ac.uk:8080/media/' + calculation_id + '.mat'

        response = Response({ \
            'results': results, \
            'expectation_value_plots': this_calculation_relative_filenames, \
            'mat_results_URL': this_calculation_mat_results_URL \
        }, status=status.HTTP_200_OK)    # R1gt

    return response

@api_view(['POST'])
def run_calculation(request):
    """
    Create MATLAB init file and run the TNT library on calculation which is POSTed to this URL ###
    First we need to take the JSON and dump it to a file named according to the calculation id
    then we want to call sarah's script which takes that name / ID as input and generates a MATLAB init file, and then calls the TNT library on that file
    """

    calculation_json = request.DATA.get('calculation')

    if calculation_json is not None:
        calculation = json.loads(calculation_json)

    calculation_id = calculation['meta_info']['id']

    print("calculation_id = ")
    print(calculation_id)

    print("Saving calculation JSON structure...")

    json_save_filename = BASE_DIR + json_input_save_dir + calculation_id + '.json'

    print("json_save_filename: ")
    print(json_save_filename)

    open(json_save_filename, 'w').write(json.dumps({'calculation': calculation}))

    print("Saved JSON structure to file...")

    # Now call Sarah's script:

    run_script_str = "./runtnt.sh " + calculation_id

    saved_path = os.getcwd()

    # Change into the appropriate directory
    try:
        os.chdir('shellscripts/')
        Popen(run_script_str.split(' '))
    except:
        os.chdir(saved_path)

    os.chdir(saved_path)

    response = Response('OK', status=status.HTTP_200_OK)    # R1gt

    return response

### END OF API CALLS FOR MANIPULATING AND QUERYING CALCULATIONS DEFINITIONS ###
