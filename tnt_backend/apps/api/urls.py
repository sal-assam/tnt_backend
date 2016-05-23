from django.conf.urls import patterns, url
import views

urlpatterns = patterns('',

    ### Root of the REST API ###
    url(r'^[/]?$', \
        views.api_root, \
        name='api_root'),

    ### START OF API CALLS FOR MANIPULATING AND QUERYING CALCULATIONS DEFINITIONS ###

    ### JSON results structure for a given calculation ###
    url(r'^calculation/results/(?P<calculation_id>[^/]+)[/]?$', \
        views.results_of_calculation, \
        name='results_of_calculation'),

    ### Delete all the results and setup files for a particular calculation if it exists ###
    url(r'^calculation/delete/(?P<calculation_id>[^/]+)[/]?$', \
        views.delete_calculation, \
        name='delete_calculation'),

    ### POST a calculation JSON structure to this URL to run it ###
    url(r'^calculation/run[/]?$', \
        views.run_calculation, \
        name='run_calculation'),

)

