/*
Authors: Sarah Al-Assam, Stephen Clark and Dieter Jaksch
Date:    $LastChangedDate$
(c) University of Oxford 2014
*/

/*  webload.c

    This contains functions to help loading arrays of nodes and string.
*

/* Include the header for the TNT library, including MPS functions */
#include "tntMps.h"

/* Loads an array of nodes, where the variables will be called var_prefix_<i>, where i goes from 1 to the number of elements */
void twbLoadNodeArray(char *loadname, /* name of file to load nodes from */
                      unsigned numelems, /* number of nodes in the array */
                      tntNodeArray *arr, /* pointer to uninitialised array of nodes */
                      const char *var_prefix, /* prefix for variable name in the file */
                      const char *nodeid) /* leg labels for the nodes */
{
    
    unsigned ul; /* used for looping over unsigned variables */
    char varname[TNT_STRLEN]; /* Used to hold variable name currently being loaded */
    
    /* Initialise array */
    *arr = tntNodeArrayAlloc(numelems);
    /* Load each node into the array */
    for (ul = 0; ul < numelems; ul++) {
        printf("Loading variable %d of %d.\n",ul+1,numelems);
        /* variable names for operators */
        sprintf(varname,"%s_%d", var_prefix, ul+1);
        tntLoadNodes(loadname, 1, arr->vals + ul, varname, nodeid);
    }
    
    return;
}

/* Loads an array of nodes, where the variables will be called var_prefix_<i>, where i goes from 1 to the number of elements */
void twbLoadStringArray(char *loadname, /* name of file to load strings from */
                        unsigned numelems, /* number of strings in the array */
                        tntStringArray *arr, /* pointer to uninitialised array of strings */
                        const char *var_prefix) /* prefix for variable name in the file */
{
    
    unsigned ul; /* used for looping over unsigned variables */
    char varname[TNT_STRLEN]; /* Used to hold variable name currently being loaded */
    char strvar[TNT_STRLEN]; /* Loaded variable */
    
    /* Initialise array */
    *arr = tntStringArrayAlloc(numelems);
    
    /* Load each node into the array */
    for (ul = 0; ul < numelems; ul++) {
        /* variable names for operators */
        sprintf(varname,"%s_%d", var_prefix, ul+1);
        tntLoadStrings(loadname, 1, strvar, varname);
        strcpy(arr->vals[ul],strvar);
    }
    
    return;
}