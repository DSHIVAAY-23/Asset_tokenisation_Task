// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AssetToken.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

/**
 * @title AssetTokenV2
 * @notice Upgraded version of AssetToken with pausability
 * @dev Adds PausableUpgradeable functionality to enforce transfer restrictions
 */
contract AssetTokenV2 is AssetToken, PausableUpgradeable {
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Pauses all token transfers
     * @dev Restricted to DEFAULT_ADMIN_ROLE only
     */
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses token transfers
     * @dev Restricted to DEFAULT_ADMIN_ROLE only
     */
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @notice Hook that is called before any transfer of tokens
     * @dev Overrides ERC20's _update to add pause enforcement
     * @param from Address tokens are transferred from
     * @param to Address tokens are transferred to
     * @param value Amount of tokens transferred
     */
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override whenNotPaused {
        super._update(from, to, value);
    }
}
