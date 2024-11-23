// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract DelegatesManagement is Initializable, AccessControlUpgradeable {
    struct DelegateDetails {
        bytes32 delegateType;
        uint validity; // Timestamp until the delegate is valid
        bool exists;   // Used for quick lookup
    }

    mapping(address => mapping(address => DelegateDetails)) private _delegates; // identity => (delegate => details)
    mapping(address => uint256) private _nonces; // Replay protection for signatures
    mapping(address => mapping(address => uint256)) private _permissions; // identity => (delegate => permissions)

    // Access control roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant DELEGATE_MANAGER_ROLE = keccak256("DELEGATE_MANAGER_ROLE");

    // Events
    event DelegateAdded(address indexed identity, bytes32 delegateType, address delegate, uint validity, address actor);
    event DelegateRevoked(address indexed identity, bytes32 delegateType, address delegate, address actor);
    event PermissionsUpdated(address indexed identity, address delegate, uint256 permissions);

    /// @notice Initialize the contract and setup roles
    function initialize() public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); // The deployer is the default admin
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(DELEGATE_MANAGER_ROLE, msg.sender);
    }

    /// @notice Check if a delegate is valid
    function validDelegate(
        address identity,
        bytes32 delegateType,
        address delegate
    ) external view returns (bool) {
        DelegateDetails memory details = _delegates[identity][delegate];
        return details.exists && details.delegateType == delegateType && details.validity > block.timestamp;
    }

    /// @notice Add a delegate with an actor's authorization
    function addDelegate(
        address identity,
        address actor,
        bytes32 delegateType,
        address delegate,
        uint validity
    ) external onlyRole(DELEGATE_MANAGER_ROLE) {
        _addDelegate(identity, delegateType, delegate, validity, actor);
    }

    /// @notice Add a delegate directly (admin only)
    function addDelegate(
        address identity,
        bytes32 delegateType,
        address delegate,
        uint validity
    ) external onlyRole(ADMIN_ROLE) {
        _addDelegate(identity, delegateType, delegate, validity, msg.sender);
    }

    /// @notice Add a delegate with an off-chain signature
    function addDelegateSigned(
        address identity,
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS,
        bytes32 delegateType,
        address delegate,
        uint validity
    ) external {
        uint256 nonce = _nonces[identity];
        bytes32 hash = keccak256(abi.encodePacked(identity, nonce, delegateType, delegate, validity));
        address signer = ecrecover(hash, sigV, sigR, sigS);
        require(signer == identity, "Invalid signature");

        _nonces[identity]++;
        _addDelegate(identity, delegateType, delegate, validity, signer);
    }

    /// @notice Revoke a delegate with an actor's authorization
    function revokeDelegate(
        address identity,
        address actor,
        bytes32 delegateType,
        address delegate
    ) external onlyRole(DELEGATE_MANAGER_ROLE) {
        _revokeDelegate(identity, delegateType, delegate, actor);
    }

    /// @notice Revoke a delegate directly (admin only)
    function revokeDelegate(
        address identity,
        bytes32 delegateType,
        address delegate
    ) external onlyRole(ADMIN_ROLE) {
        _revokeDelegate(identity, delegateType, delegate, msg.sender);
    }

    /// @notice Revoke a delegate with an off-chain signature
    function revokeDelegateSigned(
        address identity,
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS,
        bytes32 delegateType,
        address delegate
    ) external {
        bytes32 hash = keccak256(abi.encodePacked(identity, delegateType, delegate));
        address signer = ecrecover(hash, sigV, sigR, sigS);
        require(signer == identity, "Invalid signature");

        _revokeDelegate(identity, delegateType, delegate, signer);
    }

    /// @notice Batch add delegates
    function batchAddDelegates(
        address identity,
        bytes32[] memory delegateTypes,
        address[] memory delegatesList,
        uint[] memory validities
    ) external onlyRole(ADMIN_ROLE) {
        require(delegateTypes.length == delegatesList.length && delegateTypes.length == validities.length, "Input array lengths mismatch");

        for (uint256 i = 0; i < delegateTypes.length; i++) {
            _addDelegate(identity, delegateTypes[i], delegatesList[i], validities[i], msg.sender);
        }
    }

    /// @notice Get the permissions of a delegate
    function getDelegatePermissions(address identity, address delegate) external view returns (uint256) {
        return _permissions[identity][delegate];
    }

    /// @notice Set permissions for a delegate
    function setDelegatePermissions(
        address identity,
        address delegate,
        uint256 permissions
    ) external onlyRole(ADMIN_ROLE) {
        _permissions[identity][delegate] = permissions;
        emit PermissionsUpdated(identity, delegate, permissions);
    }

    /// @notice Get the nonce for an identity
    function getNonce(address identity) external view returns (uint256) {
        return _nonces[identity];
    }

    /// @notice Internal function to add a delegate
    function _addDelegate(
        address identity,
        bytes32 delegateType,
        address delegate,
        uint validity,
        address actor
    ) internal {
        require(delegate != address(0), "Invalid delegate address");
        require(validity > 0, "Validity must be greater than 0");

        _delegates[identity][delegate] = DelegateDetails(delegateType, block.timestamp + validity, true);
        emit DelegateAdded(identity, delegateType, delegate, validity, actor);
    }

    /// @notice Internal function to revoke a delegate
    function _revokeDelegate(
        address identity,
        bytes32 delegateType,
        address delegate,
        address actor
    ) internal {
        require(_delegates[identity][delegate].exists, "Delegate does not exist");
        delete _delegates[identity][delegate];
        emit DelegateRevoked(identity, delegateType, delegate, actor);
    }
}
