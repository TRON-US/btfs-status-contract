// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";


// MerkleDistributor for airdrop to BTFS staker
contract BtfsStatus {
    using SafeMath for uint256;

    // map[peer]info
    struct info {
        uint32 createTime;
        string version;
        uint16 lastNum;
        uint32 lastTime;
        uint8[30] hearts;
    }
    mapping(string => info) private peerMap;

    // sign address
    address public currentSignAddress = 0x22df207EC3C8D18fEDeed87752C5a68E5b4f6FbD;

    // version
    string public currentVersion;

    event signAddressChanged(address lastSignAddress, address currentSignAddress);
    event versionChanged(string currentVersion, string version);
    event statusReported(string peer, uint32 createTime, string version, uint16 num, uint32 nowTime, address bttcAddress, uint8[30] hearts);

    // stat
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

    // set current version, only owner do it
    function setSignAddress(address addr) external {
        emit signAddressChanged(currentSignAddress, addr);
        currentSignAddress = addr;
    }

    // set current version, only owner do it
    function setCurrentVersion(string memory ver) external {
        emit versionChanged(currentVersion, ver);
        currentVersion = ver;
    }

    // get host when score = 8.0
    function getHighScoreHost() external returns(info[] memory) {}

    function getStatus(string memory peer) external view returns(string memory, uint32, string memory, uint16, uint32, uint8[30] memory) {
        if (peerMap[peer].lastNum == 0) {
            uint8[30] memory hearts;
            return ("", 0, "", 0, 0, hearts);
        } else {
            // uint32 createTime;
            // string version;
            // uint16 num;
            // uint8[30] hearts;
            // uint16 lastNum;
            // uint32 lastTime;
            return (peer, peerMap[peer].createTime, peerMap[peer].version, peerMap[peer].lastNum, peerMap[peer].lastTime, peerMap[peer].hearts);
        }
    }


    // set heart, max idle days = 10
    function setHeart(string memory peer, uint16 num, uint32 nowTime) internal {
        uint256 diffTime = nowTime - peerMap[peer].lastTime;
        if (diffTime > 10 * 86400) {
            diffTime = 10 * 86400;
        }

        uint256 diffNum = num - peerMap[peer].lastNum;
        if (diffNum > 10 * 24) {
            diffNum = 10 * 24;
        }

        uint diffDays = diffTime / 86400;
        uint256 balanceNum = diffNum;
        for (uint256 i = 1; i < diffDays; i++) {
            uint indexTmp = (nowTime - i * 86400) % 86400 % 30;
            peerMap[peer].hearts[indexTmp] = uint8(diffNum/diffDays);

            balanceNum = balanceNum - diffNum/diffDays;
        }

        uint index = nowTime % 86400 % 30;
        peerMap[peer].hearts[index] = uint8(balanceNum);
    }

    function reportStatus(string memory peer, uint32 createTime, string memory version, uint16 num, address bttcAddress, bytes memory signed) external payable {
        require(0 < createTime, "reportStatus: Invalid createTime");
        require(0 < num, "reportStatus: Invalid num");
        require(0 < signed.length, "reportStatus: Invalid signed");
        require(peerMap[peer].lastNum <= num, "reportStatus: Invalid lastNum<num");

        // verify input param with the signed data.
        // bytes32 hash = keccak256(abi.encode(peer, createTime, version, num, bttcAddress));
        // require(verify(hash, signed), "reportStatus: Invalid signed address.");

        // // check bttcAddress and sender
        // require(bttcAddress == msg.sender, "reportStatus: Invalid signed");
        // return;

        uint32 nowTime = uint32(block.timestamp);
        uint index = nowTime % 86400 % 30;

        peerMap[peer].createTime = createTime;
        peerMap[peer].version = version;
        peerMap[peer].lastNum = num;
        peerMap[peer].lastTime = nowTime;

        // first report
        if (peerMap[peer].lastNum == 0) {
            if (num > 24) {
                num = 24;
            }

            uint8[30] memory hearts;
            peerMap[peer].hearts = hearts;
            peerMap[peer].hearts[index] = uint8(num);

            totalStat.totalUsers += 1;
        } else {
            // if (nowTime - peerMap[peer].lastTime < 86400){
            //     return;
            // }

            setHeart(peer, num, nowTime);
        }

        return;

        // set total
        totalStat.total += 1;

        emitStatusReported(
            peer,
            createTime,
            version,
            num,
            nowTime,
            bttcAddress
        );
    }

    function emitStatusReported(string memory peer, uint32 createTime, string memory version, uint16 num, uint32 nowTime, address bttcAddress) internal {
        emit statusReported(
            peer,
            createTime,
            version,
            num,
            nowTime,
            bttcAddress,
            peerMap[peer].hearts
        );
    }

    function verify(bytes32 hash, bytes memory signed) internal view returns (bool) {
        return recoverSigner(hash, signed);
    }

    function recoverSigner(bytes32 hash, bytes memory sig) internal view returns (bool)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        return ecrecover(hash, v+27, r, s) == currentSignAddress;
    }

    function splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
        // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
        // second 32 bytes
            s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    // call from external
    function genHashExt(string memory peer, uint32 createTime, string memory version, uint16 num, address bttcAddress) external pure returns (bytes32) {
        return keccak256(abi.encode(peer, createTime, version, num, bttcAddress));
    }

    // call from external
    function recoverSignerExt(bytes32 hash, bytes memory sig) external view returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        address addr1 = ecrecover(hash, v+27, r, s);
        require(addr1 == currentSignAddress, "reportStatus: xxx");

        return addr1;
    }
}