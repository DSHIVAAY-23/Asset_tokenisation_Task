// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AssetToken.sol";
import "../src/AssetTokenV2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

/**
 * @title AssetTokenTest
 * @notice Comprehensive test suite for AssetToken V1, upgrade process, and V2 functionality
 */
contract AssetTokenTest is Test {
    AssetToken public tokenV1;
    AssetTokenV2 public tokenV2Implementation;
    ERC1967Proxy public proxy;
    AssetToken public token;

    address public admin;
    address public minter;
    address public user1;
    address public user2;

    uint256 public constant MAX_SUPPLY = 1_000_000 * 10**18; // 1 million tokens

    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        // Setup test accounts
        admin = address(this);
        minter = makeAddr("minter");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // Deploy V1 implementation
        tokenV1 = new AssetToken();

        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            AssetToken.initialize.selector,
            "Xaults Asset Token",
            "XAT",
            MAX_SUPPLY,
            admin
        );

        // Deploy proxy
        proxy = new ERC1967Proxy(address(tokenV1), initData);
        token = AssetToken(address(proxy));

        // Grant MINTER_ROLE to minter address
        token.grantRole(token.MINTER_ROLE(), minter);
    }

    /**
     * @notice Test 1: Mint tokens and verify balanceOf (State Check)
     */
    function testMintAndBalanceCheck() public {
        uint256 mintAmount = 100 * 10**18; // 100 tokens

        vm.prank(minter);
        token.mint(user1, mintAmount);

        assertEq(token.balanceOf(user1), mintAmount, "User1 balance should be 100 tokens");
        assertEq(token.totalSupply(), mintAmount, "Total supply should be 100 tokens");
    }

    /**
     * @notice Test: Max supply enforcement
     */
    function testMaxSupplyEnforcement() public {
        uint256 exceedAmount = MAX_SUPPLY + 1;

        vm.prank(minter);
        vm.expectRevert(AssetToken.MaxSupplyExceeded.selector);
        token.mint(user1, exceedAmount);
    }

    /**
     * @notice Test: Minting up to max supply should succeed
     */
    function testMintUpToMaxSupply() public {
        vm.prank(minter);
        token.mint(user1, MAX_SUPPLY);

        assertEq(token.totalSupply(), MAX_SUPPLY, "Total supply should equal max supply");
        assertEq(token.balanceOf(user1), MAX_SUPPLY, "User1 should have max supply");
    }

    /**
     * @notice Test: Only MINTER_ROLE can mint
     */
    function testOnlyMinterCanMint() public {
        uint256 mintAmount = 100 * 10**18;

        vm.prank(user1);
        vm.expectRevert();
        token.mint(user1, mintAmount);
    }

    /**
     * @notice Test 2: Upgrade to V2 and verify storage persistence (Storage Layout Verification)
     */
    function testUpgradePreservesState() public {
        // Mint tokens in V1
        uint256 mintAmount = 100 * 10**18;
        vm.prank(minter);
        token.mint(user1, mintAmount);

        // Verify V1 state
        assertEq(token.balanceOf(user1), mintAmount, "Pre-upgrade: User1 balance should be 100 tokens");
        assertEq(token.totalSupply(), mintAmount, "Pre-upgrade: Total supply should be 100 tokens");
        
        string memory nameV1 = token.name();
        string memory symbolV1 = token.symbol();
        uint256 maxSupplyV1 = token.maxSupply();

        // Deploy V2 implementation
        tokenV2Implementation = new AssetTokenV2();

        // Upgrade to V2
        vm.prank(admin);
        token.upgradeToAndCall(address(tokenV2Implementation), "");

        // Cast proxy to V2 interface
        AssetTokenV2 tokenV2 = AssetTokenV2(address(proxy));

        // Verify storage persistence after upgrade
        assertEq(tokenV2.balanceOf(user1), mintAmount, "Post-upgrade: User1 balance should be preserved");
        assertEq(tokenV2.totalSupply(), mintAmount, "Post-upgrade: Total supply should be preserved");
        assertEq(tokenV2.name(), nameV1, "Post-upgrade: Token name should be preserved");
        assertEq(tokenV2.symbol(), symbolV1, "Post-upgrade: Token symbol should be preserved");
        assertEq(tokenV2.maxSupply(), maxSupplyV1, "Post-upgrade: Max supply should be preserved");
    }

    /**
     * @notice Test 3: Pause functionality blocks transfers (New V2 Logic)
     */
    function testPauseBlocksTransfers() public {
        // Deploy and upgrade to V2
        tokenV2Implementation = new AssetTokenV2();
        vm.prank(admin);
        token.upgradeToAndCall(address(tokenV2Implementation), "");
        AssetTokenV2 tokenV2 = AssetTokenV2(address(proxy));

        // Mint tokens to user1
        uint256 mintAmount = 100 * 10**18;
        vm.prank(minter);
        tokenV2.mint(user1, mintAmount);

        // Pause the contract
        vm.prank(admin);
        tokenV2.pause();

        // Attempt transfer (should revert)
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        tokenV2.transfer(user2, 50 * 10**18);
    }

    /**
     * @notice Test: Unpause allows transfers
     */
    function testUnpauseAllowsTransfers() public {
        // Deploy and upgrade to V2
        tokenV2Implementation = new AssetTokenV2();
        vm.prank(admin);
        token.upgradeToAndCall(address(tokenV2Implementation), "");
        AssetTokenV2 tokenV2 = AssetTokenV2(address(proxy));

        // Mint tokens to user1
        uint256 mintAmount = 100 * 10**18;
        vm.prank(minter);
        tokenV2.mint(user1, mintAmount);

        // Pause and unpause
        vm.prank(admin);
        tokenV2.pause();
        
        vm.prank(admin);
        tokenV2.unpause();

        // Transfer should succeed
        uint256 transferAmount = 50 * 10**18;
        vm.prank(user1);
        tokenV2.transfer(user2, transferAmount);

        assertEq(tokenV2.balanceOf(user1), mintAmount - transferAmount, "User1 balance should decrease");
        assertEq(tokenV2.balanceOf(user2), transferAmount, "User2 should receive tokens");
    }

    /**
     * @notice Test: Only admin can pause
     */
    function testOnlyAdminCanPause() public {
        // Deploy and upgrade to V2
        tokenV2Implementation = new AssetTokenV2();
        vm.prank(admin);
        token.upgradeToAndCall(address(tokenV2Implementation), "");
        AssetTokenV2 tokenV2 = AssetTokenV2(address(proxy));

        // Non-admin tries to pause
        vm.prank(user1);
        vm.expectRevert();
        tokenV2.pause();
    }

    /**
     * @notice Test: Unauthorized upgrade should fail
     */
    function testUnauthorizedUpgrade() public {
        tokenV2Implementation = new AssetTokenV2();

        // Non-admin tries to upgrade
        vm.prank(user1);
        vm.expectRevert();
        token.upgradeToAndCall(address(tokenV2Implementation), "");
    }

    /**
     * @notice Test: Minting works after upgrade to V2
     */
    function testMintingWorksAfterUpgrade() public {
        // Upgrade to V2
        tokenV2Implementation = new AssetTokenV2();
        vm.prank(admin);
        token.upgradeToAndCall(address(tokenV2Implementation), "");
        AssetTokenV2 tokenV2 = AssetTokenV2(address(proxy));

        // Mint tokens
        uint256 mintAmount = 100 * 10**18;
        vm.prank(minter);
        tokenV2.mint(user1, mintAmount);

        assertEq(tokenV2.balanceOf(user1), mintAmount, "Minting should work in V2");
    }

    /**
     * @notice Test: Max supply enforcement persists after upgrade
     */
    function testMaxSupplyEnforcementAfterUpgrade() public {
        // Upgrade to V2
        tokenV2Implementation = new AssetTokenV2();
        vm.prank(admin);
        token.upgradeToAndCall(address(tokenV2Implementation), "");
        AssetTokenV2 tokenV2 = AssetTokenV2(address(proxy));

        // Try to exceed max supply
        uint256 exceedAmount = MAX_SUPPLY + 1;
        vm.prank(minter);
        vm.expectRevert(AssetToken.MaxSupplyExceeded.selector);
        tokenV2.mint(user1, exceedAmount);
    }
}
