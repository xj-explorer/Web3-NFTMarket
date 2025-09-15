import { Button } from "@/components/ui/button"

const recentSales = [
  { time: "1年", price: "0.005", buyer: "mie_no..." },
  { time: "1年", price: "0.005", buyer: "mie_no..." },
  { time: "1年", price: "0.0035", buyer: "mie_no..." },
  { time: "1年", price: "0.0033", buyer: "mie_no..." },
  { time: "1年", price: "0.002", buyer: "mie_no..." },
  { time: "1年", price: "0.002", buyer: "mie_no..." },
]

export function RecentActivity() {
  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="font-semibold">Recent Activity</h3>
        <Button variant="link" size="sm">
          查看更多
        </Button>
      </div>

      <div className="space-y-2">
        {recentSales.map((sale, i) => (
          <div key={i} className="flex items-center justify-between p-2 rounded-lg hover:bg-accent">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 bg-muted rounded-full" />
              <div>
                <div className="text-sm">{sale.buyer}</div>
                <div className="text-xs text-muted-foreground">{sale.time}</div>
              </div>
            </div>
            <div className="text-sm font-medium">{sale.price} ETH</div>
          </div>
        ))}
      </div>
    </div>
  )
}

