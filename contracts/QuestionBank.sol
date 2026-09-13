// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Commit-reveal storage for question sets so graded questions/answers
///         cannot leak before an audit runs, while still being provable
///         after the fact once the reveal is published.
contract QuestionBank {
    enum Status {
        None,
        Committed,
        Revealed
    }

    struct QuestionSet {
        bytes32 commitHash; // keccak256(revealRoot, salt, rawQuestionsURI)
        bytes32 revealRoot; // Merkle root of the revealed questions+answers, set at reveal time
        address creator;
        uint256 committedAt;
        uint256 revealedAt;
        Status status;
    }

    mapping(bytes32 => QuestionSet) public questionSets; // setId => QuestionSet
    mapping(bytes32 => bool) public usedCommitHash; // prevents copy-pasting someone else's commit

    event Committed(bytes32 indexed setId, address indexed creator, bytes32 commitHash);
    event Revealed(bytes32 indexed setId, bytes32 revealRoot, string rawQuestionsURI);

    function commit(bytes32 setId, bytes32 commitHash) external {
        require(questionSets[setId].status == Status.None, "QuestionBank: already committed");
        require(!usedCommitHash[commitHash], "QuestionBank: hash reused");

        questionSets[setId] = QuestionSet({
            commitHash: commitHash,
            revealRoot: bytes32(0),
            creator: msg.sender,
            committedAt: block.timestamp,
            revealedAt: 0,
            status: Status.Committed
        });
        usedCommitHash[commitHash] = true;

        emit Committed(setId, msg.sender, commitHash);
    }

    /// @param rawQuestionsURI IPFS pointer to the plaintext questions, published only after grading.
    function reveal(
        bytes32 setId,
        bytes32 revealRoot,
        bytes32 salt,
        string calldata rawQuestionsURI
    ) external {
        QuestionSet storage q = questionSets[setId];
        require(q.status == Status.Committed, "QuestionBank: not committed");
        require(q.creator == msg.sender, "QuestionBank: not creator");
        require(
            keccak256(abi.encodePacked(revealRoot, salt, rawQuestionsURI)) == q.commitHash,
            "QuestionBank: reveal mismatch"
        );

        q.revealRoot = revealRoot;
        q.revealedAt = block.timestamp;
        q.status = Status.Revealed;

        emit Revealed(setId, revealRoot, rawQuestionsURI);
    }

    function isRevealed(bytes32 setId) external view returns (bool) {
        return questionSets[setId].status == Status.Revealed;
    }
}
