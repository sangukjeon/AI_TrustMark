// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./AuditorRegistry.sol";

/// @notice Confirms grading results by majority vote among independent auditors
///         and anchors batches of off-chain message/session hashes (chat logs,
///         appeal transcripts) as periodic Merkle roots, so verification never
///         needs one transaction per message.
contract AuditAnchor {
    AuditorRegistry public immutable auditorRegistry;

    struct AuditCase {
        bytes32 serviceId;
        bytes32 questionSetId;
        uint256 totalAuditors;
        uint256 approveCount;
        uint256 rejectCount;
        bool finalized;
        bool approved;
        bytes32 resultHash; // hash of the aggregated scores + evidence bundle
    }

    mapping(bytes32 => AuditCase) public cases; // caseId => AuditCase
    mapping(bytes32 => mapping(address => bool)) public hasVoted;

    mapping(uint256 => bytes32) public batchRoots; // epoch => merkleRoot of anchored hashes
    uint256 public currentEpoch;

    event CaseOpened(
        bytes32 indexed caseId,
        bytes32 indexed serviceId,
        bytes32 questionSetId,
        uint256 totalAuditors
    );
    event Voted(bytes32 indexed caseId, address indexed auditor, bool approve, bytes32 evidenceHash);
    event CaseFinalized(bytes32 indexed caseId, bool approved, bytes32 resultHash);
    event BatchAnchored(uint256 indexed epoch, bytes32 merkleRoot, string label);

    constructor(address auditorRegistryAddress) {
        auditorRegistry = AuditorRegistry(auditorRegistryAddress);
    }

    function openCase(
        bytes32 caseId,
        bytes32 serviceId,
        bytes32 questionSetId,
        uint256 totalAuditors
    ) external {
        require(cases[caseId].totalAuditors == 0, "AuditAnchor: case exists");
        require(totalAuditors > 0, "AuditAnchor: no auditors");

        cases[caseId] = AuditCase({
            serviceId: serviceId,
            questionSetId: questionSetId,
            totalAuditors: totalAuditors,
            approveCount: 0,
            rejectCount: 0,
            finalized: false,
            approved: false,
            resultHash: bytes32(0)
        });

        emit CaseOpened(caseId, serviceId, questionSetId, totalAuditors);
    }

    function vote(bytes32 caseId, bool approve, bytes32 evidenceHash) external {
        require(auditorRegistry.isActiveAuditor(msg.sender), "AuditAnchor: not an active auditor");

        AuditCase storage c = cases[caseId];
        require(c.totalAuditors != 0, "AuditAnchor: unknown case");
        require(!c.finalized, "AuditAnchor: already finalized");
        require(!hasVoted[caseId][msg.sender], "AuditAnchor: already voted");

        hasVoted[caseId][msg.sender] = true;
        if (approve) {
            c.approveCount++;
        } else {
            c.rejectCount++;
        }

        emit Voted(caseId, msg.sender, approve, evidenceHash);

        if (c.approveCount + c.rejectCount == c.totalAuditors) {
            c.finalized = true;
            c.approved = c.approveCount * 2 > c.totalAuditors; // simple majority
            c.resultHash = keccak256(
                abi.encodePacked(caseId, c.approveCount, c.rejectCount, block.timestamp)
            );
            emit CaseFinalized(caseId, c.approved, c.resultHash);
        }
    }

    /// @notice Anchors one Merkle root covering many off-chain message/session
    ///         hashes for a given period (e.g. an hourly chat-log batch).
    function anchorBatch(bytes32 merkleRoot, string calldata label) external returns (uint256 epoch) {
        require(merkleRoot != bytes32(0), "AuditAnchor: empty root");
        epoch = currentEpoch++;
        batchRoots[epoch] = merkleRoot;
        emit BatchAnchored(epoch, merkleRoot, label);
    }
}
