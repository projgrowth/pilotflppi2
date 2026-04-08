import { Radar } from "lucide-react";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

const mockLeads = [
  { id: "1", address: "9500 Collins Ave, Surfside", permitType: "Building", contractor: "Metro Builders LLC", value: "$4,200,000", detected: "Apr 6, 2026", outreach: "new" },
  { id: "2", address: "1800 Biscayne Blvd, Miami", permitType: "Electrical", contractor: "Volt Systems Inc", value: "$890,000", detected: "Apr 5, 2026", outreach: "contacted" },
  { id: "3", address: "600 NW 1st Ave, Fort Lauderdale", permitType: "Structural", contractor: "Sunshine Dev Group", value: "$2,100,000", detected: "Apr 3, 2026", outreach: "new" },
];

export default function LeadRadar() {
  return (
    <div className="p-6 md:p-8 max-w-7xl">
      <h1 className="text-2xl font-medium mb-6">Lead Radar</h1>
      <Card className="shadow-subtle border">
        <div className="divide-y">
          {mockLeads.map((lead) => (
            <div key={lead.id} className="flex items-center gap-4 px-5 py-4">
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium truncate">{lead.address}</p>
                <p className="text-xs text-muted-foreground">{lead.contractor}</p>
              </div>
              <span className="hidden sm:inline-flex rounded bg-muted px-2 py-0.5 text-[10px] font-medium">{lead.permitType}</span>
              <span className="hidden md:inline text-sm font-mono text-foreground">{lead.value}</span>
              <span className="text-xs text-muted-foreground">{lead.detected}</span>
              <span className={cn("rounded px-2 py-0.5 text-[10px] font-medium",
                lead.outreach === "new" ? "bg-accent/10 text-accent" : "bg-muted text-muted-foreground"
              )}>
                {lead.outreach === "new" ? "New" : "Contacted"}
              </span>
              <Button size="sm" variant="outline">Generate Outreach</Button>
            </div>
          ))}
        </div>
      </Card>
    </div>
  );
}
