// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";

/// @title DeployUmaInfra
/// @notice Deploys UMA infrastructure contracts (Finder + dependencies + OptimisticOracleV2)
///         using pre-compiled artifacts in the artifacts/ directory.
///         After deployment, the script wires all contracts into the Finder and whitelists
///         the YES_OR_NO_QUERY identifier and the given collateral token.
contract DeployUmaInfra is Script {
    // Interface selectors for Finder's changeImplementationAddress
    bytes32 constant IDENTIFIER_WHITELIST_KEY = bytes32("IdentifierWhitelist");
    bytes32 constant COLLATERAL_WHITELIST_KEY = bytes32("CollateralWhitelist");
    bytes32 constant STORE_KEY = bytes32("Store");
    bytes32 constant OPTIMISTIC_ORACLE_KEY = bytes32("OptimisticOracle");

    bytes32 constant YES_OR_NO_IDENTIFIER = bytes32("YES_OR_NO_QUERY");

    /// @notice Deploys all required UMA infrastructure contracts and wires them together.
    /// @param collateral - Collateral token address to whitelist on the CollateralWhitelist
    function deployUmaInfra(address collateral) public returns (address finder, address optimisticOracle) {
        vm.startBroadcast();

        finder = _deploy(vm.getCode("artifacts/Finder.json"), "");
        console.log("Finder deployed:", finder);

        address identifierWhitelist = _deploy(vm.getCode("artifacts/IdentifierWhitelist.json"), "");
        console.log("IdentifierWhitelist deployed:", identifierWhitelist);

        address collateralWhitelist = _deploy(vm.getCode("artifacts/AddressWhitelist.json"), "");
        console.log("CollateralWhitelist (AddressWhitelist) deployed:", collateralWhitelist);

        //    constructor(FixedPoint.Unsigned _fixedOracleFeePerSecondPerPfc,
        //                FixedPoint.Unsigned _weeklyDelayFeePerSecondPerPfc,
        //                address _timerAddress)
        address store = _deploy(vm.getCode("artifacts/Store.json"), abi.encode(uint256(0), uint256(0), address(0)));
        console.log("Store deployed:", store);

        _changeImplementation(finder, IDENTIFIER_WHITELIST_KEY, identifierWhitelist);
        _changeImplementation(finder, COLLATERAL_WHITELIST_KEY, collateralWhitelist);
        _changeImplementation(finder, STORE_KEY, store);

        //    constructor(uint256 _liveness, address _finderAddress, address _timerAddress)
        //    Default liveness = 2 hours (7200s), no mock timer.
        optimisticOracle = _deploy(
            vm.getCode("artifacts/OptimisticOracleV2.json"),
            abi.encode(uint256(7200), finder, address(0))
        );
        console.log("OptimisticOracleV2 deployed:", optimisticOracle);

        _changeImplementation(finder, OPTIMISTIC_ORACLE_KEY, optimisticOracle);

        _addSupportedIdentifier(identifierWhitelist, YES_OR_NO_IDENTIFIER);
        console.log("Whitelisted YES_OR_NO_QUERY identifier");

        if (collateral != address(0)) {
            _addToWhitelist(collateralWhitelist, collateral);
            console.log("Whitelisted collateral:", collateral);
        }

        vm.stopBroadcast();
    }

    /// @dev Concatenates creation bytecode + constructor args and deploys via CREATE.
    function _deploy(bytes memory bytecode, bytes memory args) internal returns (address addr) {
        bytes memory initCode = abi.encodePacked(bytecode, args);
        assembly {
            addr := create(0, add(initCode, 0x20), mload(initCode))
        }
        require(addr != address(0), "deployment failed");
    }

    /// @dev Calls Finder.changeImplementationAddress(bytes32, address)
    function _changeImplementation(address finder_, bytes32 key, address impl) internal {
        (bool ok, ) = finder_.call(abi.encodeWithSignature("changeImplementationAddress(bytes32,address)", key, impl));
        require(ok, "Finder.changeImplementationAddress failed");
    }

    /// @dev Calls IdentifierWhitelist.addSupportedIdentifier(bytes32)
    function _addSupportedIdentifier(address whitelist, bytes32 identifier) internal {
        (bool ok, ) = whitelist.call(abi.encodeWithSignature("addSupportedIdentifier(bytes32)", identifier));
        require(ok, "IdentifierWhitelist.addSupportedIdentifier failed");
    }

    /// @dev Calls AddressWhitelist.addToWhitelist(address)
    function _addToWhitelist(address whitelist, address addr) internal {
        (bool ok, ) = whitelist.call(abi.encodeWithSignature("addToWhitelist(address)", addr));
        require(ok, "AddressWhitelist.addToWhitelist failed");
    }
}
