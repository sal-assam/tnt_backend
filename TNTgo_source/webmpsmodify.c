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


/* \ingroup mps
 *
 * 
 * Documentation for modify routine goes here
 * 
 * 
 */
double twbMpsModify(char *loadname, /* Name to load all the modifying operators from */
                    tntNetwork wf_start, /* Network representing the wave function to modify */
                    int chi) /* maximum internal dimension of MPS */
{

    unsigned mod_renorm; /* Flag to state whether the modified state should be renormalised */
    unsigned mod_num_mpo; /* The number of MPOs that will be applied in sequence */
    unsigned mod_num; /* Number of operators for this MPO (all onsite) */
    unsigned modifypmpo; /* Flag to state whether the current MPO is a prodyct or sum MPO */
    tntComplexArray mod_params; /* parameters for creating the sum modifier */
    tntComplexArray *mod_param=&mod_params;  /* pointers to the above structure */
    char mod_params_label[TNT_STRLEN]; /* Label for the variable to load - will have the MPO number as a suffix */
    tntIntArray mod_sitenums; /* sitenumbers for creating the product modifier */
    tntIntArray *mod_sitenum=&mod_sitenums;  /* pointers to the above structure */
    char mod_sitenums_label[TNT_STRLEN]; /* Label for the variable to load - will have the MPO number as a suffix */
    tntNodeArray mod_ops;  /* left and right nearest neighbour operators and onsite operators for creating the modifier */
    tntNodeArray *mod_op=&mod_ops;  /* pointers to the above structures */
    char mod_op_label[TNT_STRLEN]; /* Label for the variable to load - will have the MPO number as a suffix */
    double err = 0.0; /* truncation error to return */
    unsigned i; /* used for looping */
    tntNetwork mpo; /* the MPO to use to modify the state */
    unsigned L = tntMpsLength(wf_start);
    
    
    /* Load parameters specifying number of system-wide operators, and wether to renormalise after applying them */
    tntLoadParams(loadname, 2, 0, 0, &mod_num_mpo, "mod_num_mpo", 0, &mod_renorm, "mod_renorm", 0);
    
    /* Apply each modifier to the starting state, in each case append suffix to each variable name before loading  */
    for (i = 1; i <= mod_num_mpo; i++) {
        
        /* Load number of single site oeprators in this MPO, and whether it is a product or sum MPO */
        tntLoadParams(loadname, 2, 0, 0, &modifypmpo, "modifypmpo", i-1, &mod_num, "mod_num", i-1);
        
        /* Load operators for defining the MPO to apply to the base state */
        sprintf(mod_op_label,"%s_%d", "mod_op", i);
        twbLoadNodeArray(loadname, mod_num, mod_op, mod_op_label, "oplabels");
        
        /* Create the MPO */
        if (modifypmpo) {
            sprintf(mod_sitenums_label,"%s_%d", "mod_sitenum", i);
            tntLoadArrays(loadname, 1, 0, 0, mod_sitenum, mod_sitenums_label);
            mpo = twbMpsCreatePmpo(L, mod_op, mod_sitenum);
            tntIntArrayFree(mod_sitenum);
        } else {
            sprintf(mod_params_label,"%s_%d", "mod_prm", i);
            tntLoadArrays(loadname, 0, 0, 1, mod_param, mod_params_label);
            mpo = tntMpsCreateMpo(L, NULL,  NULL, NULL, mod_op, mod_param);
            printf("finished creating MPO of length %d\n", L);
            tntComplexArrayFree(mod_param);
        }
        
        tntNodeArrayFree(mod_op);
        
        /* Apply the MPO to the start state, truncating down to chi */
        printf("Multiplying MPO and MPS\n");
        err += tntMpsMpoProduct(wf_start,mpo,chi);
        printf("finished multiplying MPO and MPS\n");
        
        /* Free the MPO */
        tntNetworkFree(&mpo);
    }
    
    /* Renormalise the MPS if the flag is given */
    if (mod_renorm) {
        double normsq;
        
        /* First make sure the orthonormality centre is on the first site */
        tntMpsOrth(wf_start,0);
        
        /* Find the norm squared */
        normsq = tntMpsSelfProduct(wf_start,0);
        
        /* Scale the first node appropriately */
        tntNodeScaleReal(tntNodeFindFirst(wf_start), 1.0/sqrt(normsq));
    }
    
    return err;
}
