/*
 Authors: Sarah Al-Assam, Stephen Clark and Dieter Jaksch
 Date:    $LastChangedDate$
 (c) University of Oxford 2014
 */

/*  webpmsp.c
 * 
 This contains functions for dealing with product MPS's. They are planned to be included in the tnt MPS library eventually, but for speed are just being defined here for the time being.
 *
 * 
 / * Include the head*er for the TNT library, including MPS functions */
#include "tntMps.h"


/* \ingroup mps
 * Creates an MPO network represeting a site-wide operator \f$\hat{O}\f$ formed from a product of \f$n\f$ onsite terms \f$\hat{o}_{i}\f$. 
 * 
 * \f[
 * \hat{O} = \prod_{i=0}^{n}\hat{o}_{i}
 * \f]
 * 
 * Each term \f$\hat{o}_{i}\f$ acts on a single site \f$j\f$ given by the entries of the array `sitenum`. 
 * If there is more than one operator on a site they will be contracted together to form a single operator such that the operator that appears first will be applied first.
 * If a site does not appear in the list of site numbers, an identity operator will be placed there instead.
 * The tensor product is represented as a network, having the same form as a non-product MPO (e.g. as created using tntMpsCreateMPO()).
 * However unlike a non-product MPO in this this case all the internal legs (left and right legs) will have dimension 1.  
 * 
 * \image html mps_pmpo.png
 * <CENTER> \image latex mps_pmpo.png ""  </CENTER>
 *
 * This function therefore creates a product MPO that can be used in any of the general MPS-MPO functions
 * However, if all that is required is a simple MPS-PMPO-MPS contraction or MPS-PMPO contraction without any quantum number conservation, it is recommended to use the tntMpsPmpo*() functions rather than creating an MPO using this function.
 * This is because the PMPO functions can take advantage of the orthogonality properties of the MPS, and that fact that contractions with identity do no need to be carried out, to provide a more efficient algorithm.
 * 
 * This function should be used, however, if QN conservation is turned on, and you wish to apply operators that are not U(1) invariant, but are U(1) covariant. 
 * This would be an operator which changes the total quantum number of any state it is applied to (e.g. increases boson number), but keeps the MPS as an eigenstate of that quantum number (e.g. it will still have a well-defined total number of bosons in the system). 
 * Operators of this type are ladder operators (e.g. \f$\hat{b}\f$ and \f$\hat{b}^{\dagger}\f$).
 * The function allows these operators to be applied, while keeping track of quantum number information, by assigning suitable quantum numbers to the internal legs of the MPO to make the tensors in the MPO invariant.
 * 
 * \return The network representing the matrix product operator.
 */
tntNetwork twbMpsCreatePmpo(unsigned L, /* Length of system. */
                            tntNodeArray *op, /* Array of on-site operators. */
                            tntIntArray *sitenum) /* Sitenumbers for the operators */
{
    tntNetwork pmpo; /* The network to return */
    tntNode siteop, tnA, tnB; /* Total operator for the current site, and the current pair of nodes that need contracting */
    tntIntArray qnums_phys, qnums_int, qnums_op; /* Quantum numbers for the physical legs and the internal legs, and for the current operator */
    unsigned j; /* For looping over sites */
    
    /* Check that there is a parameter for each of the onsite operators */
    if (op->sz != sitenum->sz) {
        tntErrorPrint("Cannot create a matrix product operator|The number of sitenumbers does not equal the number of operators.",42); /* NO_COVERAGE */
    } /* NO_COVERAGE */
    
    /* First create an empty network */
    pmpo = tntNetworkCreate();

    /* Create an identity node using the basis operator */
    tnA = tntNodeCreateEyeOp(NULL);
    
    /* Clear the quantum number info from the node if it exists */
    tntNodeClearQN(tnA);
    
    /* Add two singleton legs to left and right */
    tntNodeAddLeg(tnA,TNT_MPS_L);
    tntNodeAddLeg(tnA,TNT_MPS_R);
    
    /* Make a network of identity nodes */
    for (j = 0; j < L; j++) {
        tnB = tntNodeCopy(tnA,0);
        tntNodeInsertAtEnd(tnB, TNT_MPS_L, TNT_MPS_R, pmpo);
    }
    
    /* Free the identity node - it is not needed any more */
    tntNodeFree(&tnA);
    
    /* Apply the operators to the network. Note although this function is for applying a pmpo to an MPS, the additional upwards facing leg of the pmpo will not affect the way this function operates */
    tntMpsPmpoProduct(pmpo,op,sitenum);
    
    /* Now go through network, and deal with quantum numbers if they are being applied. */
    if (tntSymmTypeGet()) {
        
        /* Get the quantum numbers for the physical leg */
        qnums_phys = tntNodeGetQN(tntSysBasisOpGet(), TNT_MPS_D);
        
        /* Allocate array of the correct size for the internal leg quantum numbers - all the values will be initialised to zero */
        qnums_int = tntIntArrayAlloc(tntSymmNumGet());
        
        /* Get the first node in the network*/
        tnB = tntNodeFindFirst(pmpo);
        
        /* Loop through the sites, making each node invariant as you come accross it. */
        for (j = 0; j < L; j++) {
            
            /* match QNs on the incoming leg to be the same as those on the outgoing leg of the previous node (or zero if this is the first node) */
            tntNodeSetQN(tnB,TNT_MPS_L,&qnums_int,TNT_QN_IN);
            
            /* assign quantum numbers to the physical legs */
            tntNodeSetQN(tnB,TNT_MPS_D,&qnums_phys,TNT_QN_IN);
            tntNodeSetQN(tnB,TNT_MPS_U,&qnums_phys,TNT_QN_OUT);
            
            /* make the node invariant, this will set QNs on the right internal leg (the only remaining leg that does not have QNs set) as an outgoing leg */
            tntNodeMakeCovariantQN(tnB);
            
            tntNodePrintInfo(tnB);
            
            /* Get the quantum numbers on the leg (freeing previous values first) */
            tntIntArrayFree(&qnums_int);
            qnums_int = tntNodeGetQN(tnB, TNT_MPS_R);
            
            /* go to the next node */
            tnB = tntNodeFindConn(tnB, TNT_MPS_R);
        }   

        /* free the arrays containing the quantum numbers */
        tntIntArrayFree(&qnums_int);
        tntIntArrayFree(&qnums_phys);
        
    }
    
    /* return the network */
    return pmpo;
}
