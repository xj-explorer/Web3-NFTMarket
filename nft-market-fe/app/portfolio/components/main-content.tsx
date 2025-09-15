import { Box, History, DollarSign, Wallet, LayoutGrid, List, TableProperties, Grid } from "lucide-react"
import { Button } from "@/components/ui/button"
// import { Checkbox } from "@/components/ui/checkbox"

export function MainContent() {
  return (
    <div className="flex-1 p-4">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-xl font-semibold">所有系列</h1>
        <div className="flex items-center space-x-4">
          <div className="text-sm text-gray-400">
            <span className="mr-4">已挂单 0/0</span>
            <span className="mr-4">估值 0.00</span>
            <span className="mr-4">成本 0.00</span>
            <span className="mr-4">未实现盈亏 ???</span>
            <span>实现盈亏 ???</span>
          </div>
        </div>
      </div>

      <div className="mb-6">
        <div className="flex items-center space-x-4 border-b border-gray-800">
          <Button variant="ghost" className="text-[#CEC5FD] border-b-2 border-[#CEC5FD] rounded-none">
            <Box className="h-4 w-4 mr-2" />
            库存
          </Button>
          <Button variant="ghost">
            <History className="h-4 w-4 mr-2" />
            历史
          </Button>
          <Button variant="ghost">
            <DollarSign className="h-4 w-4 mr-2" />
            出价
          </Button>
          <Button variant="ghost">
            <Wallet className="h-4 w-4 mr-2" />
            借贷
          </Button>
        </div>
      </div>

      <div className="flex justify-between items-center mb-4">
        <div className="flex items-center">
          {/* <Checkbox id="select-all" /> */}
          <label htmlFor="select-all" className="ml-2 text-sm">
            全选
          </label>
        </div>
        <div className="flex items-center space-x-2">
          <Button variant="ghost" size="icon">
            <LayoutGrid className="h-4 w-4" />
          </Button>
          <Button variant="ghost" size="icon">
            <List className="h-4 w-4" />
          </Button>
          <Button variant="ghost" size="icon">
            <TableProperties className="h-4 w-4" />
          </Button>
          <Button variant="ghost" size="icon">
            <Grid className="h-4 w-4" />
          </Button>
        </div>
      </div>

      <div className="text-sm text-gray-400 grid grid-cols-6 gap-4 mb-4">
        <div>稀有度</div>
        <div>挂单价格</div>
        <div>最高出价</div>
        <div>成本</div>
        <div>最大借款</div>
        <div>摄收日期</div>
      </div>

      <div className="text-center py-8 text-gray-400">暂时没有找到NFT资产.</div>

      <div className="fixed bottom-0 left-0 right-0 border-t border-gray-800 bg-black p-4">
        <div className="flex justify-center space-x-4">
          <Button className="bg-[#CEC5FD99] hover:bg-[#CEC5FDcc] text-[#CEC5FD]">挂单 0 个</Button>
          <Button className="bg-[#CEC5FD99] hover:bg-[#CEC5FDcc] text-[#CEC5FD]">接受 0 个 0.00</Button>
          <Button className="bg-[#CEC5FD99] hover:bg-[#CEC5FDcc] text-[#CEC5FD]">借款 0 个 0.00</Button>
        </div>
      </div>
    </div>
  )
}

