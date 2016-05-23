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
 * Documentation for DMRG routine goes here
 * 
 * 
 */
tntDoubleArray twbMpsDmrg(tntNetwork wf_gs, /* network representing ground state. Start state should have its orthogonalistaion centre on site 0  */
                          tntNetwork mpo, /* network representing system Hamiltonian */
                          int chi, /* maximum internal dimension */
                          double precision, /* Absolute energy difference between iterations for convergence. Note an even number of sweeps will always be performed. */
                          unsigned i_max) /* Maximum number of iterations (1 iteration = a LTR sweep or a RTL sweep) */
{
    tntNodeArray HeffL, HeffR; /* Precontracted nodes for the right and left sides of the network. */
    tntDoubleArray E; /* The energy values to return */
    char logmsg[TNT_STRLEN]; /* log message string, number string */
    double err=0.0, Ediff; /* truncation error, difference in energy */
    int i; /* counter */
    
    /* Allocate memory for array to hold the energy values after each iteration */
    E = tntDoubleArrayAlloc(i_max+1);
    
    /* Initialise the nodes that will be needed for the DMRG sweep */
    tntMpsVarMinMpoInit(wf_gs, mpo, &HeffL, &HeffR);
    
    /* Determine the energy of the start state */
    E.vals[0] = tntComplexToReal(tntMpsMpoMpsProduct(wf_gs, mpo));
    
    printf("Starting energy is %g. \n",E.vals[0]);
    
    
    
    for (i = 1; i<=i_max; i++) {
        /* Perform a minimization sweep from left to right then right to left */
        E.vals[i] = tntMpsVarMinMpo2sSweep(wf_gs, TNT_MPS_R, chi, mpo, &HeffL, &HeffR, &err);
        E.vals[i] = tntMpsVarMinMpo2sSweep(wf_gs, TNT_MPS_L, chi, mpo, &HeffL, &HeffR, &err);
        
        Ediff = E.vals[i-1] - E.vals[i];
        
        sprintf(logmsg,"calculating ground state, \\( \\Delta E_{%d} \\) is \\( %1.0f \\times 10^{%2.0f}\\)", i, Ediff/pow(10,floor(log10(Ediff))), floor(log10(Ediff)));
        twbLog(logmsg);
        
        /* Change the size of the array containing the energy each iteration */
        E.sz = E.numrows = i+1;
        
        if (E.vals[i-1] - E.vals[i] < precision) {
            break;
        }
    }
    
    tntNodeArrayFree(&HeffL);
    tntNodeArrayFree(&HeffR);
    
    return E;
}
