/*
 * Authors: Sarah Al-Assam, Stephen Clark and Dieter Jaksch
 * (c) University of Oxford 2014-2015
 * 
 * tntweb.h
 * 
 * Function definitions for back-end of TNTgo Application.
 * 
 */

/* Include the header for the TNT library, including MPS functions */
#include "tntMps.h"

#define DMRG_ITERMAX 50 /* Maximum number of DMRG iterations */

void twbLog(char *logmsg);

void twbLoadNodeArray(char *loadname, unsigned numelems, tntNodeArray *arr, const char *var_prefix, const char *nodeid);

void twbLoadStringArray(char *loadname, unsigned numelems, tntStringArray *arr, const char *var_prefix);

void twbLoadExOp(char *loadname, tntMpsExOp *ExOp);

void twbLoadMpo(char *loadname, unsigned L, tntNetwork *mpo, const char *var_prefix, const char *var_suffix);

tntDoubleArray twbMpsDmrg(tntNetwork wf_gs, tntNetwork mpo, int chi, double precision, unsigned i_max);

tntNetwork twbMpsCreatePmpo(unsigned L, tntNodeArray *op, tntIntArray *sitenum);

double twbMpsModify(char *loadname, tntNetwork wf_start, int chi);

void twbSetParams(tntComplexArray *nnparam, tntComplexArray *nnparam_step, tntComplexArray *nntparam, tntComplexArray *osparam, tntComplexArray *osparam_step, tntComplexArray *ostparam, unsigned loop);

unsigned twbCheckParams(tntComplexArray *nnparam, tntComplexArray *nntparam, tntComplexArray *osparam, tntComplexArray *ostparam, unsigned loop, unsigned numsteps);