pragma circom 2.0.0;

// Import the GreaterEqThan comparator from circomlib
include "../node_modules/circomlib/circuits/comparators.circom";

/*
 * Creditworthiness Verification Circuit
 * 
 * This circuit proves that a borrower's private financial data satisfies
 * minimum creditworthiness thresholds without revealing the actual values.
 * 
 * Private Inputs (never revealed):
 *   - income: Borrower's annual income
 *   - creditScore: Borrower's credit score (typically 300-850)
 *   - paymentRatio: Borrower's on-time payment ratio (0-100%)
 * 
 * Public Inputs (visible on-chain):
 *   - minIncome: Minimum required income threshold
 *   - minCreditScore: Minimum required credit score threshold
 *   - minPaymentRatio: Minimum required payment ratio threshold
 * 
 * Output:
 *   - valid: 1 if all conditions are met, 0 otherwise
 * 
 * The circuit verifies:
 *   income >= minIncome AND
 *   creditScore >= minCreditScore AND
 *   paymentRatio >= minPaymentRatio
 */

template CreditworthinessVerifier() {
    // ============================================
    // SIGNAL DECLARATIONS
    // ============================================
    
    // Private inputs - borrower's actual financial data (stays private)
    signal input income;
    signal input creditScore;
    signal input paymentRatio;
    
    // Public inputs - policy thresholds (visible to verifiers)
    signal input minIncome;
    signal input minCreditScore;
    signal input minPaymentRatio;
    
    // Output signal - 1 if all conditions satisfied, 0 otherwise
    signal output valid;
    
    // Intermediate signals for storing comparison results
    signal incomeValid;
    signal creditScoreValid;
    signal paymentRatioValid;
    
    // ============================================
    // COMPARISON COMPONENTS
    // ============================================
    
    // GreaterEqThan(n) component checks if in[0] >= in[1]
    // where both values are represented as n-bit numbers
    
    // Income comparison - using 64-bit for large income values
    component incomeCheck = GreaterEqThan(64);
    incomeCheck.in[0] <== income;
    incomeCheck.in[1] <== minIncome;
    incomeValid <== incomeCheck.out;
    
    // Credit score comparison - using 16-bit (max 65535, sufficient for 300-850 range)
    component creditScoreCheck = GreaterEqThan(16);
    creditScoreCheck.in[0] <== creditScore;
    creditScoreCheck.in[1] <== minCreditScore;
    creditScoreValid <== creditScoreCheck.out;
    
    // Payment ratio comparison - using 8-bit (max 255, sufficient for 0-100 range)
    component paymentRatioCheck = GreaterEqThan(8);
    paymentRatioCheck.in[0] <== paymentRatio;
    paymentRatioCheck.in[1] <== minPaymentRatio;
    paymentRatioValid <== paymentRatioCheck.out;
    
    // ============================================
    // AND LOGIC - ALL CONDITIONS MUST BE TRUE
    // ============================================
    
    // Combine all three conditions using multiplication
    // Result is 1 only if ALL comparisons return 1
    // If any comparison returns 0, the entire result is 0
    signal allConditionsMet;
    allConditionsMet <== incomeValid * creditScoreValid;
    valid <== allConditionsMet * paymentRatioValid;
    
    // ============================================
    // BOOLEAN CONSTRAINT
    // ============================================
    
    // Ensure the output is boolean (0 or 1)
    // This constraint: valid * (valid - 1) === 0
    // Is satisfied only when valid = 0 or valid = 1
    valid * (valid - 1) === 0;
}

// ============================================
// MAIN COMPONENT
// ============================================

// Declare which signals are public
// All inputs except the main component's inputs are public by default
// We explicitly mark the threshold signals as public
component main {public [minIncome, minCreditScore, minPaymentRatio]} = CreditworthinessVerifier();
