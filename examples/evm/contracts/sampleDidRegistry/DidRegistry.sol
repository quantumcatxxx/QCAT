// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./IdentityOwnership.sol";
import "./DelegateManagement.sol";
import "./AttributesManagement.sol";
import "./MetadataAuditing.sol";
import "./MultiSignatureSecurity.sol";

contract DIDRegistry is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    IdentityOwnership,
    DelegateManagement,
    AttributesManagement,
    MetadataAuditing,
    MultiSignatureSecurity
{
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Initializer function (replaces constructor)
    function initialize(address admin) public initializer {
        // Initialize parent contracts
        __AccessControl_init();
        __UUPSUpgradeable_init();

        // Set up roles
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(UPGRADER_ROLE, admin);

        // Call initializations of modular components if needed
        _initializeIdentityOwnership(admin);
        _initializeDelegateManagement(admin);
        _initializeAttributesManagement(admin);
    }

    // Authorize upgrades (UUPS pattern)
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    // Example of combining multiple functionalities
    function fullDIDResolution(address identity)
        public
        view
        returns (
            address owner,
            bytes32[] memory attributes,
            address[] memory delegates
        )
    {
        owner = identityOwner(identity); // From IdentityOwnership
        attributes = listAttributes(identity); // From AttributesManagement
        delegates = getActiveDelegates(identity); // From DelegateManagement
    }
}
