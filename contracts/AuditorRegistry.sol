// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Ownable.sol";

/// @notice Allow-list of independent auditor servers and their signing keys.
///         `owner` is expected to be a Safe multisig in production so no
///         single admin can unilaterally add or remove auditors.
contract AuditorRegistry is Ownable {
    struct Auditor {
        address signer; // key the auditor server signs grading results with
        string endpoint; // off-chain API URL, for reference/discovery only
        bool active;
        uint256 registeredAt;
    }

    mapping(address => Auditor) public auditors; // auditorId => Auditor
    address[] public auditorList;

    event AuditorRegistered(address indexed auditorId, address signer, string endpoint);
    event AuditorStatusChanged(address indexed auditorId, bool active);
    event AuditorSignerRotated(address indexed auditorId, address oldSigner, address newSigner);

    constructor(address initialOwner) Ownable(initialOwner) {}

    function registerAuditor(
        address auditorId,
        address signer,
        string calldata endpoint
    ) external onlyOwner {
        require(auditors[auditorId].registeredAt == 0, "AuditorRegistry: already registered");
        require(signer != address(0), "AuditorRegistry: zero signer");

        auditors[auditorId] = Auditor({
            signer: signer,
            endpoint: endpoint,
            active: true,
            registeredAt: block.timestamp
        });
        auditorList.push(auditorId);

        emit AuditorRegistered(auditorId, signer, endpoint);
    }

    function setActive(address auditorId, bool active) external onlyOwner {
        require(auditors[auditorId].registeredAt != 0, "AuditorRegistry: unknown auditor");
        auditors[auditorId].active = active;
        emit AuditorStatusChanged(auditorId, active);
    }

    function rotateSigner(address auditorId, address newSigner) external onlyOwner {
        require(auditors[auditorId].registeredAt != 0, "AuditorRegistry: unknown auditor");
        require(newSigner != address(0), "AuditorRegistry: zero signer");
        address old = auditors[auditorId].signer;
        auditors[auditorId].signer = newSigner;
        emit AuditorSignerRotated(auditorId, old, newSigner);
    }

    function isActiveAuditor(address auditorId) external view returns (bool) {
        return auditors[auditorId].active;
    }

    function auditorCount() external view returns (uint256) {
        return auditorList.length;
    }
}
