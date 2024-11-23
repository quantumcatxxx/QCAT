// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

contract IdentityOwnership is Initializable, OwnableUpgradeable, UUPSUpgradeable, EIP712Upgradeable {
    // Struct to store identity details
    struct IdentityData {
        address owner;
        address recoveryAddress;
        uint256 recoveryExpiration;
    }

    // Mappings for identity ownership and metadata
    mapping(address => IdentityData) private identities;
    mapping(address => mapping(string => string)) private identityMetadata;

    // Events
    event OwnershipChanged(address indexed identity, address indexed previousOwner, address indexed newOwner);
    event OwnershipRevoked(address indexed identity, address indexed previousOwner);
    event RecoveryAddressSet(address indexed identity, address indexed recoveryAddress, uint256 expiration);
    event MetadataUpdated(address indexed identity, string key, string value);
    event CrossChainDIDResolved(address indexed resolvedAddress, bytes crossChainData);

    // Upgradeable proxy version
    string public version;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory _version) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __EIP712_init("IdentityOwnership", "1");
        version = _version;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // Modifier for identity owner access
    modifier onlyIdentityOwner(address identity) {
        require(identities[identity].owner == msg.sender, "Not the identity owner");
        _;
    }

    // Modifier to ensure valid addresses
    modifier validAddress(address account) {
        require(account != address(0), "Invalid address");
        _;
    }

    // Get the owner of an identity
    function identityOwner(address identity) public view returns (address) {
        return identities[identity].owner;
    }

    // Change the owner of an identity
    function changeOwner(address identity, address newOwner)
        public
        onlyIdentityOwner(identity)
        validAddress(newOwner)
    {
        address previousOwner = identities[identity].owner;
        identities[identity].owner = newOwner;
        emit OwnershipChanged(identity, previousOwner, newOwner);
    }

    // Change owner using an EIP-712 signature
    function changeOwnerSigned(
        address identity,
        address newOwner,
        bytes memory signature
    ) public validAddress(newOwner) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(
                keccak256("ChangeOwner(address identity,address newOwner)"),
                identity,
                newOwner
            ))
        );
        address signer = ECDSAUpgradeable.recover(digest, signature);
        require(signer == identities[identity].owner, "Invalid signature");

        address previousOwner = identities[identity].owner;
        identities[identity].owner = newOwner;
        emit OwnershipChanged(identity, previousOwner, newOwner);
    }

    // Revoke ownership of an identity
    function revokeOwner(address identity) public onlyIdentityOwner(identity) {
        address previousOwner = identities[identity].owner;
        delete identities[identity];
        emit OwnershipRevoked(identity, previousOwner);
    }

    // Set a recovery address for an identity
    function setRecoveryAddress(address identity, address recoveryAddress, uint256 expiration)
        public
        onlyIdentityOwner(identity)
        validAddress(recoveryAddress)
    {
        require(expiration > block.timestamp, "Expiration must be in the future");
        identities[identity].recoveryAddress = recoveryAddress;
        identities[identity].recoveryExpiration = expiration;
        emit RecoveryAddressSet(identity, recoveryAddress, expiration);
    }

    // Recover ownership using a recovery address
    function recoverOwnership(address identity) public {
        IdentityData memory data = identities[identity];
        require(data.recoveryAddress == msg.sender, "Invalid recovery address");
        require(data.recoveryExpiration >= block.timestamp, "Recovery period expired");

        address previousOwner = data.owner;
        identities[identity].owner = msg.sender;
        emit OwnershipChanged(identity, previousOwner, msg.sender);
    }

    // Resolve a cross-chain DID
    function resolveCrossChainDID(bytes memory crossChainData) public returns (address) {
        address resolvedAddress = abi.decode(crossChainData, (address));
        emit CrossChainDIDResolved(resolvedAddress, crossChainData);
        return resolvedAddress;
    }

    // Set metadata for an identity
    function setMetadata(address identity, string memory key, string memory value)
        public
        onlyIdentityOwner(identity)
    {
        identityMetadata[identity][key] = value;
        emit MetadataUpdated(identity, key, value);
    }

    // Get metadata for an identity
    function getMetadata(address identity, string memory key) public view returns (string memory) {
        return identityMetadata[identity][key];
    }
}
