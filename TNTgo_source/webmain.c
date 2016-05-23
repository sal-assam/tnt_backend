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

/* Global variables for log file name */
char logname[TNT_STRLEN];

int main(int argc, char **argv)
{
    
    
    /***********************************************************************************************/
    /*                             First define all variables required                             */
    /***********************************************************************************************/
    
    
    /* Networks and variables for the MPS wave function */
    tntNetwork wf_start; /* The original network */
    tntNetwork wf_gs=NULL; /* The ground state wave function */
    tntNetwork wf_evolved; /* The wave function evolved in time under system hamiltonian */
    unsigned usegsfortebd=0; /* flag to specify whether the ground state should be used as a base for the TEBD calculation */
    unsigned modifybasestate; /* flag to specify whether modifiers have been provided for the initial state */
    unsigned calc_energy; /* flag to specify whether energy of evolved state should be calculated */
    char init_config[TNT_STRLEN]; /* initial configuration to use for TEBD if not using ground state */
    unsigned L; /* Length of the network */
    tntIntArray qnums; /* quantum numbers for the physical leg */
    unsigned U1symm; /* Flag to specify whether symmetry information is turned on */
    double err; /* truncation error */
    
    /* General variables needed */
    tntNode basisOp; /* Operator that defines the physical basis */
    int chi; /* Maximum internal dimension for the simulations */
    char loadname[TNT_STRLEN], saveprefix[TNT_STRLEN]; /* Name of the initialisation, log and save files */
    char calc_id[TNT_STRLEN]; /* unique identifier given to the calculation */
    char logmsg[TNT_STRLEN];/* log file message when it needs to be dynamically created */
    unsigned D = 5; /* Default starting internal dimension for MPS for DMRG calculations */
    unsigned i, j; /* Loop counters */
    
    /* Variable for the matrix product operators (the same variable is used for both the ground state Hamiltonian and the modifier MPO) */
    tntNetwork mpo; /* The network representing the MPO */
    
    /* Variables needed for DMRG simulation */
    unsigned dodmrg; /* flag to specify whether to run DMRG simulation */
    unsigned U1symm_ground=0; /* Flag to specify whether symmetry information is turned on for ground state calculation */
    int qn_tot; /* total quantum number of start state */
    tntDoubleArray E; /* Array to hold value of the energy for each iteration, and array of the size of the number of iterations */
    unsigned i_max = DMRG_ITERMAX; /* maximum number of iterations */
    double precision; /* default precision for ground state calculation */
    
    unsigned numos, numnn; /* Number of onsite and nearest neighbour operators */
    tntComplexArray nnparams, osparams; /* parameters for creating the Hamiltonian */
    tntComplexArray *nnparam=&nnparams, *osparam=&osparams;  /* pointers to the above structures */
    tntNodeArray nnLs, nnRs, oss;  /* left and right nearest neighbour operators and onsite operators for creating the Hamiltonian */
    tntNodeArray *nnL=&nnLs, *nnR=&nnRs, *os=&oss;  /* pointers to the above structures */
    char varname[TNT_STRLEN]; /* Used to hold variable name currently being loaded */
    
    /* Variables needed for creating the propagotors for time evolution */
    unsigned dotebd; /* flag to specify whether to run TEBD simulation */
    unsigned U1symm_dyn; /* Flag to specify whether symmetry information is turned on for dynamic calculation */
    unsigned numsteps; /* number of time steps */
    tntComplex dtc; /* Complex time step */
    tntNetwork prop; /* Network that makes up the propagator */
    unsigned bigsteps = 1; /* Counter of the number of 'bigsteps' or expectation values so far taken */
    unsigned numbigsteps; /* number of big time steps that will be carried out */
    unsigned tbigstep; /* number of time steps per big step */
    tntComplexArray nntparams, ostparams; /* parameters for temporal variation in operators */
    tntComplexArray *nntparam=&nntparams, *ostparam=&ostparams;  /* pointers to parameters for temporal variation in operators */
    tntComplexArray nnparams_step, osparams_step;  /* spatial parameters for current time step */
    tntComplexArray *nnparam_step=&nnparams_step, *osparam_step=&osparams_step;  /* pointers to spatial parameters for current time step */
    unsigned changed_params=0; /* flag for whether new parameters are needed for this time step */
    tntDoubleArray extimes; /* evolved time at each bigstep */
    tntDoubleArray truncerrs; /* truncation error at each time step */
    unsigned loop; /* loop over time steps */
    unsigned calc_ol_gs, calc_ol_is; /* flags for whether or not to calculate overlaps with ground state or initial state */
    
    /* Variables needed for calculating expectation values */
    tntMpsExOp ExOp; /* Structure for holding all the operators for calculating expectation values */
    tntDoubleArray overlaps_gs, overlaps_is, energies; /* arrays for holding the overlaps and energy at each time step */
    unsigned changed_params_bigstep = 0; /* Check if parameters have changed since the last big step */
    
    /***********************************************************************************************/
    /*                                        Load variables                                       */
    /***********************************************************************************************/
    
    /* Always first start with call to initialise library */
    tntInitialize();
    
    /* Get the load name and save name from the command line parameters. All the other parameters will be loaded from the initialisation file. */
    tntProcessCLOptions(argc,argv,loadname,logname,saveprefix,NULL,NULL);
    
    twbLog("loading calculation parameters from input file");
    /* Set the truncation tolerance. This avoids minimisation errors in the ARPACK routines when finding ground states which require a much smaller internal dimension than chi */
    tntSVDTruncTolSet(1e-12);
    
    /* Load the calculation id */
    tntLoadStrings(loadname, 1, calc_id, "calculation_id");
    
    /* Load flags  */
    tntLoadParams(loadname, 3, 0, 0, &dodmrg, "dodmrg", 0, &dotebd, "dotebd", 0, &usegsfortebd, "usegsfortebd", 0);
    tntLoadParams(loadname, 4, 0, 0, &modifybasestate, "modifybasestate", 0, &calc_ol_gs, "calc_ol_gs", 0, &calc_ol_is, "calc_ol_is", 0, &calc_energy, "calc_energy", 0);
    
    /* Load general simulation parameters  */
    tntLoadParams(loadname, 2, 0, 0, &chi, "chi", 0, &L, "L", 0);
    
    /* Load and set the basis operator, then free (set function makes copy of basis operator) */
    tntLoadNodes(loadname, 1, &basisOp, "basisOp", "oplabels");
    tntSysBasisOpSet(basisOp);
    tntNodeFree(&basisOp);
    
    /* Load the operators required for expectation values */
    twbLoadExOp(loadname, &ExOp);
    
    /* Flags for whether qn info should be used */
    tntLoadParams(loadname, 2, 0, 0, &U1symm_ground, "U1symm_ground", 0, &U1symm_dyn, "U1symm_dyn", 0);
    
    twbLog("setting symmetry information");
    /* Set symmetries if they are required by the calculation */
    if ((dodmrg && U1symm_ground) || (!dodmrg)&& U1symm_dyn) {
        /* Load array for quantum number labels, and variable for the total quantum number of the start state */
        tntLoadArrays(loadname, 1, 0, 0, &qnums, "qnums");
        tntLoadParams(loadname, 1, 0, 0, &qn_tot, "U1symm_num", 0);
        
        /* Set symmetry type for system */
        tntSymmTypeSet("U(1)", 1);
        
        /* Set quanutm numbers on basis operator */
        basisOp = tntSysBasisOpGet();
        tntNodeSetQN(basisOp, TNT_MPS_U, &qnums, TNT_QN_OUT);
        tntNodeSetQN(basisOp, TNT_MPS_D, &qnums, TNT_QN_IN);
        
        /* Free the quantum numbers */
        tntIntArrayFree(&qnums);
    }
    
    /***********************************************************************************************/
    /*                                       DMRG Calculation                                      */
    /***********************************************************************************************/
    if (dodmrg) {
        
        twbLog("starting ground state calculation");
        
        /* Create random start state */
        wf_gs = tntMpsCreateSymmRandom(L, &qn_tot);
        
        /* Load the precision required for the calculation */
        tntLoadParams(loadname, 0, 1, 0, &precision, "precision", 0);
        
        /* Load the MPO */
        twbLoadMpo(loadname, L, &mpo,"h_","_g");
        
        E = twbMpsDmrg(wf_gs,mpo,chi,precision,i_max);

        twbLog("calculating ground state expectation values");
        
        /* Find and output expectation values */
        tntMpsExpecOutput(wf_gs, &ExOp, 0, 0, 1, saveprefix, 0);
        
        twbLog("saving output from ground state calculation");
        
        /* Save the energy at each iteration */
        tntSaveArrays(saveprefix,"", 0, 1, 0, &E, "E");
        
        /*  Free the ground state wave function if it is no longer required. */
        if (!usegsfortebd && !calc_ol_gs) {
            tntNetworkFree(&wf_gs);
        }
        tntNetworkFree(&mpo);
        tntDoubleArrayFree(&E);
    }
    
    /***********************************************************************************************/
    /*                                       TEBD Calculation                                      */
    /***********************************************************************************************/    
    
    if (dotebd) {
        if ((U1symm_ground)&&(!U1symm_dyn)) { 
            /* If symmetries are already enforced from GS calculation, but shouldn't be enforced for time evolution, turn symmetry conservation off */
            tntSymmTypeUnset();
        } 
        
        /* Load the number of time steps and time step size, overlap flag, and the state to start the evolution from. */
        tntLoadParams(loadname, 2, 1, 0, &numsteps, "numsteps", 0, &tbigstep, "bigstep", 0, &(dtc.re), "dt", 0);
        if (!usegsfortebd) {
            tntLoadStrings(loadname, 1, init_config, "init_config");
        }
        
        tntTruncType("sumsquares");
        
        /* ------- Create a starting state from the initial configuration or use ground state --------- */
        if (usegsfortebd) {
            if (calc_ol_gs) {
                wf_start = tntNetworkCopy(wf_gs);
            } else {
                wf_start = wf_gs;
            }
        } else {
            twbLog("creating configuration start state for time evolution");
            wf_start = tntMpsCreateConfig(L, init_config);
        }
        /***********************************************************************************************/
        /*                              Apply modifiers to the base state                              */
        /***********************************************************************************************/
        if (modifybasestate) {
            
            twbLog("modifiying base state before starting time evolution");
            
            err = twbMpsModify(loadname, wf_start, chi);
            /* save the truncation error for reference */
            tntSaveParams(saveprefix,"", 0, 1, 0, err, "modifier_err");
        }
        
        
        /* -------- Do time evolution  --------------- */
        twbLog("setting up time evolution calculation");
        
        /* Load the number of operators that make up the system Hamiltonian */
        tntLoadParams(loadname, 2, 0, 0, &numos, "h_numos_d", 0, &numnn, "h_numnn_d", 0);
        
        /* Load operators and parameters needed for defining the system Hamiltonian if they exist */
        if (numos) {
            twbLoadNodeArray(loadname, numos, os, "h_opos_d", "oplabels");
            tntLoadArrays(loadname, 0, 0, 2, osparam, "h_prmos_d", ostparam, "h_prmos_t");
        } else {
            os = NULL; 
            osparam = ostparam = osparam_step = NULL;
        }
        if (numnn) {
            twbLoadNodeArray(loadname, numnn, nnL, "h_opnnL_d", "oplabels"); 
            twbLoadNodeArray(loadname, numnn, nnR, "h_opnnR_d", "oplabels");
            tntLoadArrays(loadname, 0, 0, 2, nnparam, "h_prmnn_d", nntparam, "h_prmnn_t");
        } else {
            nnL = nnR = NULL;
            nnparam = nntparam = nnparam_step = NULL;
        }
        
        /* Create copy of start state for evolution if the start state is needed for overlap calculations, else simply assign start state. */
        wf_evolved = calc_ol_is ? tntNetworkCopy(wf_start) : wf_start;
        
        /* Calculate total number of big time steps there will be */
        numbigsteps = numsteps/tbigstep+((numsteps%tbigstep)?2:1);
        
        /* Allocate memory to hold the evolved time each time the expectation value is taken */
        extimes = tntDoubleArrayAlloc(numbigsteps);
        truncerrs = tntDoubleArrayAlloc(numsteps);
        
        /* If overlap calculation is required, allocate an array to hold the values */
        if (calc_ol_gs) overlaps_gs = tntDoubleArrayAlloc(numbigsteps);
        if (calc_ol_is) overlaps_is = tntDoubleArrayAlloc(numbigsteps);
        if (calc_energy) energies = tntDoubleArrayAlloc(numbigsteps);
               
        /* Initialise parameters for first time step */
        if (NULL != nnparam) {
            nnparams_step = tntComplexArrayAlloc(nnparam->numrows,nnparam->numcols);
        }
        if (NULL != osparam) {
            osparams_step = tntComplexArrayAlloc(osparam->numrows,osparam->numcols);
        }
        twbSetParams(nnparam, nnparam_step, nntparam, osparam, osparam_step, ostparam, 1);
        prop = tntMpsCreatePropST2sc(L, dtc, nnL, nnR, nnparam_step, os, osparam_step);
        
        /* Calculate initial expectation values */
        tntMpsExpecOutput(wf_evolved, &ExOp, 0, 1, 1, saveprefix, bigsteps);
        extimes.vals[0] = 0.0;
        if (calc_ol_gs) overlaps_gs.vals[0] = tntComplexToReal(tntMpsMpsProduct(wf_gs,wf_evolved));
        if (calc_ol_is) overlaps_is.vals[0] = tntComplexToReal(tntMpsMpsProduct(wf_start,wf_evolved));
        if (calc_energy) {
            mpo = tntMpsCreateMpo(L, nnL, nnR, nnparam_step, os, osparam_step);
            energies.vals[0] = tntComplexToReal(tntMpsMpoMpsProduct(wf_evolved,mpo));
        }
        
        /* Run the simulation for all the time steps. */
        for (loop = 1; loop <= numsteps; loop++) {
            if (1 == changed_params) {
                /* reassign parameters for this time step */
                twbSetParams(nnparam, nnparam_step, nntparam, osparam, osparam_step, ostparam, loop);
                /* Create Suzuki Trotter second order staircase propagator */
                prop = tntMpsCreatePropST2sc(L, dtc, nnL, nnR, nnparam_step, os, osparam_step);
            }
            
            /* Sweep right to left then left to right */
            truncerrs.vals[loop-1] = tntMpsPropST2scProduct(wf_evolved, prop, chi);

            /* Calculate expectation values every tbigstep */
            if ((0 == loop%tbigstep)||(loop == numsteps)) {
                /* take the current evolved time */
                extimes.vals[bigsteps] = loop*dtc.re;
                
                sprintf(logmsg,"calculating time evolution, %2.0f%% complete",(100.0*loop)/(1.0*numsteps));
                twbLog(logmsg);
                
                if (calc_ol_gs) overlaps_gs.vals[bigsteps] = tntComplexToReal(tntMpsMpsProduct(wf_gs,wf_evolved));
                if (calc_ol_is) overlaps_is.vals[bigsteps] = tntComplexToReal(tntMpsMpsProduct(wf_start,wf_evolved));
                if (calc_energy) {
                    if (changed_params_bigstep) { /* check whether Hamiltonian has changed since last big step */
                        tntNetworkFree(&mpo);
                        mpo = tntMpsCreateMpo(L, nnL, nnR, nnparam_step, os, osparam_step); /* create new energy operator */
                        changed_params_bigstep = 0; /* reset flag */
                    }
                    energies.vals[bigsteps] = tntComplexToReal(tntMpsMpoMpsProduct(wf_evolved,mpo));
                }
                /* increment counter of number of big steps */
                bigsteps++;
                
                /* Find and print expectation values, updating the counter (last argument) */
                tntMpsExpecOutput(wf_evolved, &ExOp, 0, 0, 1, saveprefix, bigsteps);
               
            }
            
            /* Check whether there are a new set of time dependent parameters for the next time step. */
            changed_params = twbCheckParams(nnparam, nntparam, osparam, ostparam, loop, numsteps);
            if (changed_params) changed_params_bigstep = 1;
            
        }
        
        /* Save the time at each iteration */
        tntSaveArrays(saveprefix,"",0,2,0, &extimes, "extimes",&truncerrs,"truncerrs");
        
        /* Save overlap values if appropriate */
        if (calc_ol_gs) tntSaveArrays(saveprefix,"", 0, 1, 0, &overlaps_gs, "overlaps_gs");
        if (calc_ol_is) tntSaveArrays(saveprefix,"", 0, 1, 0, &overlaps_is, "overlaps_is");
        if (calc_energy) tntSaveArrays(saveprefix,"", 0, 1, 0, &energies, "energies");
        
        twbLog("time evolution calculation complete");
                                      
    }
    /* Finalise calculation */
    tntFinalize();
    
    return 0;
}

