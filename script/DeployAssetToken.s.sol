// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/AssetToken.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title DeployAssetToken
 * @notice Foundry script to deploy AssetToken V1 via UUPS proxy
 */
contract DeployAssetToken is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deployer address:", deployer);
        console.log("Deployer balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy implementation contract
        AssetToken implementation = new AssetToken();
        console.log("AssetToken V1 Implementation deployed at:", address(implementation));

        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            AssetToken.initialize.selector,
            "Xaults Asset Token",  // name
            "XAT",                 // symbol
            1_000_000 * 10**18,    // maxSupply: 1 million tokens
            deployer               // admin
        );

        // Deploy proxy
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );

        console.log("===========================================");
        console.log("ERC1967Proxy deployed at:", address(proxy));
        console.log("===========================================");
        console.log("");
        console.log("To interact with the token, use the proxy address:");
        console.log(address(proxy));

        vm.stopBroadcast();

        // Verify initialization
        AssetToken token = AssetToken(address(proxy));
        console.log("");
        console.log("Token Details:");
        console.log("  Name:", token.name());
        console.log("  Symbol:", token.symbol());
        console.log("  Max Supply:", token.maxSupply() / 10**18, "tokens");
        console.log("  Admin has DEFAULT_ADMIN_ROLE:", token.hasRole(token.DEFAULT_ADMIN_ROLE(), deployer));
        console.log("  Admin has MINTER_ROLE:", token.hasRole(token.MINTER_ROLE(), deployer));
    }
}
