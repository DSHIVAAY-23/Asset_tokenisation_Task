// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title AssetToken (V1)
 * @notice UUPS-upgradeable ERC20 token with role-based minting and supply cap
 * @dev Inherits ERC20Upgradeable, AccessControlUpgradeable, and UUPSUpgradeable
 */
contract AssetToken is 
    Initializable, 
    ERC20Upgradeable, 
    AccessControlUpgradeable, 
    UUPSUpgradeable 
{
    /// @notice Role identifier for addresses allowed to mint tokens
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice Maximum supply cap for the token
    uint256 private _maxSupply;

    /// @notice Thrown when minting would exceed the maximum supply
    error MaxSupplyExceeded();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the token contract (replaces constructor for upgradeable pattern)
     * @param name Token name
     * @param symbol Token symbol
     * @param maxSupply_ Maximum token supply cap
     * @param admin Address to receive DEFAULT_ADMIN_ROLE and MINTER_ROLE
     */
    function initialize(
        string memory name,
        string memory symbol,
        uint256 maxSupply_,
        address admin
    ) public initializer {
        __ERC20_init(name, symbol);
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _maxSupply = maxSupply_;
        
        // Grant roles to admin
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
    }

    /**
     * @notice Mints tokens to a specified address
     * @param to Address to receive minted tokens
     * @param amount Amount of tokens to mint
     * @dev Requires MINTER_ROLE and enforces maxSupply cap
     */
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        if (totalSupply() + amount > _maxSupply) {
            revert MaxSupplyExceeded();
        }
        _mint(to, amount);
    }

    /**
     * @notice Returns the maximum supply cap
     * @return Maximum token supply
     */
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @notice Authorizes contract upgrades
     * @param newImplementation Address of the new implementation contract
     * @dev Restricted to DEFAULT_ADMIN_ROLE only
     */
    function _authorizeUpgrade(address newImplementation) 
        internal 
        override 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {}
}
