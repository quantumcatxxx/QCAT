// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

interface IRolesPermissions {
    function assignRole(address identity, address actor, string memory role) external;
    function getRole(address identity, address actor) external view returns (string memory);
}

interface IMultiSignatureSecurity {
    function executeMultiSigAction(
        address identity,
        address[] memory signers,
        uint8[] memory sigVs,
        bytes32[] memory sigRs,
        bytes32[] memory sigSs,
        bytes32 actionHash
    ) external;

    function rotateKeys(address identity, address newKey) external;
}

interface IFeeManagement {
    function setFee(uint operation, uint fee) external;
    function getFee(uint operation) external view returns (uint);
}

interface IUtilityLibrary {
    function checkSignature(
        address identity,
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS,
        bytes32 hash
    ) external view returns (bool);

    function hasExpired(uint timestamp) external view returns (bool);
}

interface IBatchOperations {
    function registerBatch(address[] memory identities, bytes32[] memory metadataHashes) external;
}

contract DIDManager is UUPSUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    IRolesPermissions private rolesPermissions;
    IMultiSignatureSecurity private multiSig;
    IFeeManagement private feeManagement;
    IUtilityLibrary private utils;
    IBatchOperations private batchOps;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    event RoleAssigned(address indexed identity, address indexed actor, string role);
    event MultiSigExecuted(address indexed identity, bytes32 actionHash);
    event FeeUpdated(uint operation, uint fee);
    event BatchRegistered(address[] identities, bytes32[] metadataHashes);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _rolesPermissions,
        address _multiSig,
        address _feeManagement,
        address _utilityLibrary,
        address _batchOperations
    ) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();

        rolesPermissions = IRolesPermissions(_rolesPermissions);
        multiSig = IMultiSignatureSecurity(_multiSig);
        feeManagement = IFeeManagement(_feeManagement);
        utils = IUtilityLibrary(_utilityLibrary);
        batchOps = IBatchOperations(_batchOperations);

        _setupRole(ADMIN_ROLE, msg.sender);
    }

    /// @dev Only the admin can authorize upgrades.
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(ADMIN_ROLE) {}

    /// @dev Assign a role to an actor for a specific DID.
    function assignRole(address identity, address actor, string memory role) external onlyRole(ADMIN_ROLE) {
        rolesPermissions.assignRole(identity, actor, role);
        emit RoleAssigned(identity, actor, role);
    }

    /// @dev Execute a multi-signature action with the provided signatures.
    function executeMultiSigAction(
        address identity,
        address[] memory signers,
        uint8[] memory sigVs,
        bytes32[] memory sigRs,
        bytes32[] memory sigSs,
        bytes32 actionHash
    ) external nonReentrant {
        multiSig.executeMultiSigAction(identity, signers, sigVs, sigRs, sigSs, actionHash);
        emit MultiSigExecuted(identity, actionHash);
    }

    /// @dev Update the fee for a specific operation.
    function setFee(uint operation, uint fee) external onlyRole(ADMIN_ROLE) {
        feeManagement.setFee(operation, fee);
        emit FeeUpdated(operation, fee);
    }

    /// @dev Get the fee for a specific operation.
    function getFee(uint operation) external view returns (uint) {
        return feeManagement.getFee(operation);
    }

    /// @dev Register multiple identities with their metadata hashes.
    function registerBatch(address[] memory identities, bytes32[] memory metadataHashes) external nonReentrant {
        batchOps.registerBatch(identities, metadataHashes);
        emit BatchRegistered(identities, metadataHashes);
    }

    /// @dev Check if a signature is valid.
    function checkSignature(
        address identity,
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS,
        bytes32 hash
    ) external view returns (bool) {
        return utils.checkSignature(identity, sigV, sigR, sigS, hash);
    }

    /// @dev Check if a timestamp has expired.
    function hasExpired(uint timestamp) external view returns (bool) {
        return utils.hasExpired(timestamp);
    }
}
