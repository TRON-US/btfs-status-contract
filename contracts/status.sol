// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// Open Zeppelin libraries for controlling upgradability and access.
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


// BtfsStatus for hosts' heartbeat report
contract BtfsStatus is Initializable, UUPSUpgradeable, OwnableUpgradeable{
    using SafeMath for uint256;

    // map[peer]info
    struct info {
        uint32 createTime;
        string version;
        uint32 lastNonce;
        uint32 lastTime;
        uint16[30] hearts;
    }
    mapping(string => info) private peerMap;

    // sign address
    address public currentSignAddress = 0x22df207EC3C8D18fEDeed87752C5a68E5b4f6FbD;

    // version
    string public currentVersion;

    event signAddressChanged(address lastSignAddress, address currentSignAddress);
    event versionChanged(string currentVersion, string version);
    event statusReported(string peer, uint32 createTime, string version, uint32 Nonce, uint32 nowTime, address bttcAddress, uint16[30] hearts);

    // stat
    struct statistics {
        uint64 total;
        uint64 totalUsers;
    }
    statistics  public totalStat;


//    constructor() {
//    }

    // initialize
    function initialize() public initializer {
        __Ownable_init();
    }

    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    // set current version, only owner do it
    function setSignAddress(address addr) public onlyOwner {
        emit signAddressChanged(currentSignAddress, addr);
        currentSignAddress = addr;
    }

    // set current version, only owner do it
    function setCurrentVersion(string memory ver) public onlyOwner {
        emit versionChanged(currentVersion, ver);
        currentVersion = ver;
    }

    // get host when score = 8.0
    function getHighScoreHost() external returns(info[] memory) {}

    function getStatus(string memory peer) external view returns(string memory, uint32, string memory, uint32, uint32, uint16[30] memory) {
        if (peerMap[peer].lastNonce == 0) {
            uint16[30] memory hearts;
            return ("", 0, "", 0, 0, hearts);
        } else {
            return (peer, peerMap[peer].createTime, peerMap[peer].version, peerMap[peer].lastNonce, peerMap[peer].lastTime, peerMap[peer].hearts);
        }
    }


    // set heart, max idle days = 10
    function setHeart(string memory peer, uint32 Nonce, uint32 nowTime) internal {
        uint256 diffTime = nowTime - peerMap[peer].lastTime;
        if (diffTime > 30 * 86400) {
            diffTime = 30 * 86400;
        }

        uint256 diffNonce = Nonce - peerMap[peer].lastNonce;
        if (diffNonce > 30 * 24) {
            diffNonce = 30 * 24;
        }

        uint diffDays = diffTime / 86400;
        uint256 balanceNum = diffNonce;


        // 1.set new (diffDays-1) average Nonce; (it is alse reset 0 for more than 30 days' diffDays)
        for (uint256 i = 1; i < diffDays; i++) {
            uint indexTmp = ((nowTime - i * 86400) / 86400) % 30;
            peerMap[peer].hearts[indexTmp] = uint8(diffNonce/diffDays);

            balanceNum = balanceNum - diffNonce/diffDays;
        }

        // 2.set today balanceNum
        uint index = (nowTime / 86400) % 30;
        peerMap[peer].hearts[index] += uint8(balanceNum);
    }

    // report status
    function reportStatus(string memory peer, uint32 createTime, string memory version, uint32 Nonce, address bttcAddress, bytes memory signed) external payable {
        require(0 < createTime, "reportStatus: Invalid createTime");
        require(0 < Nonce, "reportStatus: Invalid Nonce");
        require(0 < signed.length, "reportStatus: Invalid signed");
        require(peerMap[peer].lastNonce <= Nonce, "reportStatus: Invalid lastNonce<Nonce");

        // verify input param with the signed data.
        bytes32 hash = genHash(peer, createTime, version, Nonce, bttcAddress);
        require(verify(hash, signed), "reportStatus: Invalid signed address.");

        // only bttcAddress is sender， to report status
        // require(bttcAddress == msg.sender, "reportStatus: Invalid signed");

        uint32 nowTime = uint32(block.timestamp);
        uint index = (nowTime / 86400) % 30;

        // first report
        if (peerMap[peer].lastNonce == 0) {
            if (Nonce > 24) {
                Nonce = 24;
            }

            peerMap[peer].hearts[index] = uint8(Nonce);

            totalStat.totalUsers += 1;
            totalStat.total += 1;
        } else {
            // if (nowTime - peerMap[peer].lastTime <= 86400){
            //     return;
            // }

            setHeart(peer, Nonce, nowTime);
            totalStat.total += Nonce - peerMap[peer].lastNonce;
        }

        peerMap[peer].createTime = createTime;
        peerMap[peer].version = version;
        peerMap[peer].lastNonce = Nonce;
        peerMap[peer].lastTime = nowTime;



        emitStatusReported(
            peer,
            createTime,
            version,
            Nonce,
            nowTime,
            bttcAddress
        );
    }

    function emitStatusReported(string memory peer, uint32 createTime, string memory version, uint32 Nonce, uint32 nowTime, address bttcAddress) internal {
        emit statusReported(
            peer,
            createTime,
            version,
            Nonce,
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

    function genHash(string memory peer, uint32 createTime, string memory version, uint32 Nonce, address bttcAddress) internal pure returns (bytes32) {
        bytes memory data = abi.encode(peer, createTime, version, Nonce, bttcAddress);
        return keccak256(abi.encode("\x19Ethereum Signed Message:\n", data.length, data));
    }

    // call from external
    function genHashExt(string memory peer, uint32 createTime, string memory version, uint32 Nonce, address bttcAddress) external pure returns (bytes32) {
        return genHash(peer, createTime, version, Nonce, bttcAddress);
    }

    // call from external
    function recoverSignerExt(bytes32 hash, bytes memory sig) external pure returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        return ecrecover(hash, v+27, r, s);
    }
}