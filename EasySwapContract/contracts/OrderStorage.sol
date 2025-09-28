// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {RedBlackTreeLibrary, Price} from "./libraries/RedBlackTreeLibrary.sol";
import {LibOrder, OrderKey} from "./libraries/LibOrder.sol";

error CannotInsertDuplicateOrder(OrderKey orderKey);

contract OrderStorage is Initializable {
    using RedBlackTreeLibrary for RedBlackTreeLibrary.Tree;

    /// @dev all order keys are wrapped in a sentinel value to avoid collisions
    /// @dev 所有订单键都包装在一个哨兵值中以避免冲突
    mapping(OrderKey => LibOrder.DBOrder) public orders;

    /// @dev price tree for each collection and side, sorted by price
    /// @dev 存储每个NFT Collection集合的每个交易方向（买或卖）对应的价格树，价格树按照价格进行排序。
    ///      外层映射的键是NFT Collection集合的地址，代表不同的NFT集合；    
    ///      内层映射的键是LibOrder.Side类型，代表交易方向（买入或卖出）；
    ///      值为RedBlackTreeLibrary.Tree类型的价格树，用于高效管理和查找价格。
    mapping(address => mapping(LibOrder.Side => RedBlackTreeLibrary.Tree)) public priceTrees;

    /// @dev order queue for each collection, side and expecially price, sorted by orderKey
    /// @dev 存储每个NFT Collection集合的每个交易方向（买或卖）对应的价格队列，价格队列按照订单键（orderKey）进行排序。
    ///      外层映射的键是NFT Collection集合的地址，代表不同的NFT集合；
    ///      内层映射的键是LibOrder.Side类型，代表交易方向（买入或卖出）；
    ///      中层映射的键是Price类型，代表订单的价格；
    ///      值为LibOrder.OrderQueue类型的价格队列，用于存储相同价格的订单。
    mapping(address => mapping(LibOrder.Side => mapping(Price => LibOrder.OrderQueue))) public orderQueues;

    /// @dev 初始化 OrderStorage 合约的主初始化函数，该函数会调用未链接的初始化函数。
    function __OrderStorage_init() internal onlyInitializing {}

    /// @dev OrderStorage 合约的未链接初始化函数，用于放置不需要在主初始化流程中立即执行的初始化逻辑。
    function __OrderStorage_init_unchained() internal onlyInitializing {}

    function onePlus(uint256 x) internal pure returns (uint256) {
        unchecked {
            return 1 + x;
        }
    }

    /// @dev 获取指定NFT Collection集合和交易方向（买或卖）的最优价格。
    /// @param collection NFT Collection集合的地址。
    /// @param side 交易方向（买入或卖出）。
    /// @return price 最优价格。
    function getBestPrice(
        address collection,
        LibOrder.Side side
    ) public view returns (Price price) {
        // 根据交易方向（side）获取最优价格
        // 如果交易方向为买入（LibOrder.Side.Bid），则获取价格树中的最后一个元素，因为通常买入时最高价格为最优价（从接单角度看）
        // 如果交易方向为卖出，则获取价格树中的第一个元素，因为通常卖出时最低价格为最优价（从接单角度看）
        price = (side == LibOrder.Side.Bid)
            ? priceTrees[collection][side].last()
            : priceTrees[collection][side].first();
    }

    /// @dev 获取指定NFT Collection集合和交易方向（买或卖）的次优价格。
    /// @param collection NFT Collection集合的地址。
    /// @param side 交易方向（买入或卖出）。
    /// @param price 当前价格。
    /// @return nextBestPrice 次优价格。
    function getNextBestPrice(
        address collection,
        LibOrder.Side side,
        Price price
    ) public view returns (Price nextBestPrice) {
        if (RedBlackTreeLibrary.isEmpty(price)) { // 如果当前价格为空，则复用最优价格的逻辑
            nextBestPrice = (side == LibOrder.Side.Bid)
                ? priceTrees[collection][side].last()
                : priceTrees[collection][side].first();
        } else {
            nextBestPrice = (side == LibOrder.Side.Bid)
                ? priceTrees[collection][side].prev(price)
                : priceTrees[collection][side].next(price);
        }
    }

    function _addOrder(
        LibOrder.Order memory order
    ) internal returns (OrderKey orderKey) {
        // 获取订单的hash值
        orderKey = LibOrder.hash(order);
        //  判断订单是否已经存在
        if (orders[orderKey].order.maker != address(0)) {
            revert CannotInsertDuplicateOrder(orderKey);
        }

        // insert price to price tree if not exists
        RedBlackTreeLibrary.Tree storage priceTree = priceTrees[
            order.nft.collection
        ][order.side];
        if (!priceTree.exists(order.price)) {
            priceTree.insert(order.price);
        }

        // insert order to order queue
        // 将订单插入到订单队列中
        // 获取对应NFT集合、交易方向和价格的订单队列的存储引用
        LibOrder.OrderQueue storage orderQueue = orderQueues[
            order.nft.collection
        ][order.side][order.price];

        // 检查队列是否初始化是否为空，若为空则创建新队列（map类型数据必须先初始化后才能读写操作，即在下面tail的判断中进行写入操作）
        if (LibOrder.isSentinel(orderQueue.head)) {
            orderQueues[order.nft.collection][order.side][order.price] = LibOrder.OrderQueue(
                LibOrder.ORDERKEY_SENTINEL,
                LibOrder.ORDERKEY_SENTINEL
            );
            orderQueue = orderQueues[order.nft.collection][order.side][order.price];
        }
        if (LibOrder.isSentinel(orderQueue.tail)) { // 队列是否为空
            orderQueue.head = orderKey;
            orderQueue.tail = orderKey;
            orders[orderKey] = LibOrder.DBOrder( // 创建新的订单，插入队列， 下一个订单为sentinel
                order,
                LibOrder.ORDERKEY_SENTINEL // 初始化下一个订单为sentinel
            );
        } else { // 队列不为空
            orders[orderQueue.tail].next = orderKey; // 将新订单插入队列尾部
            orders[orderKey] = LibOrder.DBOrder(
                order,
                LibOrder.ORDERKEY_SENTINEL
            );
            orderQueue.tail = orderKey;
        }
    }

    function _removeOrder(
        LibOrder.Order memory order
    ) internal returns (OrderKey orderKey) {
        LibOrder.OrderQueue storage orderQueue = orderQueues[
            order.nft.collection
        ][order.side][order.price];
        orderKey = orderQueue.head;
        OrderKey prevOrderKey;
        bool found;
        while (LibOrder.isNotSentinel(orderKey) && !found) {
            LibOrder.DBOrder memory dbOrder = orders[orderKey];
            // 匹配需要删除的订单
            if (
                (dbOrder.order.maker == order.maker) &&
                (dbOrder.order.saleKind == order.saleKind) &&
                (dbOrder.order.expiry == order.expiry) &&
                (dbOrder.order.salt == order.salt) &&
                (dbOrder.order.nft.tokenId == order.nft.tokenId) &&
                (dbOrder.order.nft.amount == order.nft.amount)
            ) {
                OrderKey temp = orderKey;
                // emit OrderRemoved(order.nft.collection, orderKey, order.maker, order.side, order.price, order.nft, block.timestamp);
                if (OrderKey.unwrap(orderQueue.head) == OrderKey.unwrap(orderKey)) {
                    orderQueue.head = dbOrder.next;
                } else {
                    orders[prevOrderKey].next = dbOrder.next;
                }
                if (OrderKey.unwrap(orderQueue.tail) == OrderKey.unwrap(orderKey)) {
                    orderQueue.tail = prevOrderKey;
                }
                prevOrderKey = orderKey;
                orderKey = dbOrder.next;
                // 从订单中删除订单
                delete orders[temp];
                found = true;
            } else {
                // 更新前一个订单键为当前订单键
                prevOrderKey = orderKey;
                // 将当前订单键更新为下一个订单键，继续遍历订单队列
                orderKey = dbOrder.next;
            }
        }
        if (found) {
            // 订单删除后，检查队列是否为空，如果为空则删除队列
            if (LibOrder.isSentinel(orderQueue.head)) {
                // 队列为空，删除队列
                delete orderQueues[order.nft.collection][order.side][order.price];
                RedBlackTreeLibrary.Tree storage priceTree = priceTrees[order.nft.collection][order.side];
                // 价格对应的队列被删除后，检查价格树是否存在该价格节点，如果存在则删除
                if (priceTree.exists(order.price)) {
                    priceTree.remove(order.price);
                }
            }
        } else {
            revert("Cannot remove missing order");
        }
    }

    /**
     * @dev 获取符合指定条件的订单列表。
     * @param collection NFT 集合的地址。
     * @param tokenId NFT 的 ID。
     * @param side 要获取的订单方向（买入或卖出）。
     * @param saleKind 销售类型（固定价格或拍卖）。
     * @param count 要获取的最大订单数量。
     * @param price 要获取的订单的最高价格。
     * @param firstOrderKey 要获取的第一个订单的键。
     * @return resultOrders 符合指定条件的订单数组。
     * @return nextOrderKey 下一个要获取的订单的键。
     */
    function getOrders(
        address collection,
        uint256 tokenId,
        LibOrder.Side side,
        LibOrder.SaleKind saleKind,
        uint256 count,
        Price price,
        OrderKey firstOrderKey
    )
        external
        view
        returns (LibOrder.Order[] memory resultOrders, OrderKey nextOrderKey)
    {
        // 检查参数是否有效
        // if (count == 0 || Price.unwrap(price) == 0) {
        //     return (new LibOrder.Order[](0), LibOrder.ORDERKEY_SENTINEL);
        // }
        // 初始化指定长度的结果数组
        resultOrders = new LibOrder.Order[](count);

        if (RedBlackTreeLibrary.isEmpty(price)) {
            price = getBestPrice(collection, side);
        } else {
            if (LibOrder.isSentinel(firstOrderKey)) {
                price = getNextBestPrice(collection, side, price);
            }
        }

        uint256 i;
        // 遍历价格对应的订单队列，直到找到count个订单或遍历完所有订单
        while (RedBlackTreeLibrary.isNotEmpty(price) && i < count) {
            LibOrder.OrderQueue memory orderQueue = orderQueues[collection][side][price];
            OrderKey orderKey = orderQueue.head;
            // 从第一个订单键开始遍历订单队列，直到找到firstOrderKey或遍历完所有订单
            if (LibOrder.isNotSentinel(firstOrderKey)) {
                while (
                    LibOrder.isNotSentinel(orderKey) && OrderKey.unwrap(orderKey) != OrderKey.unwrap(firstOrderKey)
                ) {
                    LibOrder.DBOrder memory order = orders[orderKey];
                    orderKey = order.next;
                }
                firstOrderKey = LibOrder.ORDERKEY_SENTINEL;
            }
            // 从当前订单键开始遍历订单队列，直到找到count个订单或遍历完所有订单
            while (LibOrder.isNotSentinel(orderKey) && i < count) {
                LibOrder.DBOrder memory dbOrder = orders[orderKey];
                // 已经添加了firstOrderKey，直接从下一个订单开始判断
                orderKey = dbOrder.next;
                // 检查订单是否过期，过期则跳过当前订单，继续查找下一个订单
                if (
                    (dbOrder.order.expiry != 0) && (dbOrder.order.expiry < block.timestamp)
                ) {
                    continue;
                }
                // 检查订单是否符合指定条件，不符合则跳出当前订单循环，查找下一个订单
                if (
                    (side == LibOrder.Side.Bid) && (saleKind == LibOrder.SaleKind.FixedPriceForCollection)
                ) {
                    if (
                        (dbOrder.order.side == LibOrder.Side.Bid) && (dbOrder.order.saleKind == LibOrder.SaleKind.FixedPriceForItem)
                    ) {
                        continue;
                    }
                }
                // 检查订单是否符合指定条件，不符合则跳出当前订单循环，查找下一个订单
                if (
                    (side == LibOrder.Side.Bid) && (saleKind == LibOrder.SaleKind.FixedPriceForItem)
                ) {
                    if (
                        (dbOrder.order.side == LibOrder.Side.Bid) &&
                        (dbOrder.order.saleKind == LibOrder.SaleKind.FixedPriceForItem) &&
                        // (dbOrder.order.saleKind == LibOrder.SaleKind.FixedPriceForCollection) && // 是否应该使用这个？
                        (dbOrder.order.nft.tokenId != tokenId)
                    ) {
                        continue;
                    }
                }

                // 符合条件的订单，添加到结果数组中，并作为返回值返回
                resultOrders[i] = dbOrder.order;
                // 记录下一个订单键，用于后续获取，并作为返回值返回
                nextOrderKey = dbOrder.next;
                i = onePlus(i);
            }
            // 遍历完当前价格的订单队列后，若没有获取凑齐count个数量的order，则获取下一个最佳价格继续获取订单，直到数量达到count个再返回
            price = getNextBestPrice(collection, side, price);
        }
    }

    /**
     * @dev 获取符合指定条件的最优订单
     * @param collection 集合地址
     * @param tokenId NFT的ID
     * @param side 订单方向
     * @param saleKind 销售类型
     * @return orderResult 最优订单
     */
    function getBestOrder(
        address collection,
        uint256 tokenId,
        LibOrder.Side side,
        LibOrder.SaleKind saleKind
    ) external view returns (LibOrder.Order memory orderResult) {
        Price price = getBestPrice(collection, side);
        while (RedBlackTreeLibrary.isNotEmpty(price)) {
            // 获取当前价格对应的订单队列
            LibOrder.OrderQueue memory orderQueue = orderQueues[collection][side][price];
            OrderKey orderKey = orderQueue.head;
            // 从第一个订单键开始遍历订单队列，直到找到count个订单或遍历完所有订单
            while (LibOrder.isNotSentinel(orderKey)) {
                LibOrder.DBOrder memory dbOrder = orders[orderKey];
                // 检查订单是否符合指定条件，不符合则跳出当前订单循环，查找下一个订单
                if (
                    (side == LibOrder.Side.Bid) && (saleKind == LibOrder.SaleKind.FixedPriceForItem)
                ) {
                    if (
                        (dbOrder.order.side == LibOrder.Side.Bid) &&
                        (dbOrder.order.saleKind == LibOrder.SaleKind.FixedPriceForItem) &&
                        // (dbOrder.order.saleKind == LibOrder.SaleKind.FixedPriceForCollection) && // 是否应该使用这个
                        (tokenId != dbOrder.order.nft.tokenId)
                    ) {
                        orderKey = dbOrder.next;
                        continue;
                    }
                }
                // 检查订单是否符合指定条件，不符合则跳出当前订单循环，查找下一个订单
                if (
                    (side == LibOrder.Side.Bid) && (saleKind == LibOrder.SaleKind.FixedPriceForCollection)
                ) {
                    if (
                        (dbOrder.order.side == LibOrder.Side.Bid) && (dbOrder.order.saleKind == LibOrder.SaleKind.FixedPriceForItem)
                    ) {
                        orderKey = dbOrder.next;
                        continue;
                    }
                }
                // 检查订单是否过期，过期则跳出当前订单循环，查找下一个订单
                if (
                    (dbOrder.order.expiry == 0) || (dbOrder.order.expiry > block.timestamp)
                ) {
                    orderResult = dbOrder.order;
                    break;
                }
                orderKey = dbOrder.next;
            }
            // 判断结果订单的价格是否存在，存在则跳出循环，返回最优order
            if (Price.unwrap(orderResult.price) > 0) {
                break;
            }
            // 遍历完当前价格的订单队列后，若没找到最优order，则获取下一个最佳价格继续获取，直到找到最优order或遍历完所有价格
            price = getNextBestPrice(collection, side, price);
        }
    }

    // 用于未来版本升级时预留的存储空间，防止升级合约时出现存储槽冲突
    uint256[50] private __gap;
}
