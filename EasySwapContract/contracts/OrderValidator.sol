// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 导入 OpenZeppelin 可升级合约库中的 Initializable 合约，用于支持合约的初始化逻辑
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// 导入 OpenZeppelin 可升级合约库中的 ContextUpgradeable 合约，用于处理上下文信息
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
// 导入 OpenZeppelin 可升级合约库中的 EIP712Upgradeable 合约，用于处理 EIP712 签名验证
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";

// 导入自定义库 RedBlackTreeLibrary 中的 Price 类型
import {Price} from "./libraries/RedBlackTreeLibrary.sol";
// 导入自定义库 LibOrder 中的 LibOrder 结构体和 OrderKey 类型
import {LibOrder, OrderKey} from "./libraries/LibOrder.sol";

/**
 * @title Verify the validity of the order parameters.
 */
abstract contract OrderValidator is
    Initializable,
    ContextUpgradeable,
    EIP712Upgradeable
{
    bytes4 private constant EIP_1271_MAGIC_VALUE = 0x1626ba7e;

    uint256 private constant CANCELLED = type(uint256).max;

    // fillsStat record orders filled status, key is the order hash, and value is filled amount.
    // Value CANCELLED means the order has been canceled.
    // 记录每个订单已成交的NFT数量，键为订单键，值为已成交的NFT数量。若值为 CANCELLED 则表示订单已取消。
    mapping(OrderKey => uint256) public filledAmount;

    /**
     * @dev 初始化 OrderValidator 合约。
     * 该函数会初始化上下文和 EIP712 相关参数，并调用未链接的初始化函数。
     * @param EIP712Name EIP712 的名称。
     * @param EIP712Version EIP712 的版本。
     */
    function __OrderValidator_init(
        string memory EIP712Name,
        string memory EIP712Version
    ) internal onlyInitializing {
        // 初始化上下文，用于后续获取调用者地址等上下文信息
        __Context_init();
        // 初始化 EIP712 相关参数
        __EIP712_init(EIP712Name, EIP712Version);
        // 调用未链接的初始化函数
        __OrderValidator_init_unchained();
    }

    function __OrderValidator_init_unchained() internal onlyInitializing {}

    /**
     * @notice 验证订单参数
     * @param order  需要验证的订单
     * @param isSkipExpiry  若为 true 则跳过过期检查
     */
    function _validateOrder(
        LibOrder.Order memory order,
        bool isSkipExpiry
    ) internal view {
        // Order must have a maker.
        require(order.maker != address(0), "OVa: miss maker");
        // Order must be started and not be expired.

        if (!isSkipExpiry) { // Skip expiry check if true.
            require(
                order.expiry == 0 || order.expiry > block.timestamp,
                "OVa: expired"
            );
        }
        // Order salt cannot be 0.
        require(order.salt != 0, "OVa: zero salt");

        if (order.side == LibOrder.Side.List) {
            require(
                order.nft.collection != address(0),
                "OVa: unsupported nft asset"
            );
        } else if (order.side == LibOrder.Side.Bid) {
            // 要求订单价格必须大于 0，若价格为 0 则抛出错误
            require(Price.unwrap(order.price) > 0, "OVa: zero price");
        }
    }

    /**
     * @notice 获取订单已成交数量
     * @param orderKey  订单键
     * @return orderFilledAmount  订单已成交数量（若订单未成交则为 0）
     */
    function _getFilledAmount(
        OrderKey orderKey
    ) internal view returns (uint256 orderFilledAmount) {
        // Get has completed fill amount.
        orderFilledAmount = filledAmount[orderKey];
        // Cancelled order cannot be matched.
        require(orderFilledAmount != CANCELLED, "OVa: canceled");
    }

    /**
     * @notice 更新订单已成交数量
     * @param newAmount  新的已成交数量
     * @param orderKey  订单键
     */
    function _updateFilledAmount(
        uint256 newAmount,
        OrderKey orderKey
    ) internal {
        require(newAmount != CANCELLED, "OVa: canceled");
        filledAmount[orderKey] = newAmount;
    }

    /**
     * @notice 取消订单
     * @dev 已取消的订单不能重新开启
     * @param orderKey  订单键
     */
    function _cancelOrder(OrderKey orderKey) internal {
        filledAmount[orderKey] = CANCELLED;
    }

    uint256[50] private __gap;
}
