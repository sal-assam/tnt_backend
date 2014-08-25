from django.conf.urls import patterns, include, url

from django.contrib import admin
admin.autodiscover()

urlpatterns = patterns('',
    # Examples:
    # url(r'^$', 'tnt_backend.views.home', name='home'),
    # url(r'^blog/', include('blog.urls')),

    ### Internal TNT backend API ###
    url(r'^api/v1.0/',
        include('tnt_backend.apps.api.urls',
        namespace='api')),

    url(r'^admin/', include(admin.site.urls)),
)
