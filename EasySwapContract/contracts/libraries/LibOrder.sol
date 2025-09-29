// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Price} from "./RedBlackTreeLibrary.sol";

// 定义 OrderKey 类型，使用 bytes32 作为底层类型，用于唯一标识订单
type OrderKey is bytes32;

library LibOrder {
    enum Side {
        List,// 出售订单
        Bid // 购买订单
    }

    /// @dev 定义订单的销售类型
    enum SaleKind {
        FixedPriceForCollection, // 针对整个集合的固定价格销售
        FixedPriceForItem // 针对单个物品的固定价格销售
    }

    struct Asset {
        uint256 tokenId;
        address collection;
        uint96 amount;
    }

    struct NFTInfo {
        address collection;
        uint256 tokenId;
    }

    struct Order {
        Side side; // 订单类型，List 为出售订单，Bid 为购买订单
        SaleKind saleKind; // 订单的销售类型，FixedPriceForCollection 为集合固定价销售，FixedPriceForItem 为单品固定价销售
        address maker; // 订单创建者的地址
        Asset nft; // 订单关联的 NFT 资产信息
        Price price; // unit price of nft，NFT 的单价
        uint64 expiry; // 订单的过期时间戳
        uint64 salt; // 随机数，用于生成唯一的订单哈希
    }

    struct DBOrder {
        Order order;
        OrderKey next;
    }

    /// @dev Order queue: used to store orders of the same price
    struct OrderQueue {
        OrderKey head;
        OrderKey tail;
    }

    struct EditDetail {
        OrderKey oldOrderKey; // old order key which need to be edit
        LibOrder.Order newOrder; // new order struct which need to be add
    }

    /// @dev 定义订单匹配详情结构体，用于记录一次订单匹配中的出售订单和购买订单
    struct MatchDetail {
        LibOrder.Order sellOrder; // 出售订单
        LibOrder.Order buyOrder;  // 购买订单
    }

    // 定义一个哨兵订单键常量，使用值 0x0 包装，用于表示空订单或边界条件
    // wrap() 方法用于将底层类型的值（这里是 bytes32 类型的 0x0）包装为自定义类型 OrderKey。
    // 自定义类型通过包装操作来确保类型安全，防止不同类型的值被意外混用。
    OrderKey public constant ORDERKEY_SENTINEL = OrderKey.wrap(0x0);

    bytes32 public constant ASSET_TYPEHASH =
        keccak256("Asset(uint256 tokenId,address collection,uint96 amount)");

    bytes32 public constant ORDER_TYPEHASH =
        keccak256(
            "Order(uint8 side,uint8 saleKind,address maker,Asset nft,uint128 price,uint64 expiry,uint64 salt)Asset(uint256 tokenId,address collection,uint96 amount)"
        );

    /// @dev 计算资产的哈希值，用于唯一标识资产
    /// @param asset 资产结构体，包含资产的所有信息
    /// @return assetHash 资产哈希值，用于唯一标识资产
    function hash(Asset memory asset) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ASSET_TYPEHASH,
                    asset.tokenId,
                    asset.collection,
                    asset.amount
                )
            );
    }

    /// @dev 计算订单的哈希值，用于唯一标识订单
    /// @param order 订单结构体，包含订单的所有信息
    /// @return orderKey 订单键，用于唯一标识订单
    function hash(Order memory order) internal pure returns (OrderKey) {
        return
            OrderKey.wrap(
                keccak256(
                    abi.encodePacked(
                        ORDER_TYPEHASH,
                        order.side,
                        order.saleKind,
                        order.maker,
                        hash(order.nft),
                        Price.unwrap(order.price),
                        order.expiry,
                        order.salt
                    )
                )
            );
    }

    function isSentinel(OrderKey orderKey) internal pure returns (bool) {
        // unwrap() 方法用于将自定义类型 OrderKey 转换为其底层类型 bytes32，
        // 这样才能对两个 OrderKey 类型的值进行比较操作，因为自定义类型不能直接比较，
        // 需要转换为底层类型后再进行比较。
        // 检查订单键是否为初始零值
        return OrderKey.unwrap(orderKey) == OrderKey.unwrap(ORDERKEY_SENTINEL);
    }

    function isNotSentinel(OrderKey orderKey) internal pure returns (bool) {
        return OrderKey.unwrap(orderKey) != OrderKey.unwrap(ORDERKEY_SENTINEL);
    }
}
