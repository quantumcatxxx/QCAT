// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AttributesManagement is Initializable, AccessControl, ReentrancyGuard {
    struct Attribute {
        bytes value;
        uint validity; // Expiry timestamp
        bool exists;   // To check if the attribute exists
    }

    mapping(address => mapping(bytes32 => Attribute)) private attributes;
    mapping(address => bytes32[]) private attributeKeys; // To track attribute names for an identity

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ACTOR_ROLE = keccak256("ACTOR_ROLE");

    event AttributeSet(address indexed identity, bytes32 name, bytes value, uint validity);
    event AttributeRevoked(address indexed identity, bytes32 name, bytes value);
    event AttributeExpired(address indexed identity, bytes32 name);

    // Initialize the contract (for upgradability)
    function initialize(address admin) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(ADMIN_ROLE, admin);
    }

    // Modifier for access control
    modifier onlySelfOrActor(address identity) {
        require(msg.sender == identity || hasRole(ACTOR_ROLE, msg.sender), "Not authorized");
        _;
    }

    // Set attribute for self or authorized actor
    function setAttribute(
        address identity,
        bytes32 name,
        bytes memory value,
        uint validity
    ) public onlySelfOrActor(identity) {
        _setAttribute(identity, name, value, validity);
    }

    // Revoke an attribute for self or authorized actor
    function revokeAttribute(
        address identity,
        bytes32 name,
        bytes memory value
    ) public onlySelfOrActor(identity) {
        require(attributes[identity][name].exists, "Attribute does not exist");
        require(keccak256(attributes[identity][name].value) == keccak256(value), "Invalid attribute value");

        delete attributes[identity][name];
        _removeAttributeKey(identity, name);
        emit AttributeRevoked(identity, name, value);
    }

    // Check if an attribute is valid
    function isAttributeValid(address identity, bytes32 name) public view returns (bool) {
        return attributes[identity][name].exists && attributes[identity][name].validity >= block.timestamp;
    }

    // Get an attribute value and validity
    function getAttributes(address identity, bytes32 name) public view returns (bytes memory, uint) {
        require(attributes[identity][name].exists, "Attribute does not exist");
        return (attributes[identity][name].value, attributes[identity][name].validity);
    }

    // Batch set attributes
    function setAttributesBatch(
        address identity,
        bytes32[] memory names,
        bytes[] memory values,
        uint[] memory validities
    ) public onlySelfOrActor(identity) {
        require(names.length == values.length && names.length == validities.length, "Input lengths mismatch");
        for (uint i = 0; i < names.length; i++) {
            _setAttribute(identity, names[i], values[i], validities[i]);
        }
    }

    // Internal function to set attributes
    function _setAttribute(
        address identity,
        bytes32 name,
        bytes memory value,
        uint validity
    ) internal {
        if (!attributes[identity][name].exists) {
            attributeKeys[identity].push(name); // Track new attribute
        }

        attributes[identity][name] = Attribute({
            value: value,
            validity: validity,
            exists: true
        });

        emit AttributeSet(identity, name, value, validity);
    }

    // Remove an attribute key
    function _removeAttributeKey(address identity, bytes32 name) internal {
        bytes32[] storage keys = attributeKeys[identity];
        for (uint i = 0; i < keys.length; i++) {
            if (keys[i] == name) {
                keys[i] = keys[keys.length - 1];
                keys.pop();
                break;
            }
        }
    }

    // List attributes with pagination
    function listAttributesPaginated(
        address identity,
        uint start,
        uint limit
    ) public view returns (bytes32[] memory) {
        uint total = attributeKeys[identity].length;
        require(start < total, "Start index out of bounds");

        uint end = start + limit > total ? total : start + limit;
        bytes32[] memory paginated = new bytes32[](end - start);

        for (uint i = start; i < end; i++) {
            paginated[i - start] = attributeKeys[identity][i];
        }

        return paginated;
    }

    // Notify expiry for an attribute
    function notifyExpiry(address identity, bytes32 name) public {
        require(attributes[identity][name].exists, "Attribute does not exist");
        if (attributes[identity][name].validity < block.timestamp) {
            emit AttributeExpired(identity, name);
        }
    }
}
