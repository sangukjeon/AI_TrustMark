# Contracts

Five contracts split by responsibility so no single contract (or single admin key) controls the whole certification lifecycle. All verified to compile cleanly with `solc 0.8.24` (`npx solc@0.8.24 --bin --abi contracts/*.sol`), no external dependencies required to compile — `Ownable.sol` is a small self-contained access-control base instead of pulling in OpenZeppelin, so the contracts have zero install step to try out.

| Contract | Role |
|---|---|
| [`DocumentRegistry.sol`](DocumentRegistry.sol) | Anchors a Merkle root per regulation-document version; `verifyChunk` proves a single chunk belongs to that version. |
| [`QuestionBank.sol`](QuestionBank.sol) | Commit-reveal for question sets — the grading questions are committed as a hash before the audit runs, and revealed (with proof) only afterward, so they can't leak or be gamed in advance. |
| [`AuditorRegistry.sol`](AuditorRegistry.sol) | Allow-list of independent auditor servers and their signing keys. `owner` is meant to be a Safe multisig in production. |
| [`AuditAnchor.sol`](AuditAnchor.sol) | Confirms grading by majority vote among registered auditors, and anchors batches of off-chain message/session hashes (chat logs, appeal transcripts) as one Merkle root per epoch — so a whole day of chat doesn't need one transaction per message. |
| [`Certification.sol`](Certification.sol) | Holds each service's grade, expiry, and appeal history. Only `AuditAnchor` can issue, revoke, or resolve an appeal, so every state change traces back to an on-chain vote. |

## Try it without installing anything

```bash
npx solc@0.8.24 --bin --abi contracts/Ownable.sol contracts/DocumentRegistry.sol \
  contracts/QuestionBank.sol contracts/AuditorRegistry.sol contracts/AuditAnchor.sol \
  contracts/Certification.sol -o build
```

## Hardhat (for tests / deployment)

```bash
npm install
npx hardhat compile
```

`hardhat.config.js` is pre-wired for Base Sepolia — set `BASE_SEPOLIA_RPC_URL` and `DEPLOYER_PRIVATE_KEY` as environment variables before deploying.

## What's not here yet

- Deploy scripts and a wiring script (`AuditorRegistry` → `AuditAnchor` → `Certification`)
- Unit tests
- EAS (Ethereum Attestation Service) schema + attestation call from `AuditAnchor`
- Safe multisig setup for `owner`
