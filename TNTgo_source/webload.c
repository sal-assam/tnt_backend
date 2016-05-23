/*
 * Authors: Sarah Al-Assam, Stephen Clark and Dieter Jaksch
 * (c) University of Oxford 2014-2015
 * 
 * webmpsmodify.c
 * 
 * Function definitions for back-end of TNTgo Application.
 * 
 */
#include "tntweb.h"

/* Writes messagew to custom log file */
void twbLog(char *logmsg)
{
    extern char logname[TNT_STRLEN]; /* global variable for log file name */
    FILE *logfile; /* Pointer to the logile */
    
    /* open then close log file to flush buffer, allow code to be read from head node */
    logfile = fopen(logname,"a");
    fprintf(logfile,"%s...\n",logmsg);
    fclose(logfile);
    
}

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

/* Loads all the elements required for the expectation values structure. */
void twbLoadExOp(char *loadname, /* name of file to load strings from */
                 tntMpsExOp *ExOp) /* pointer to uninitialised array of strings */
{
    
    unsigned ex_numos, ex_numnn, ex_numcs, ex_numap; /* Number of expectation values to calculate of each type */

  
    /* Load parameters specifying number of expectation value operators */
    tntLoadParams(loadname, 4, 0, 0, &ex_numos, "ex_numos", 0, &ex_numnn, "ex_numnn", 0, &ex_numcs, "ex_numcs", 0, &ex_numap, "ex_numap", 0);
    
    /* Load operators for calculating expectation values */
    twbLoadNodeArray(loadname, ex_numos, &(ExOp->ExOpOs), "ex_opos", "oplabels");
    twbLoadNodeArray(loadname, ex_numnn*2, &(ExOp->ExOp2nn), "ex_opnn", "oplabels");
    twbLoadNodeArray(loadname, ex_numcs*2, &(ExOp->ExOp2cs), "ex_opcs", "oplabels");
    twbLoadNodeArray(loadname, ex_numap*2, &(ExOp->ExOp2ap), "ex_opap", "oplabels");
    
    /* Load labels for operators */
    twbLoadStringArray(loadname, ex_numos, &(ExOp->LbOpOs), "ex_oposlabel");
    twbLoadStringArray(loadname, ex_numnn, &(ExOp->LbOp2nn), "ex_opnnlabel");
    twbLoadStringArray(loadname, ex_numcs, &(ExOp->LbOp2cs), "ex_opcslabel");
    twbLoadStringArray(loadname, ex_numap, &(ExOp->LbOp2ap), "ex_opaplabel");
    
    return;
}

/* Loads an array of nodes, where the variables will be called var_prefix_<i>, where i goes from 1 to the number of elements */
void twbLoadMpo(char *loadname, /* name of file to load strings from */
                unsigned L, /* Length of MPO to create */
                tntNetwork *mpo, /* pointer to uninitialised array of strings */
                const char *var_prefix, /* prefix for variable name in the variable */
                const char *var_suffix) /* prefix for variable name in the variable */
{
    unsigned numos, numnn; /* Number of onsite and nearest neighbour operators */
    tntComplexArray nnparams, osparams; /* parameters for creating the Hamiltonian */
    tntComplexArray *nnparam=&nnparams, *osparam=&osparams;  /* pointers to the above structures */
    tntNodeArray nnLs, nnRs, oss;  /* left and right nearest neighbour operators and onsite operators for creating the Hamiltonian */
    tntNodeArray *nnL=&nnLs, *nnR=&nnRs, *os=&oss;  /* pointers to the above structures */
    char varname[TNT_STRLEN]; /* Used to hold variable name currently being loaded */
    
    /* Load the number of operators that make up the system Hamiltonian */
    sprintf(varname,"%s%s%s", var_prefix, "numos", var_suffix);
    tntLoadParams(loadname, 1, 0, 0, &numos, varname, 0);
    sprintf(varname,"%s%s%s", var_prefix, "numnn", var_suffix);
    tntLoadParams(loadname, 1, 0, 0, &numnn, varname, 0);
    
    /* Load operators and parameters needed for defining the system Hamiltonian if they exist */
    if (numos) {
        sprintf(varname,"%s%s%s", var_prefix, "opos", var_suffix);
        twbLoadNodeArray(loadname, numos, os, varname, "oplabels");
        sprintf(varname,"%s%s%s", var_prefix, "prmos", var_suffix);
        tntLoadArrays(loadname, 0, 0, 1, osparam, varname);
    } else {
        os = NULL; 
        osparam = NULL;
    }
    if (numnn) {
        sprintf(varname,"%s%s%s", var_prefix, "opnnL", var_suffix);
        twbLoadNodeArray(loadname, numnn, nnL, varname, "oplabels");
        sprintf(varname,"%s%s%s", var_prefix, "opnnR", var_suffix);
        twbLoadNodeArray(loadname, numnn, nnR, varname, "oplabels");
        sprintf(varname,"%s%s%s", var_prefix, "prmnn", var_suffix);
        tntLoadArrays(loadname, 0, 0, 1, nnparam, varname);
    } else {
        nnL = nnR = NULL;
        nnparam = NULL;
    }
    
    /* Create the MPO */
    *mpo = tntMpsCreateMpo(L, nnL, nnR, nnparam, os, osparam);
    
    /* Free the arrays used */
    if (numos) {
        tntNodeArrayFree(os);
        tntComplexArrayFree(osparam);
    } else {
        os = &oss;
        osparam=&osparams;
    }
    if (numnn) {
        tntNodeArrayFree(nnL);
        tntNodeArrayFree(nnR);
        tntComplexArrayFree(nnparam);
    } else {
        nnL = &nnLs;
        nnR = &nnRs;
        nnparam = &nnparams;
    }
    
    return;
}
