// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library LibPayInfo {
    //total share in percentage, 10,000 = 100%
    // 资金分配的总份额，以百分比为单位，10,000 表示 100%
    uint128 public constant TOTAL_SHARE = 10000;
    // 协议最大份额，以基点为单位，1000 表示 10%，即 最大10% 的资金会被协议收取作为手续费，在ProtocolManager合约中可以设置手续费份额大小
    uint128 public constant MAX_PROTOCOL_SHARE = 1000;
    // PayInfo 结构体的类型哈希，用于 EIP-712 签名验证，通过 keccak256 哈希 "PayInfo(address receiver,uint96 share)" 生成
    bytes32 public constant TYPE_HASH = keccak256("PayInfo(address receiver,uint96 share)");

    struct PayInfo {
        address payable receiver;
        // Share of funds. 
        // Basis point format.
        uint96 share;
    }

    // 计算 PayInfo 结构体的哈希值，用于 EIP-712 签名验证
    function hash(PayInfo memory info) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, info.receiver, info.share));
    }
}
