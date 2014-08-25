import json

from subprocess import call

import os

from tnt_backend.settings import \
    BASE_DIR, \
    json_save_dir

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

    # Check if the results file exists
    results_exist = False

    if not results_exist:
    	
    	response = Response('Not found', status=status.HTTP_404_NOT_FOUND)    # R1gt

    else:

    	response = Response({'results': 'some_results'}, status=status.HTTP_200_OK)    # R1gt

    return response

@api_view(['POST'])
def run_calculation(request):
    """
    Create MATLAB init file and run the TNT library on calculation which is POSTed to this URL ###
    """
    print("A")

    print request.DATA

    request.DATA.get('calculation')

    calculation_json = request.DATA.get('calculation')

    print("B")

    print calculation_json

    if calculation_json is not None:
        calculation = json.loads(calculation_json)

    print calculation

    calculation_id = calculation['meta_info']['id']

    print("calculation_id = ")
    print(calculation_id)

    print("Saving calculation JSON structure...")

    json_save_filename = BASE_DIR + json_save_dir + calculation_id + '.json'

    print("json_save_filename: ")
    print(json_save_filename)

    open(json_save_filename, 'w').write(json.dumps({'calculation': calculation}))

    # matlab_run_str = "/Applications/MATLAB_R2012b.app/bin/matlab -r json2mat('" + calculation_id + "');exit -nodesktop"   # 
    matlab_run_str = "matlab -r json2mat('" + calculation_id + "');exit -nodesktop" # 

    print matlab_run_str

    saved_path = os.getcwd()

    try:
        os.chdir('matlab-json/')
        call(matlab_run_str.split(' '))
    except:
        os.chdir(saved_path)
        response = Response('Something went wrong converting JSON to mat file', status=status.HTTP_500_INTERNAL_SERVER_ERROR)    # R1gt
    
    os.chdir(saved_path)

    response = Response('OK', status=status.HTTP_200_OK)    # R1gt

    return response

### END OF API CALLS FOR MANIPULATING AND QUERYING CALCULATIONS DEFINITIONS ###