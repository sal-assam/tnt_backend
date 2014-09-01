from django.conf.urls import patterns, include, url

from django.conf import settings

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

#if settings.DEBUG:
    ## static files (images, css, javascript, etc.)
    #urlpatterns += patterns('',
        #(r'^media/(?P<path>.*)$', 'django.views.static.serve', {
        #'document_root': settings.MEDIA_ROOT}))



# static files (images, css, javascript, etc.)
urlpatterns += patterns('',
    (r'^media/(?P<path>.*)$', 'django.views.static.serve', {
    'document_root': settings.MEDIA_ROOT}))
