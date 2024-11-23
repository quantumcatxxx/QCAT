// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract DIDLifecycleManagement is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    // Role for administrators
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Storage for DID states
    mapping(address => bool) private _deactivatedDIDs;
    mapping(address => address) private _newOwners;

    // Events
    event DIDDeactivated(address indexed identity, uint256 timestamp);
    event DIDReactivated(address indexed identity, address newOwner, uint256 timestamp);
    event DIDSelfDestructed(address indexed identity, uint256 timestamp);
    event BatchRegistered(address[] identities, bytes32[] metadataHashes);

    // Initializer
    function initialize(address admin) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        // Set up admin role
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
    }

    // Deactivate DID
    function deactivateDID(address identity) external onlyRole(ADMIN_ROLE) {
        require(!_deactivatedDIDs[identity], "DID already deactivated");
        _deactivatedDIDs[identity] = true;
        emit DIDDeactivated(identity, block.timestamp);
    }

    // Reactivate DID
    function reactivateDID(address identity, address newOwner) external onlyRole(ADMIN_ROLE) {
        require(_deactivatedDIDs[identity], "DID is not deactivated");
        _deactivatedDIDs[identity] = false;
        _newOwners[identity] = newOwner;
        emit DIDReactivated(identity, newOwner, block.timestamp);
    }

    // Self-destruct DID
    function selfDestructDID(address identity) external onlyRole(ADMIN_ROLE) {
        require(_deactivatedDIDs[identity], "DID must be deactivated first");
        delete _deactivatedDIDs[identity];
        delete _newOwners[identity];
        emit DIDSelfDestructed(identity, block.timestamp);
    }

    // Batch register DIDs
    function registerBatch(address[] memory identities, bytes32[] memory metadataHashes) external onlyRole(ADMIN_ROLE) {
        require(identities.length == metadataHashes.length, "Array length mismatch");
        emit BatchRegistered(identities, metadataHashes);
    }

    // Authorize upgrades
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(ADMIN_ROLE) {}
}
