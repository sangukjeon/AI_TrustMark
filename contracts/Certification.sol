// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Tracks certification grade, expiry and appeal history per AI
///         service. Only the AuditAnchor contract can issue, revoke or
///         resolve appeals, so a certificate's state always traces back to
///         an on-chain auditor vote.
contract Certification {
    enum Grade {
        None,
        A,
        B,
        C,
        D,
        Revoked
    }

    struct Cert {
        Grade grade;
        uint256 issuedAt;
        uint256 expiresAt;
        bytes32 auditCaseId;
        uint256 appealCount;
    }

    mapping(bytes32 => Cert) public certificates; // serviceId => Cert
    address public auditAnchor;

    event Certified(bytes32 indexed serviceId, Grade grade, uint256 expiresAt, bytes32 auditCaseId);
    event Revoked(bytes32 indexed serviceId, bytes32 auditCaseId);
    event AppealFiled(bytes32 indexed serviceId, bytes32 indexed appealId, bytes32 evidenceHash);
    event AppealResolved(bytes32 indexed serviceId, bytes32 indexed appealId, bool overturned, Grade newGrade);

    modifier onlyAuditAnchor() {
        require(msg.sender == auditAnchor, "Certification: not authorized");
        _;
    }

    constructor(address auditAnchorAddress) {
        auditAnchor = auditAnchorAddress;
    }

    function issue(
        bytes32 serviceId,
        Grade grade,
        uint256 validityDays,
        bytes32 auditCaseId
    ) external onlyAuditAnchor {
        require(grade != Grade.None && grade != Grade.Revoked, "Certification: invalid grade");
        uint256 expiresAt = block.timestamp + validityDays * 1 days;

        certificates[serviceId] = Cert({
            grade: grade,
            issuedAt: block.timestamp,
            expiresAt: expiresAt,
            auditCaseId: auditCaseId,
            appealCount: certificates[serviceId].appealCount // carry over appeal history
        });

        emit Certified(serviceId, grade, expiresAt, auditCaseId);
    }

    function revoke(bytes32 serviceId, bytes32 auditCaseId) external onlyAuditAnchor {
        certificates[serviceId].grade = Grade.Revoked;
        certificates[serviceId].auditCaseId = auditCaseId;
        emit Revoked(serviceId, auditCaseId);
    }

    function fileAppeal(bytes32 serviceId, bytes32 appealId, bytes32 evidenceHash) external {
        certificates[serviceId].appealCount++;
        emit AppealFiled(serviceId, appealId, evidenceHash);
    }

    function resolveAppeal(
        bytes32 serviceId,
        bytes32 appealId,
        bool overturned,
        Grade newGrade
    ) external onlyAuditAnchor {
        if (overturned) {
            certificates[serviceId].grade = newGrade;
        }
        emit AppealResolved(serviceId, appealId, overturned, newGrade);
    }

    function isValid(bytes32 serviceId) external view returns (bool) {
        Cert memory c = certificates[serviceId];
        return c.grade != Grade.None && c.grade != Grade.Revoked && block.timestamp <= c.expiresAt;
    }
}
