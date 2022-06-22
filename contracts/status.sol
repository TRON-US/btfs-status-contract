// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";


// MerkleDistributor for airdrop to BTFS staker
contract BtfsStatus {
    using SafeMath for uint256;

    // info
    struct info {
        uint256 createTime;
        uint256 version;
        uint256 num;
        bytes32 hearts;
        uint256 lastNum;
        uint256 lastTime;
    }
    // which peer, last info
    mapping(string => info) private peerMap;

    //version
    bytes16 public currentVersion;

    event versionChanged(bytes16 currentVersion, bytes16 version);
    event statusReported(bytes32 merkleRootInput, uint256 index, address account, uint256 amount);

    //stat
    struct statistics {
        uint64 total;
        uint64 totalUsers;
    }
    statistics  public totalStat;


    // owner
    address public owner;
    constructor() {
        owner = msg.sender;
    }


    // set current version
    function setCurrentVersion(bytes16 version) external onlyOwner {
        bytes16 lastVersion = currentVersion;

        currentVersion = version;
        emit versionChanged(lastVersion, currentVersion);
    }


    function setHeart(string memory peer, uint256 num, uint256 now) internal {
        require(0 < num, "claim: Invalid num");
        require(peerMap[peer].lastNum <= num, "claim: Invalid lastNum<num");
        require(0 < createTime, "claim: Invalid createTime");
        require(0 < heart, "claim: Invalid heart");


        uint256 diffTime = now - peerMap[peer].lastTime;
        if (diffTime > 30 * 86400) {
            diffTime = 30 * 86400;
        }

        uint256 diffNum = num - peerMap[peer].lastNum;
        if (diffNum > 30) {
            diffNum = 30;
        }

        uint times = diffTime/86400;
        uint256 balance = diffNum;
        for (uint256 i = 1; i < times; i++) {
            indexTmp = (now - i*86400)%86400%30;
            peerMap[peer].hearts[indexTmp] = diff/times;

            balance = balance - diff/times;
        }
        peerMap[peer].hearts[index] = balance;
    }

    function reportStatus(string memory peer, uint256 createTime, bytes16 version, uint256 num, uint256 now, bytes32 signed) external {
        require(0 < num, "reportStatus: Invalid num");
        require(0 < createTime, "reportStatus: Invalid createTime");
        require(0 < heart, "reportStatus: Invalid heart");

        require(peerMap[peer].lastNum <= num, "reportStatus: Invalid lastNum<num");

        // Verify the signed with msg.sender.
        bytes32 node = keccak256(abi.encodePacked(peer, createTime, version, num, now));
        require(verify(signed, node), "reportStatus: Invalid signed.");

        uint index = now%86400%30;
        peerMap[peer].createTime = createTime;
        peerMap[peer].version = version;
        peerMap[peer].lastNum = num;

        if (peerMap[peer].num == 0) {
            peerMap[peer].hearts[index] = num;
            totalStat.totalUsers += 1;
        } else {
            setHeart(peer, num, now);
        }

        // set total
        totalStat.total += 1;

        emit statusReported(
                peerMap[peer].createTime,
                peerMap[peer].version,
                peerMap[peer].lastNum,
                peerMap[peer].hearts
        );
    }

    function verify(bytes32 signed, bytes32 node) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }

}