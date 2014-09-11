/*
Authors: Sarah Al-Assam, Stephen Clark and Dieter Jaksch
Date:    $LastChangedDate$
(c) University of Oxford 2014
*/

/*  webmain.c

    This is the main C file for running code using the web interface.
*

/* Include the header for the TNT library, including MPS functions */
#include "tntMps.h"
/* helper functions */
void twbLoadNodeArray(char *loadname, unsigned numelems, tntNodeArray *arr, const char *var_prefix, const char *nodeid);
void twbLoadStringArray(char *loadname, unsigned numelems, tntStringArray *arr, const char *var_prefix);

int main(int argc, char **argv)
{
    
    
    /***********************************************************************************************/
    /*                             First define all variables required                             */
    /***********************************************************************************************/
    
    
    /* Networks and variables for the MPS wave function */
    tntNetwork wf_start; /* The original network */
    tntNetwork wf_gs; /* The ground state wave function */
    tntNetwork wf_evolved; /* The wave function evolved in time under system hamiltonian */
    char init_config[TNT_STRLEN]; 
    unsigned L; /* Length of the network */
    unsigned U1symm; /* Flag to specify whether symmetry information is turned on */
    
    /* Network for the mpo */
    tntNetwork mpo; /* The network representing the matrix product operator for finding the ground state */
    
    /* Variables needed for creating the MPO */
    unsigned numos, numnn; /* Number of onsite and nearest neighbour operators */
    tntComplexArray nnparams, osparams; /* parameters for creating the MPO */
    tntComplexArray *nnparam=&nnparams, *osparam=&osparams;  /* pointers to the above structures */
    tntNodeArray nnLs, nnRs, oss;  /* left and right nearest neighbour operators and onsite operators for creating the MPO */
    tntNodeArray *nnL=&nnLs, *nnR=&nnRs, *os=&oss;  /* pointers to the above structures */
    
    /* Variables needed for DMRG simulation */
    unsigned dodmrg; /* flag to specify whether to run DMRG simulation */
    struct dbl_arr E; /* Array to hold value of the energy for each iteration, and array of the size of the number of iterations */
    tntNodeArray HeffL, HeffR; /* Precontracted nodes for the right and left sides of the network. */
    unsigned i, i_max=30; /* iteration counter, maximum number of iterations */
    double prec = 1.0e-12; /* default precision for ground state calculation */
    
    /* Variables needed for creating the propagotors for time evolution */
    /* (currently just same operators as for ground state) */
    unsigned dotebd; /* flag to specify whether to run TEBD simulation */
    unsigned numsteps; /* number of time steps */
    tntComplex dtc; /* Complex time step */
    tntNodeArray Uarr; /* Arrays that make up the propagator */
    double err = 0.0; /* Truncation error from SVDs */
    unsigned bigsteps = 1; /* Number of 'bigsteps' or expectation values taken */
    unsigned tbigstep = 20; /* number of time steps per big step */
    tntDoubleArray extimes; /* evolved time at each bigstep */
    tntDoubleArray truncerrs; /* truncation error at each bigstep */
    unsigned loop; /* loop over time steps */
    
    /* Variables needed for calculating expectation values */
    tntMpsExOp ExOp; /* Structure for holding all the operators for calculating expectation values */
    unsigned ex_numos, ex_numnn, ex_numcs, ex_numap; /* Number of expectation values to calculate of each type */
    
    /* General variables needed */
    tntNode basisOp; /* Operator that defines the physical basis */
    int chi; /* Maximum internal dimension for the simulations */
    char loadname[TNT_STRLEN], saveprefix[TNT_STRLEN]; /* Name of the initialisation and save files */
    char calc_id[TNT_STRLEN]; /* unique identifier given to the calculation */
    unsigned D = 5; /* Default starting internal dimension for MPS for DMRG calculations */
    
    /***********************************************************************************************/
    /*                                        Load variables                                       */
    /***********************************************************************************************/
    
    /* Always first start with call to initialise library */
    tntInitialize();

    /* Get the load name and save name from the command line parameters. All the other parameters will be loaded from the initialisation file. */
    tntProcessCLOptions(argc,argv,loadname,NULL,saveprefix,&chi,NULL);
    
    /* Set the truncation tolerance. This avoids minimisation errors in the ARPACk routines when finding ground states which require a much smaller internal dimension than chi */
    tntSVDTruncTolSet(1e-12);
    
    /* Load the calculation id */
    tntLoadStrings(loadname, 1, calc_id, "calculation_id");
    
    /* Load general simulation parameters  */
    tntLoadParams(loadname, 5, 0, 0, &dotebd, "dotebd", 0, &dodmrg, "dodmrg", 0, &chi, "chi", 0, &L, "L", 0, &U1symm, "U1symm", 0);
    
    /* Load parameters specifying number of operators */
    tntLoadParams(loadname, 6, 0, 0, &numos, "h_numos", 0, &numnn, "h_numnn", 0, &ex_numos, "ex_numos", 0, 
                  &ex_numnn, "ex_numnn", 0, &ex_numcs, "ex_numcs", 0, &ex_numap, "ex_numap", 0);
    
    /* if tebd simulation is required, load the number of time steps and time step size, and the state to start the evolution from. */
    if (dotebd) {
        tntLoadParams(loadname, 1, 1, 0, &numsteps, "numsteps", 0, &(dtc.re), "dt", 0);
        tntLoadStrings(loadname, 1, init_config, "init_config");
    }
    
    /* Load and set the basis operator */
    tntLoadNodes(loadname, 1, &basisOp, "basisOp", "oplabels");
    tntSysBasisOpSet(basisOp);
    
    /* Load operators and parameters needed for defining the system Hamiltonian if they exist */
    if (numos) {
        twbLoadNodeArray(loadname, numos, os, "h_opos", "oplabels");
        tntLoadArrays(loadname, 0, 0, 1, osparam, "h_prmos");
    } else {
        os = NULL; 
        osparam = NULL;
    }
    if (numnn) {
        twbLoadNodeArray(loadname, numnn, nnL, "h_opnnL", "oplabels");
        twbLoadNodeArray(loadname, numnn, nnR, "h_opnnR", "oplabels");
        tntLoadArrays(loadname, 0, 0, 1, nnparam, "h_prmnn");
    } else {
        nnL = nnR = NULL;
        nnparam = NULL;
    }
    
    /* Load operators for calculating expectation values */
    twbLoadNodeArray(loadname, ex_numos, &(ExOp.ExOpOs), "ex_opos", "oplabels");
    twbLoadNodeArray(loadname, ex_numnn*2, &(ExOp.ExOp2nn), "ex_opnn", "oplabels");
    twbLoadNodeArray(loadname, ex_numcs*2, &(ExOp.ExOp2cs), "ex_opcs", "oplabels");
    twbLoadNodeArray(loadname, ex_numap*2, &(ExOp.ExOp2ap), "ex_opap", "oplabels");
    
    /* Load labels for operators */
    twbLoadStringArray(loadname, ex_numos, &(ExOp.LbOpOs), "ex_oposlabel");
    twbLoadStringArray(loadname, ex_numnn, &(ExOp.LbOp2nn), "ex_opnnlabel");
    twbLoadStringArray(loadname, ex_numcs, &(ExOp.LbOp2cs), "ex_opcslabel");
    twbLoadStringArray(loadname, ex_numap, &(ExOp.LbOp2ap), "ex_opaplabel");
    
    /***********************************************************************************************/
    /*                                       DMRG Calculation                                      */
    /***********************************************************************************************/
    
    if (dodmrg) {
        
        printf("---------------------------------------\n");
        printf("Starting DMRG \n");
        printf("---------------------------------------\n");
        
        /* Create random start state */
        wf_gs = tntMpsCreateRandom(L, D);
        
        /* Create the MPO */
        mpo = tntMpsCreateMpo(L, nnL, nnR, nnparam, os, osparam);
        
        tntSaveNetwork(saveprefix,"_operators",mpo,"mpo");
        
        /* Allocate memory for array to hold the energy values after each iteration */
        E = tntDoubleArrayAlloc(2*i_max+1);

        /* Initialise the nodes that will be needed for the DMRG sweep */
        tntMpsDmrgInit(wf_gs, mpo, &HeffL, &HeffR);
        
        /* Determine the energy of the start state */
        E.vals[0] = tntMpsMpoMpsProduct(wf_gs, mpo);
        
        printf("Starting energy for randomly generated MPS is %g. \n",E.vals[0]);
                
        for (i = 1; i<=i_max; i++) {
            /* Perform a minimization sweep from left to right then right to left */
            E.vals[2*i-1] = tntMpsDmrgSweep(wf_gs, TNT_MPS_R, chi, mpo, &HeffL, &HeffR, &err);
            
            printf("Iteration %d: Energy is %4.4g, difference is %4.4g.\n", 2*i-1, E.vals[2*i-1],(E.vals[2*i-2] - E.vals[2*i-1]));
            
            E.vals[2*i] = tntMpsDmrgSweep(wf_gs, TNT_MPS_L, chi, mpo, &HeffL, &HeffR, &err);

            printf("Iteration %d: Energy is %4.4g, difference is %4.4g.\n", 2*i, E.vals[2*i],(E.vals[2*i-1] - E.vals[2*i]));
            
            /* Change the size of the array containing the energy each iteration */
            E.sz = 2*i+1;
            tntSaveArrays(saveprefix,"", 0, 1, 0, &E, "E");
            
            if (fabs(E.vals[2*i - 1] - E.vals[2*i]) < prec) {
                
                break;
            }
        }
        
        /* Find and output expectation values */
        tntMpsExpecOutput(wf_gs, &ExOp, 0, 1, 1, saveprefix, 0);
        
        /* Save the final network, and the energy at each iteration */
        tntSaveNetwork(saveprefix,"_operators",wf_gs,"wf_gs");
        tntSaveArrays(saveprefix,"", 0, 1, 0, &E, "E");
        
        /*  Free all the dynamically allocated nodes and associated dynamically allocated arrays. */
        tntNetworkFree(&wf_gs);
        tntNetworkFree(&mpo);
        tntDoubleArrayFree(&E);
        tntNodeArrayFree(&HeffL);
        tntNodeArrayFree(&HeffR);

    }
    
    /***********************************************************************************************/
    /*                                       TEBD Calculation                                      */
    /***********************************************************************************************/    
    
    if (dotebd) {
        
        tntTruncType("sumsquares");
        
        /* If quantum number conservation is turned on, set the quantum numbers for the basis operator. This should ensure that any other functions create invariant operators */
        if (U1symm) {
            /* Load array for quantum number labels */
            tntIntArray qnums;
            tntLoadArrays(loadname, 1, 0, 0, &qnums, "qnums");
            
            /* Set symmetry type for system */
            tntSymmTypeSet("U(1)", 1);
            
            /* Set quanutm numbers on basis operators */
            tntNodeSetQN(basisOp, TNT_MPS_U, &qnums, TNT_QN_OUT);
            tntNodeSetQN(basisOp, TNT_MPS_D, &qnums, TNT_QN_IN);
            
            /* Set quantum numbers on all the expectation value operators */
            for (i = 0; i < ExOp.ExOpOs.sz; i++) {
                tntNodeSetQN(ExOp.ExOpOs.vals[i], TNT_MPS_U, &qnums, TNT_QN_OUT);
                tntNodeSetQN(ExOp.ExOpOs.vals[i], TNT_MPS_D, &qnums, TNT_QN_IN);
            }
            for (i = 0; i < ExOp.ExOp2nn.sz; i++) {
                tntNodeSetQN(ExOp.ExOp2nn.vals[i], TNT_MPS_U, &qnums, TNT_QN_OUT);
                tntNodeSetQN(ExOp.ExOp2nn.vals[i], TNT_MPS_D, &qnums, TNT_QN_IN);
            }
            for (i = 0; i < ExOp.ExOp2cs.sz; i++) {
                tntNodeSetQN(ExOp.ExOp2cs.vals[i], TNT_MPS_U, &qnums, TNT_QN_OUT);
                tntNodeSetQN(ExOp.ExOp2cs.vals[i], TNT_MPS_D, &qnums, TNT_QN_IN);
            }
            for (i = 0; i < ExOp.ExOp2ap.sz; i++) {
                tntNodeSetQN(ExOp.ExOp2ap.vals[i], TNT_MPS_U, &qnums, TNT_QN_OUT);
                tntNodeSetQN(ExOp.ExOp2ap.vals[i], TNT_MPS_D, &qnums, TNT_QN_IN);
            }
            
            /* Free the quantum numbers */
            tntIntArrayFree(&qnums);
        }
        tntSysBasisOpSet(basisOp);
        
        /* Create a starting state from the initial configuration */
        wf_start = tntMpsCreateConfig(L, init_config);
        wf_evolved = tntNetworkCopy(wf_start);
        
        /* Create Suzuki Trotter second order staircase propagator */
        Uarr = tntMpsCreatePropagatorST2(L, dtc, nnL, nnR, nnparam, os, osparam);
        
        printf("---------------------------------------\n");
        printf("Starting TEBD \n");
        printf("---------------------------------------\n");
        
        /* Allocate memory to hold the evolved time each time the expectation value is taken */
        extimes = tntDoubleArrayAlloc(numsteps/tbigstep+((numsteps%tbigstep)?2:1));
        truncerrs = tntDoubleArrayAlloc(numsteps/tbigstep+((numsteps%tbigstep)?2:1));
        
        /* Calculate initial expectation values */
        tntMpsExpecOutput(wf_evolved, &ExOp, 0, 1, 1, saveprefix, bigsteps);
        extimes.vals[0] = 0.0;
        truncerrs.vals[0] = 0.0;
        
        /* Set error to zero */
        err = 0.0;
        
        /* Run the simulation for all the time steps. */
        for (loop = 1; loop <= numsteps; loop++) {
            /* Sweep right to left then left to right */
            err += tntMpsTebdSweepInhom(wf_evolved, TNT_MPS_R, chi, Uarr);
            err += tntMpsTebdSweepInhom(wf_evolved, TNT_MPS_L, chi, Uarr);
            
            /* Calculate expectation values every tbigstep */
            if ((0 == loop%tbigstep)||(loop == numsteps)) {
                /* take the current evolved time */
                extimes.vals[bigsteps] = loop*dtc.re;
                truncerrs.vals[bigsteps] = err;
                
                /* increment counter of number of big steps */
                bigsteps++;
                
                printf("Completed %d out of %d steps. The truncation error is %g. \n", loop, numsteps, err);
                /* Find and print expectation values, updating the counter (last argument) */
                tntMpsExpecOutput(wf_evolved, &ExOp, 0, (loop == numsteps), 1, saveprefix, bigsteps);
                
            }
        }
        
        /*  Save the wave function */
        tntSaveNetwork(saveprefix,"_operators", wf_evolved, "wf_evolved");
        
        /* Save the time at each iteration */
        tntSaveArrays(saveprefix,"",0,2,0, &extimes, "extimes",&truncerrs,"truncerrs");
        
        /*  Free all the dynamically allocated nodes and associated dynamically allocated arrays. */
        tntNetworkFree(&wf_evolved);
        tntNetworkFree(&wf_start);
        tntNodeArrayFree(&Uarr);
    }

    /* Free dynamically allocated arrays */
    tntMpsExOpFree(&ExOp);

    /* Finalise calculation */
    tntFinalize();

    return 0;
}

