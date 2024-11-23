// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract MetadataAuditing is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    // Role for administrators
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Storage for metadata hashes
    mapping(address => bytes32) private _metadataHashes;

    // Events
    event MetadataHashSet(address indexed identity, bytes32 hash);
    event MetadataHashUpdated(address indexed identity, bytes32 oldHash, bytes32 newHash);
    event AuditLogEmitted(address indexed identity, string action);
    event AnchorOnChain(address indexed identity, bytes32 dataHash);

    // Initializer
    function initialize(address admin) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        // Set up admin role
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
    }

    // Set metadata hash
    function setMetadataHash(address identity, bytes32 hash) external onlyRole(ADMIN_ROLE) {
        bytes32 oldHash = _metadataHashes[identity];
        _metadataHashes[identity] = hash;

        if (oldHash == bytes32(0)) {
            emit MetadataHashSet(identity, hash);
        } else {
            emit MetadataHashUpdated(identity, oldHash, hash);
        }
    }

    // Get metadata hash
    function getMetadataHash(address identity) external view returns (bytes32) {
        return _metadataHashes[identity];
    }

    // Emit audit log
    function emitAuditLog(address identity, string memory action) external onlyRole(ADMIN_ROLE) {
        emit AuditLogEmitted(identity, action);
    }

    // Anchor data on-chain
    function anchorOnChain(address identity, bytes32 dataHash) external onlyRole(ADMIN_ROLE) {
        emit AnchorOnChain(identity, dataHash);
    }

    // Batch set metadata hashes
    function setMetadataHashBatch(address[] memory identities, bytes32[] memory hashes) external onlyRole(ADMIN_ROLE) {
        require(identities.length == hashes.length, "Array length mismatch");
        for (uint256 i = 0; i < identities.length; i++) {
            setMetadataHash(identities[i], hashes[i]);
        }
    }

    // Authorize upgrades
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(ADMIN_ROLE) {}
}
