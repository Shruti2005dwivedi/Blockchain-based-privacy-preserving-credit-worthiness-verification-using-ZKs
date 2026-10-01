// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title CreditworthinessRegistry
 * @dev Central registry for creditworthiness credentials using zero-knowledge proofs
 * 
 * This contract manages the lifecycle of creditworthiness credentials:
 * - Verifies zero-knowledge proofs from borrowers
 * - Mints soulbound tokens (SBTs) representing verified credentials
 * - Tracks credential state (VERIFIED, ACTIVE, EXPIRED, REVOKED)
 * - Manages authorized issuers who can revoke credentials
 * 
 * Privacy: Borrower financial data (income, credit score, payment ratio) never
 * appears on-chain. Only proof verification results and public thresholds are stored.
 * 
 * Security: Uses AccessControl for role-based permissions and ReentrancyGuard
 * to prevent reentrancy attacks.
 */
contract CreditworthinessRegistry is AccessControl, ReentrancyGuard {
    
    // ============================================
    // ROLES
    // ============================================
    
    /// @notice Role for authorized issuers who can revoke credentials
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    
    // ============================================
    // ENUMS
    // ============================================
    
    /// @notice Possible states for a credential
    enum CredentialState {
        PENDING,      // Awaiting confirmation (not used in current implementation)
        VERIFIED,     // ZK proof verified and credential issued
        ACTIVE,       // Credential is currently valid (alias for VERIFIED)
        EXPIRED,      // Credential has passed its expiration date
        REVOKED       // Credential has been revoked by an issuer
    }
    
    // ============================================
    // STRUCTS
    // ============================================
    
    /// @notice Credential data structure
    struct Credential {
        uint256 id;              // Unique credential ID
        address borrower;        // Borrower's address (credential holder)
        uint256 policyId;        // Policy ID defining thresholds
        CredentialState state;   // Current credential state
        uint256 issuedAt;        // Timestamp when issued
        uint256 expiresAt;       // Expiration timestamp
        bytes32 proofHash;       // Hash of the ZK proof for verification
    }
    
    // ============================================
    // STATE VARIABLES
    // ============================================
    
    /// @notice Mapping from credential ID to Credential struct
    mapping(uint256 => Credential) public credentials;
    
    /// @notice Mapping from borrower address to their credential IDs
    mapping(address => uint256[]) public borrowerCredentials;
    
    /// @notice Counter for generating unique credential IDs
    uint256 public credentialIdCounter;
    
    /// @notice Address of the Groth16 verifier contract
    address public verifierContract;
    
    /// @notice Address of the SBT contract
    address public sbtContract;
    
    // ============================================
    // ERRORS
    // ============================================
    
    error InvalidAddress(address provided);
    error InvalidProof();
    error CredentialNotFound(uint256 credentialId);
    error CredentialAlreadyRevoked(uint256 credentialId);
    error NotAuthorized(address caller);
    error InvalidProofArrayLength();
    
    // ============================================
    // EVENTS
    // ============================================
    
    event CredentialIssued(
        uint256 indexed credentialId,
        address indexed borrower,
        uint256 policyId,
        uint256 issuedAt,
        uint256 expiresAt
    );
    
    event CredentialRevoked(
        uint256 indexed credentialId,
        address indexed revoker,
        string reason,
        uint256 revokedAt
    );
    
    event CredentialExpired(
        uint256 indexed credentialId,
        uint256 expiredAt
    );
    
    event IssuerAuthorized(
        address indexed issuer,
        address indexed authorizer,
        uint256 timestamp
    );
    
    event IssuerRevoked(
        address indexed issuer,
        address indexed revoker,
        uint256 timestamp
    );
    
    // ============================================
    // CONSTRUCTOR
    // ============================================
    
    /**
     * @notice Initializes the registry contract
     * @param _verifierContract Address of the Groth16Verifier contract
     * @param _sbtContract Address of the CredentialSBT contract
     */
    constructor(address _verifierContract, address _sbtContract) {
        if (_verifierContract == address(0)) revert InvalidAddress(_verifierContract);
        if (_sbtContract == address(0)) revert InvalidAddress(_sbtContract);
        
        verifierContract = _verifierContract;
        sbtContract = _sbtContract;
        
        // Grant DEFAULT_ADMIN_ROLE to deployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    // ============================================
    // CREDENTIAL ISSUANCE
    // ============================================
    
    /**
     * @notice Submits a credential with ZK proof verification
     * @dev Verifies the proof, mints SBT, and stores credential data
     * @param a Proof component a (2 elements)
     * @param b Proof component b (2x2 elements)
     * @param c Proof component c (2 elements)
     * @param publicSignals Public signals [minIncome, minCreditScore, minPaymentRatio]
     * @param policyId Policy ID defining the thresholds
     * @param expirationDays Number of days until credential expires
     * @return credentialId The newly created credential ID
     */
    function submitCredential(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[3] memory publicSignals,
        uint256 policyId,
        uint256 expirationDays
    ) external nonReentrant returns (uint256 credentialId) {
        if (msg.sender == address(0)) revert InvalidAddress(msg.sender);
        
        // Verify the zero-knowledge proof
        bool proofValid = _verifyProof(a, b, c, publicSignals);
        if (!proofValid) revert InvalidProof();
        
        // Generate new credential ID
        credentialIdCounter++;
        credentialId = credentialIdCounter;
        
        // Calculate expiration
        uint256 issuedAt = block.timestamp;
        uint256 expiresAt = issuedAt + (expirationDays * 1 days);
        
        // Compute proof hash for verification
        bytes32 proofHash = keccak256(abi.encodePacked(a, b, c, publicSignals));
        
        // Create credential
        credentials[credentialId] = Credential({
            id: credentialId,
            borrower: msg.sender,
            policyId: policyId,
            state: CredentialState.VERIFIED,
            issuedAt: issuedAt,
            expiresAt: expiresAt,
            proofHash: proofHash
        });
        
        // Add to borrower's credential list
        borrowerCredentials[msg.sender].push(credentialId);
        
        // Mint SBT to borrower
        _mintSBT(msg.sender, credentialId);
        
        // Emit event
        emit CredentialIssued(
            credentialId,
            msg.sender,
            policyId,
            issuedAt,
            expiresAt
        );
        
        return credentialId;
    }
    
    /**
     * @dev Internal function to verify ZK proof
     * @param a Proof component a
     * @param b Proof component b
     * @param c Proof component c
     * @param input Public signals
     * @return True if proof is valid
     */
    function _verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[3] memory input
    ) internal view returns (bool) {
        // Call the verifier contract
        (bool success, bytes memory data) = verifierContract.staticcall(
            abi.encodeWithSignature(
                "verifyProof(uint256[2],uint256[2][2],uint256[2],uint256[3])",
                a, b, c, input
            )
        );
        
        if (!success) return false;
        return abi.decode(data, (bool));
    }
    
    /**
     * @dev Internal function to mint SBT
     * @param to Address to mint to
     * @param tokenId Token ID (credential ID)
     */
    function _mintSBT(address to, uint256 tokenId) internal {
        // Call mint function on SBT contract
        (bool success,) = sbtContract.call(
            abi.encodeWithSignature(
                "mint(address,uint256,string)",
                to,
                tokenId,
                ""  // Empty URI for now
            )
        );
        require(success, "SBT minting failed");
    }
    
    // ============================================
    // CREDENTIAL REVOCATION
    // ============================================
    
    /**
     * @notice Revokes a credential
     * @dev Can only be called by accounts with ISSUER_ROLE
     * @param credentialId ID of credential to revoke
     * @param reason Reason for revocation
     */
    function revokeCredential(
        uint256 credentialId,
        string memory reason
    ) external onlyRole(ISSUER_ROLE) {
        Credential storage cred = credentials[credentialId];
        
        if (cred.borrower == address(0)) {
            revert CredentialNotFound(credentialId);
        }
        
        if (cred.state == CredentialState.REVOKED) {
            revert CredentialAlreadyRevoked(credentialId);
        }
        
        // Update state
        cred.state = CredentialState.REVOKED;
        
        // Emit event
        emit CredentialRevoked(
            credentialId,
            msg.sender,
            reason,
            block.timestamp
        );
    }
    
    // ============================================
    // CREDENTIAL EXPIRATION
    // ============================================
    
    /**
     * @notice Checks if credential is expired and updates state
     * @param credentialId ID of credential to check
     * @return isValid True if credential is still valid
     */
    function checkExpiration(uint256 credentialId) public returns (bool isValid) {
        Credential storage cred = credentials[credentialId];
        
        if (cred.borrower == address(0)) {
            revert CredentialNotFound(credentialId);
        }
        
        // Check if expired
        if (block.timestamp > cred.expiresAt && cred.state != CredentialState.REVOKED) {
            cred.state = CredentialState.EXPIRED;
            emit CredentialExpired(credentialId, block.timestamp);
            return false;
        }
        
        // Valid if not revoked and not expired
        return cred.state != CredentialState.REVOKED && cred.state != CredentialState.EXPIRED;
    }
    
    /**
     * @notice Checks if credential is currently valid
     * @param credentialId ID of credential to check
     * @return True if credential is valid
     */
    function isCredentialValid(uint256 credentialId) external view returns (bool) {
        Credential storage cred = credentials[credentialId];
        
        if (cred.borrower == address(0)) return false;
        if (cred.state == CredentialState.REVOKED) return false;
        if (block.timestamp > cred.expiresAt) return false;
        
        return true;
    }
    
    // ============================================
    // CREDENTIAL QUERIES
    // ============================================
    
    /**
     * @notice Gets credential details
     * @param credentialId ID of credential
     * @return Credential struct
     */
    function getCredential(uint256 credentialId) external view returns (Credential memory) {
        return credentials[credentialId];
    }
    
    /**
     * @notice Gets active credentials for a borrower
     * @param borrower Borrower's address
     * @return Array of active credential IDs
     */
    function getActiveCredentials(address borrower) external view returns (uint256[] memory) {
        uint256[] memory allCreds = borrowerCredentials[borrower];
        uint256 activeCount = 0;
        
        // Count active credentials
        for (uint256 i = 0; i < allCreds.length; i++) {
            Credential storage cred = credentials[allCreds[i]];
            if (cred.state != CredentialState.REVOKED && block.timestamp <= cred.expiresAt) {
                activeCount++;
            }
        }
        
        // Build array of active credentials
        uint256[] memory activeCreds = new uint256[](activeCount);
        uint256 index = 0;
        for (uint256 i = 0; i < allCreds.length; i++) {
            Credential storage cred = credentials[allCreds[i]];
            if (cred.state != CredentialState.REVOKED && block.timestamp <= cred.expiresAt) {
                activeCreds[index] = allCreds[i];
                index++;
            }
        }
        
        return activeCreds;
    }
    
    // ============================================
    // ISSUER MANAGEMENT
    // ============================================
    
    /**
     * @notice Authorizes an issuer
     * @dev Can only be called by accounts with DEFAULT_ADMIN_ROLE
     * @param issuer Address to authorize as issuer
     */
    function authorizeIssuer(address issuer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (issuer == address(0)) revert InvalidAddress(issuer);
        
        _grantRole(ISSUER_ROLE, issuer);
        
        emit IssuerAuthorized(issuer, msg.sender, block.timestamp);
    }
    
    /**
     * @notice Revokes issuer authorization
     * @dev Can only be called by accounts with DEFAULT_ADMIN_ROLE
     * @param issuer Address to revoke issuer role from
     */
    function revokeIssuer(address issuer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(ISSUER_ROLE, issuer);
        
        emit IssuerRevoked(issuer, msg.sender, block.timestamp);
    }
    
    /**
     * @notice Checks if address is authorized issuer
     * @param issuer Address to check
     * @return True if address has ISSUER_ROLE
     */
    function isAuthorizedIssuer(address issuer) external view returns (bool) {
        return hasRole(ISSUER_ROLE, issuer);
    }
}
