// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { UmaCtfAdapter } from "src/UmaCtfAdapter.sol";

/// @title DeployAdapters
/// @notice Deploys two UmaCtfAdapter instances in a single transaction batch:
///         - Standard adapter pointing at the CTF Core contract
///         - NegRisk adapter pointing at the NegRisk Operator contract
/// @author Polymarket
contract DeployAdapters is Script {
    /// @notice Deploys both adapters.
    /// @param admin        - Admin address added to both adapters
    /// @param ctf          - CTF Core (ConditionalTokens) address  - standard adapter
    /// @param negRiskCtf   - NegRisk Operator address              - neg-risk adapter
    /// @param finder       - UMA Finder address
    /// @param oo           - UMA OptimisticOracleV2 address
    function deployAdapters(
        address admin,
        address ctf,
        address negRiskCtf,
        address finder,
        address oo
    ) public returns (address standardAdapter, address negRiskAdapter) {
        address deployer = msg.sender;

        vm.startBroadcast();

        UmaCtfAdapter standard = new UmaCtfAdapter(ctf, finder, oo);
        standard.addAdmin(admin);

        if (deployer != admin) standard.renounceAdmin();
        standardAdapter = address(standard);
        console.log("Standard adapter deployed:", standardAdapter);

        UmaCtfAdapter negRisk = new UmaCtfAdapter(negRiskCtf, finder, oo);
        negRisk.addAdmin(admin);
        if (deployer != admin) negRisk.renounceAdmin();
        negRiskAdapter = address(negRisk);
        console.log("NegRisk adapter deployed: ", negRiskAdapter);

        vm.stopBroadcast();

        _verify(deployer, admin, ctf, standardAdapter, "standard");
        _verify(deployer, admin, negRiskCtf, negRiskAdapter, "negRisk");
    }

    function _verify(address deployer, address admin, address ctf, address adapter, string memory label) internal view {
        UmaCtfAdapter a = UmaCtfAdapter(adapter);
        if (deployer != admin && a.isAdmin(deployer))
            revert(string(abi.encodePacked(label, ": deployer admin not renounced")));
        if (!a.isAdmin(admin)) revert(string(abi.encodePacked(label, ": adapter admin not set")));
        if (address(a.ctf()) != ctf) revert(string(abi.encodePacked(label, ": unexpected CTF address")));
    }
}
