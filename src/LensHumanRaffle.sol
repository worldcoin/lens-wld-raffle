// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {HumanCheck} from "world-id-lens/HumanCheck.sol";

contract LensHumanRaffle {
    error RaffleEnded();
    error RaffleRunning();
    error InvalidProfile();

    event EndedRaffle(uint256[] winners);
    event JoinedRaffle(uint256 indexed profileId);

    uint256 internal seed;
    uint256[] public winners;
    uint256 public immutable endsAt;
    uint256 public participantCount;
    ERC721 public immutable lensNft;
    uint256 public immutable numWinners;
    HumanCheck public immutable humanCheck;

    mapping(uint256 => bool) public isParticipating;
    mapping(uint256 => uint256) public getParticipant;

    constructor(
        ERC721 _lensNft,
        HumanCheck _humanCheck,
        uint256 _numWinners,
        uint256 _endsAt
    ) {
        endsAt = _endsAt;
        lensNft = _lensNft;
        humanCheck = _humanCheck;
        numWinners = _numWinners;
    }

    function enter(uint256 profileId) public {
        if (
            isParticipating[profileId] ||
            lensNft.ownerOf(profileId) != msg.sender ||
            !humanCheck.isVerified(profileId)
        ) revert InvalidProfile();

        isParticipating[profileId] = true;
        getParticipant[participantCount++] = profileId;
        seed ^= uint256(keccak256(abi.encodePacked(seed, profileId)));

        emit JoinedRaffle(profileId);
    }

    function settle() public {
        if (endsAt > block.timestamp) revert RaffleRunning();

        for (uint256 i = 0; i < numWinners; i++) {
            winners.push(getParticipant[seed % participantCount]);

            seed ^= uint256(keccak256(abi.encodePacked(seed, i)));
        }

        emit EndedRaffle(winners);
    }
}
