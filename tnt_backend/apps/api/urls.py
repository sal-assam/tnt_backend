from django.conf.urls import patterns, url
import views

urlpatterns = patterns('',

    ### Root of the REST API ###
    url(r'^[/]?$', \
        views.api_root, \
        name='api_root'),

    ### START OF API CALLS FOR MANIPULATING AND QUERYING CALCULATIONS DEFINITIONS ###

    ### Info on progress of a given calculation ###
    url(r'^calculation/progress/(?P<calculation_id>[^/]+)[/]?$', \
        views.progress_of_calculation, \
        name='progress_of_calculation'),

    ### JSON results structure for a given calculation ###
    url(r'^calculation/results/(?P<calculation_id>[^/]+)[/]?$', \
        views.results_of_calculation, \
        name='results_of_calculation'),

    ### POST a calculation JSON structure to this URL to run it ###
    url(r'^calculation/run[/]?$', \
        views.run_calculation, \
        name='run_calculation'),

)

