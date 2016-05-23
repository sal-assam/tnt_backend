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

void twbSetParams(tntComplexArray *nnparam, tntComplexArray *nnparam_step, tntComplexArray *nntparam, tntComplexArray *osparam, tntComplexArray *osparam_step, tntComplexArray *ostparam, unsigned loop) {
    
    unsigned i, j;
    
    if (NULL != nnparam) {
        for (i = 0; i < nnparam->numrows; i++) { /* Row counter is for terms */
            for (j = 0; j < nnparam->numcols; j++) { /* column counter is for sites */
                nnparam_step->vals[i + nnparam->numrows * j].re = nnparam->vals[i + nnparam->numrows * j].re * nntparam->vals[i + nntparam->numrows * (loop-1)].re;
            }
        }
    }
    if (NULL != osparam) {
        for (i = 0; i < osparam->numrows; i++) { /* Row counter is for terms */
            for (j = 0; j < osparam->numcols; j++) { /* column counter is for sites */
                osparam_step->vals[i + osparam->numrows * j].re = osparam->vals[i + osparam->numrows * j].re * ostparam->vals[i + ostparam->numrows * (loop-1)].re;
            }
        }
    }
}

unsigned twbCheckParams(tntComplexArray *nnparam, tntComplexArray *nntparam, tntComplexArray *osparam, tntComplexArray *ostparam, unsigned loop, unsigned numsteps) {
    
    unsigned i, j, changed_params=0;
    
    if (NULL != nnparam && loop != numsteps) {
        for (i = 0; i < nntparam->numrows; i++) {
            if (nntparam->vals[i + nntparam->numrows * loop].re != nntparam->vals[i + nntparam->numrows * (loop-1)].re) {
                changed_params = 1;
                break;
            }
        }
    }
    if (0 == changed_params && NULL != osparam && loop != numsteps) {
        for (i = 0; i < ostparam->numrows; i++) {
            if (ostparam->vals[i + ostparam->numrows * loop].re != ostparam->vals[i + ostparam->numrows * (loop-1)].re) {
                changed_params = 1;
                break;
            }
        }
    }
    return changed_params;
}