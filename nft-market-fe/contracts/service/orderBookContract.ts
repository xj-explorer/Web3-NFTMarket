import { ethers } from "ethers";
import EasySwapOrderBookABI from '../abis/EasySwapOrderBook.sol/EasySwapOrderBook.json';



// 定义枚举类型
export enum Side {
    Buy = 0,
    Sell = 1
}

export enum SaleKind {
    FixedPrice = 0,
    DutchAuction = 1
}

// 定义接口类型
export interface Asset {
    tokenId: string | number;
    collection: string;
    amount: number;
}

export interface Order {
    side: Side;
    saleKind: SaleKind;
    maker: string;
    nft: Asset;
    price: string;  // 使用字符串以支持大数
    expiry: number;
    salt: number;
}

/**
 * 创建NFT订单
 * @param contract EasySwapOrderBook合约实例
 * @param orders 订单数组
 * @param options 交易选项
 */
export async function makeOrders(
    contract: ethers.Contract,
    orders: Order[],
    options: {
        value?: string;  // 如果是买单需要支付ETH
    } = {}
) {
    try {
        // 验证订单数据
        orders.forEach(order => {
            if (!ethers.isAddress(order.maker)) {
                throw new Error('无效的maker地址');
            }
            if (!ethers.isAddress(order.nft.collection)) {
                throw new Error('无效的NFT合约地址');
            }
        });

        // 调用合约方法
        const tx = await contract.makeOrders(orders, {
            value: options.value || '0',
        });

        // 等待交易确认
        const receipt = await tx.wait();

        // 从事件中获取订单ID
        const orderKeys = receipt.events
            ?.filter((event: any) => event.event === 'LogMake')
            ?.map((event: any) => event.args.orderKey);

        return {
            orderKeys,
            transactionHash: receipt.transactionHash
        };

    } catch (error: any) {
        throw new Error(`创建订单失败: ${error.message}`);
    }
}

export default class OrderBookContract {
    private contract: ethers.Contract | null;
    private signer: ethers.Signer | null;

    constructor() {
        this.contract = null;
    }

    async init() {
        const provider = new ethers.BrowserProvider(window.ethereum);
        const signer = await provider.getSigner();
        this.signer = signer;
        this.contract = new ethers.Contract(
            "0x8039A8DafF806B27dB59C05fE5AD680F19c34f5A",
            EasySwapOrderBookABI.abi,
            signer
        );
    }

    public async getOrders(params: {
        collection: string,
        tokenId: number,
        side: number,      // 0: buy, 1: sell
        saleKind: number,  // 通常是固定价格或拍卖
        count: number,     // 想要获取的订单数量
        price?: bigint,
        firstOrderKey?: string
    }) {
        await this.init();
        const zeroBytes32 = '0x' + '0'.repeat(64);

        const orders = await this.contract!.getOrders(
            params.collection,
            params.tokenId,
            params.side,
            params.saleKind,
            params.count,
            params.price || BigInt(0),    // 如果不需要价格过滤，传null
            params.firstOrderKey || zeroBytes32  // 如果是第一次查询，传null
        );
        // return orders;
        // // 处理返回的订单数据
        const formattedOrders = orders.resultOrders.map((order: any) => {
            return {
                maker: order.maker,
                nftContract: order.nft.collection,
                tokenId: order.nft.tokenId.toString(),
                price: ethers.formatEther(order.price),
                side: order.side,
                expiry: new Date(Number(order.expiry) * 1000).toLocaleString(),
                // 其他字段根据实际返回数据结构添加
            };
        });

        return {
            orders: formattedOrders,
            nextOrderKey: orders.nextOrderKey  // 用于分页查询
        };
    }

    async createOrder(orders: any[]) {
        await this.init();
        const tx = await this.contract!.createOrder(orders);
        return tx;
    }


}