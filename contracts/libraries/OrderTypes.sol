// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title OrderTypes
 * @notice This library contains order types for the ApeNft exchange.
 */
library OrderTypes {
    // keccak256("MakerOrder(bool isOrderAsk,address signer,address collection,uint256 price,uint256 tokenId,uint256 amount,address strategy,address currency,uint256 nonce,uint256 startTime,uint256 endTime,uint256 minPercentageToAsk,bytes params)")
    bytes32 internal constant MAKER_ORDER_HASH = 0x40261ade532fa1d2c7293df30aaadb9b3c616fae525a0b56d3d411c841a85028;

    struct MakerOrder {
        address signer; // signer of the status
        address bttcAddr; // bttc address
        uint256 amount; // price (used as )
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    function hash(MakerOrder memory makerOrder) internal pure returns (bytes32) {
        return keccak256(
                abi.encode(
                    MAKER_ORDER_HASH,
                    makerOrder.signer,
                    makerOrder.bttcAddr,
                    makerOrder.amount
                )
            );
    }
}
