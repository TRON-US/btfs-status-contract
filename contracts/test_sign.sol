// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// ApeNft libraries
import {OrderTypes} from "./libraries/OrderTypes.sol";
import {SignatureChecker} from "./libraries/SignatureChecker.sol";

// MerkleDistributor for airdrop to BTFS staker
contract BtfsStatusTest {
    using SafeMath for uint256;

    event Log(address);

    // owner
    address public owner;
    constructor() {
        owner = msg.sender;
        emit Log(owner);
    }




    /**
 * @notice Verify the validity of the maker order
     * @param makerOrder maker order
     * @param orderHash computed hash for the order
     */
    function _validateOrder(OrderTypes.MakerOrder calldata makerOrder, bytes32 orderHash) internal view {

        // Verify the signer is not address(0)
        require(makerOrder.signer != address(0), "Order: Invalid signer");

        // Verify the amount is not 0
        require(makerOrder.amount > 0, "Order: Amount cannot be 0");

        // Verify the validity of the signature
        require(
            SignatureChecker.verify(
                orderHash,
                makerOrder.signer,
                makerOrder.v,
                makerOrder.r,
                makerOrder.s
            ),
            "Signature: Invalid"
        );
    }


    /**
     * @param makerAsk maker ask order
     */
    function validateOrder(OrderTypes.MakerOrder calldata makerAsk) external view {
//        require(owner.address() == "0x70997970C51812dc3A010C7d01b50e0d17dc79C8", "owner: is current user."+owner);

        // Check the maker ask order
        bytes32 askHash = keccak256(
            abi.encode(
                makerAsk.signer,
                makerAsk.bttcAddr,
                makerAsk.amount
            )
        );
        _validateOrder(makerAsk, askHash);
    }

    /**
 * @param makerAsk maker ask order
     */
    function testHash(OrderTypes.MakerOrder calldata makerAsk) external view returns (bytes32) {

        // Check the maker ask order
        bytes32 askHash = keccak256(
            abi.encode(
                makerAsk.signer,
                makerAsk.bttcAddr,
                makerAsk.amount
            )
        );
        return askHash;
    }
}