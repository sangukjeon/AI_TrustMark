// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Anchors regulation/policy documents used as grading evidence.
///         Documents are chunked off-chain; only the Merkle root of the chunks
///         is written on-chain, so any single chunk can later be proven to
///         belong to a specific, timestamped document version.
contract DocumentRegistry {
    struct Document {
        bytes32 merkleRoot;
        address submitter;
        uint256 timestamp;
        string uri; // IPFS CID or other off-chain pointer to the full document
    }

    mapping(bytes32 => Document) public documents; // documentId => Document
    mapping(bytes32 => bytes32[]) public serviceDocuments; // serviceId => documentId[]

    event DocumentRegistered(
        bytes32 indexed documentId,
        bytes32 indexed serviceId,
        bytes32 merkleRoot,
        string uri
    );

    function registerDocument(
        bytes32 serviceId,
        bytes32 merkleRoot,
        string calldata uri
    ) external returns (bytes32 documentId) {
        require(merkleRoot != bytes32(0), "DocumentRegistry: empty root");

        documentId = keccak256(
            abi.encodePacked(serviceId, merkleRoot, block.timestamp, msg.sender)
        );
        require(documents[documentId].timestamp == 0, "DocumentRegistry: duplicate");

        documents[documentId] = Document({
            merkleRoot: merkleRoot,
            submitter: msg.sender,
            timestamp: block.timestamp,
            uri: uri
        });
        serviceDocuments[serviceId].push(documentId);

        emit DocumentRegistered(documentId, serviceId, merkleRoot, uri);
    }

    /// @notice Verifies that `leaf` (a hashed document chunk) belongs to the
    ///         Merkle tree committed for `documentId`.
    function verifyChunk(
        bytes32 documentId,
        bytes32 leaf,
        bytes32[] calldata proof
    ) external view returns (bool) {
        bytes32 computed = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 sibling = proof[i];
            computed = computed < sibling
                ? keccak256(abi.encodePacked(computed, sibling))
                : keccak256(abi.encodePacked(sibling, computed));
        }
        return computed == documents[documentId].merkleRoot;
    }

    function getServiceDocuments(bytes32 serviceId) external view returns (bytes32[] memory) {
        return serviceDocuments[serviceId];
    }
}
