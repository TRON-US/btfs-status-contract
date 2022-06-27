// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";


// MerkleDistributor for airdrop to BTFS staker
contract BtfsStatus {
    using SafeMath for uint256;

    // info
    struct info {
        uint256 createTime;
        bytes16 version;
        uint256 num;
        uint8[] hearts;
        uint256 lastNum;
        uint256 lastTime;
    }
    // which peer, last info
    mapping(string => info) private peerMap;

    //version
    bytes16 public currentVersion;

    event versionChanged(bytes16 currentVersion, bytes16 version);
    event statusReported(string peer, uint256 createTime, bytes16 version, uint256 num, uint256 nowTime, uint8[] hearts);

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
    // only owner do it
    function setCurrentVersion(bytes16 ver) external {
        bytes16 lastVersion = currentVersion;

        currentVersion = ver;
        emit versionChanged(lastVersion, currentVersion);
    }


    function setHeart(string memory peer, uint256 num, uint256 nowTime) internal {
        uint256 diffTime = nowTime - peerMap[peer].lastTime;
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
            uint indexTmp = (nowTime-i*86400)%86400%30;
            peerMap[peer].hearts[indexTmp] = uint8(diffNum/times);

            balance = balance - diffNum/times;
        }

        uint index = nowTime%86400%30;
        peerMap[peer].hearts[index] = uint8(balance);
    }

    function reportStatus(string memory peer, uint256 createTime, bytes16 version, uint256 num, uint256 nowTime, bytes32 signed) external {
        require(0 < createTime, "reportStatus: Invalid createTime");
        require(0 < version.length, "reportStatus: Invalid version.length");
        require(0 < num, "reportStatus: Invalid num");
        require(0 < signed.length, "reportStatus: Invalid signed");

        require(peerMap[peer].lastNum <= num, "reportStatus: Invalid lastNum<num");

        // Verify the signed with msg.sender.
        bytes32 node = keccak256(abi.encodePacked(peer, createTime, version, num, nowTime));
        require(verify(signed, node), "reportStatus: Invalid signed.");

        uint index = nowTime%86400%30;
        peerMap[peer].createTime = createTime;
        peerMap[peer].version = version;
        peerMap[peer].lastNum = num;

        if (peerMap[peer].num == 0) {
            if (num > 24) {
                num = 24;
            }
            peerMap[peer].hearts[index] = uint8(num);
            totalStat.totalUsers += 1;
        } else {
            setHeart(peer, num, nowTime);
        }

        // set total
        totalStat.total += 1;

        emit statusReported(
            peer,
            createTime,
            version,
            num,
            nowTime,
            peerMap[peer].hearts
        );
    }

    function verify(bytes32 signed, bytes32 node) internal pure returns (bool) {
        return true;
    }
}