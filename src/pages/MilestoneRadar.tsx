import { Building2 } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

const mockBuildings = [
  { id: "1", name: "Bayshore Towers", address: "2200 Bayshore Dr, Miami", stories: 24, coYear: "2015", deadline: "2025-06-15", status: "critical" },
  { id: "2", name: "Gulf Point Plaza", address: "900 Gulf Blvd, Clearwater", stories: 8, coYear: "2018", deadline: "2026-01-20", status: "upcoming" },
];

export default function MilestoneRadar() {
  return (
    <div className="p-6 md:p-8 max-w-7xl">
      <h1 className="text-2xl font-medium mb-6">Milestone Radar</h1>
      <div className="grid gap-4 md:grid-cols-2">
        {mockBuildings.map((b) => (
          <Card key={b.id} className="shadow-subtle border">
            <CardContent className="p-5">
              <div className="flex items-start justify-between mb-3">
                <div>
                  <h3 className="text-sm font-medium">{b.name}</h3>
                  <p className="text-xs text-muted-foreground">{b.address}</p>
                </div>
                <span className={cn("rounded px-2 py-0.5 text-[10px] font-medium",
                  b.status === "critical" ? "bg-destructive/10 text-destructive" : "bg-muted text-muted-foreground"
                )}>
                  {b.status === "critical" ? "Critical" : "Upcoming"}
                </span>
              </div>
              <div className="text-xs text-muted-foreground space-y-1 mb-4">
                <p>{b.stories} stories · CO issued {b.coYear}</p>
                <p>Milestone deadline: {b.deadline}</p>
              </div>
              <Button size="sm" variant="outline" className="w-full">Launch Outreach</Button>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
