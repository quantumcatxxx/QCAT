List of Functions

	1.	identityOwner(address identity) public view returns(address)
	2.	checkSignature(address identity, uint8 sigV, bytes32 sigR, bytes32 sigS, bytes32 hash) internal returns(address)
	3.	validDelegate(address identity, bytes32 delegateType, address delegate) public view returns(bool)
	4.	changeOwner(address identity, address actor, address newOwner) internal
	5.	changeOwner(address identity, address newOwner) public
	6.	changeOwnerSigned(address identity, uint8 sigV, bytes32 sigR, bytes32 sigS, address newOwner) public
	7.	addDelegate(address identity, address actor, bytes32 delegateType, address delegate, uint validity) internal
	8.	addDelegate(address identity, bytes32 delegateType, address delegate, uint validity) public
	9.	addDelegateSigned(address identity, uint8 sigV, bytes32 sigR, bytes32 sigS, bytes32 delegateType, address delegate, uint validity) public
	10.	revokeDelegate(address identity, address actor, bytes32 delegateType, address delegate) internal
	11.	revokeDelegate(address identity, bytes32 delegateType, address delegate) public
	12.	revokeDelegateSigned(address identity, uint8 sigV, bytes32 sigR, bytes32 sigS, bytes32 delegateType, address delegate) public
	13.	setAttribute(address identity, address actor, bytes32 name, bytes memory value, uint validity) internal
	14.	setAttribute(address identity, bytes32 name, bytes memory value, uint validity) public
	15.	setAttributeSigned(address identity, uint8 sigV, bytes32 sigR, bytes32 sigS, bytes32 name, bytes memory value, uint validity) public
	16.	revokeAttribute(address identity, address actor, bytes32 name, bytes memory value) internal
	17.	revokeAttribute(address identity, bytes32 name, bytes memory value) public
	18.	revokeAttributeSigned(address identity, uint8 sigV, bytes32 sigR, bytes32 sigS, bytes32 name, bytes memory value) public
	19.	deactivateDID(address identity) public
	20.	reactivateDID(address identity, address newOwner) public
	21.	getAttributes(address identity, bytes32 name) public view returns (bytes memory)
	22.	getHistory(address identity) public view returns (bytes32[] memory)
	23.	executeMultiSigAction(address identity, address[] memory signers, uint8[] memory sigVs, bytes32[] memory sigRs, bytes32[] memory sigSs, bytes32 actionHash) public
	24.	getActiveDelegates(address identity) public view returns (address[] memory)
	25.	setMetadataHash(address identity, bytes32 hash) public
	26.	getMetadataHash(address identity) public view returns (bytes32)
	27.	rotateKeys(address identity, address newKey) public
	28.	isAttributeValid(address identity, bytes32 name) public view returns (bool)
	29.	batchAddDelegates(address identity, bytes32[] memory delegateTypes, address[] memory delegatesList, uint[] memory validities) public
	30.	revokeOwner(address identity) public
	31.	hasExpired(uint timestamp) public view returns (bool);
	32.	listAttributes(address identity) public view returns (bytes32[] memory);
	33.	listDelegates(address identity, bytes32 delegateType) public view returns (address[] memory);
	34.	transferOwnershipViaDelegate(address identity, address newOwner) public;
	35.	resolveDID(address identity) public view returns (address owner, bytes32[] memory attributes, address[] memory delegates);
	36.	registerBatch(address[] memory identities, bytes32[] memory metadataHashes) public;
	37.	emitAuditLog(address identity, string memory action) internal;
	38.	recoverOwnership(address identity, address recoveryAddress) public;
	39.	setDelegatePermissions(address identity, address delegate, uint256 permissions) public;
	40.	assignRole(address identity, address actor, string memory role) public;
	41.	getRole(address identity, address actor) public view returns (string memory);
	42.	notifyExpiry(address identity, bytes32 name) public;
	43.	anchorOnChain(address identity, bytes32 dataHash) public;
	44.	resolveCrossChainDID(bytes memory crossChainData) public view returns (address owner);
	45.	selfDestructDID(address identity) public;
	46.	setFee(uint operation, uint fee) public;
	47.	getFee(uint operation) public view returns (uint);
