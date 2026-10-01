// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CredentialSBT
 * @dev Soulbound Token (SBT) for creditworthiness credentials
 * 
 * This contract implements non-transferable ERC721 tokens that represent
 * creditworthiness credentials. Once minted, these tokens cannot be transferred
 * to another address, ensuring the credential remains bound to the original holder.
 * 
 * Key Features:
 * - Non-transferable: All transfer functions revert
 * - Non-approvable: Cannot approve others to manage tokens
 * - Burnable: Registry or owner can burn tokens
 * - Registry-only minting: Only the CreditworthinessRegistry can mint
 * 
 * Security: Credentials are permanently bound to the borrower's address,
 * preventing secondary markets or credential theft.
 */
contract CredentialSBT is ERC721, ERC721Burnable, Ownable {
    
    // ============================================
    // STATE VARIABLES
    // ============================================
    
    /// @notice Address of the CreditworthinessRegistry contract
    /// @dev Only this address can mint new tokens
    address public registryContract;
    
    /// @notice Mapping from token ID to metadata URI
    mapping(uint256 => string) private _tokenURIs;
    
    // ============================================
    // ERRORS
    // ============================================
    
    /// @dev Thrown when attempting to transfer a soulbound token
    error SoulboundTokenCannotBeTransferred();
    
    /// @dev Thrown when attempting to approve a soulbound token
    error SoulboundTokenCannotBeApproved();
    
    /// @dev Thrown when non-registry address attempts to mint
    error OnlyRegistryCanMint();
    
    /// @dev Thrown when registry address is not set
    error RegistryNotSet();
    
    // ============================================
    // MODIFIERS
    // ============================================
    
    /// @notice Ensures only the registry contract can call the function
    modifier onlyRegistry() {
        if (msg.sender != registryContract) {
            revert OnlyRegistryCanMint();
        }
        _;
    }
    
    // ============================================
    // CONSTRUCTOR
    // ============================================
    
    /**
     * @notice Initializes the SBT contract
     * @dev Sets the token name and symbol
     */
    constructor() ERC721("Creditworthiness Credential", "CWCRED") Ownable(msg.sender) {}
    
    // ============================================
    // REGISTRY MANAGEMENT
    // ============================================
    
    /**
     * @notice Sets the registry contract address
     * @dev Can only be called by the contract owner (deployer)
     * @param _registry Address of the CreditworthinessRegistry contract
     */
    function setRegistry(address _registry) external onlyOwner {
        require(_registry != address(0), "Invalid registry address");
        registryContract = _registry;
    }
    
    // ============================================
    // MINTING (Registry Only)
    // ============================================
    
    /**
     * @notice Mints a new soulbound token
     * @dev Can only be called by the registry contract
     * @param to Address to mint the token to (borrower)
     * @param tokenId Unique credential ID
     * @param uri Metadata URI for the credential
     */
    function mint(
        address to,
        uint256 tokenId,
        string memory uri
    ) external onlyRegistry {
        require(to != address(0), "Cannot mint to zero address");
        _safeMint(to, tokenId);
        _tokenURIs[tokenId] = uri;
    }
    
    // ============================================
    // SOULBOUND ENFORCEMENT - TRANSFER PREVENTION
    // ============================================
    
    /**
     * @dev Override transferFrom to make token non-transferable
     * @notice This function always reverts - soulbound tokens cannot be transferred
     */
    function transferFrom(
        address,
        address,
        uint256
    ) public pure override {
        revert SoulboundTokenCannotBeTransferred();
    }
    
    /**
     * @dev Override safeTransferFrom to make token non-transferable
     * @notice This function always reverts - soulbound tokens cannot be transferred
     */
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public pure override {
        revert SoulboundTokenCannotBeTransferred();
    }
    
    // ============================================
    // SOULBOUND ENFORCEMENT - APPROVAL PREVENTION
    // ============================================
    
    /**
     * @dev Override approve to prevent token approval
     * @notice This function always reverts - soulbound tokens cannot be approved
     */
    function approve(address, uint256) public pure override {
        revert SoulboundTokenCannotBeApproved();
    }
    
    /**
     * @dev Override setApprovalForAll to prevent operator approval
     * @notice This function always reverts - soulbound tokens cannot be approved
     */
    function setApprovalForAll(address, bool) public pure override {
        revert SoulboundTokenCannotBeApproved();
    }
    
    // ============================================
    // BURNING (Registry or Owner)
    // ============================================
    
    /**
     * @dev Override burn to allow registry or token owner to burn
     * @param tokenId ID of token to burn
     */
    function burn(uint256 tokenId) public override {
        require(
            msg.sender == registryContract || msg.sender == ownerOf(tokenId),
            "Only registry or owner can burn"
        );
        super.burn(tokenId);
        
        // Clear metadata
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
    
    // ============================================
    // METADATA
    // ============================================
    
    /**
     * @dev Returns the token URI for a given token ID
     * @param tokenId Token ID to query
     * @return Token metadata URI
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return _tokenURIs[tokenId];
    }
    
    /**
     * @notice Checks if this contract implements an interface
     * @dev Override to support interface detection
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
