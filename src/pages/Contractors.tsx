import { Users } from "lucide-react";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";

const mockContractors = [
  { id: "1", name: "Coastal Builders Inc", license: "CBC1263578", email: "info@coastalbuilders.com", phone: "(305) 555-0100", projects: 4, portalAccess: true },
  { id: "2", name: "Sunshine Development", license: "CGC1521098", email: "contact@sunshinedev.com", phone: "(954) 555-0200", projects: 2, portalAccess: true },
  { id: "3", name: "Atlantic Construction Corp", license: "CBC1259834", email: "ops@atlanticcorp.com", phone: "(904) 555-0300", projects: 1, portalAccess: false },
];

export default function Contractors() {
  return (
    <div className="p-6 md:p-8 max-w-7xl">
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-medium">Contractors</h1>
        <Button className="bg-accent text-accent-foreground hover:bg-accent/90">+ Add Contractor</Button>
      </div>
      <Card className="shadow-subtle border">
        <div className="divide-y">
          {mockContractors.map((c) => (
            <div key={c.id} className="flex items-center gap-4 px-5 py-4">
              <div className="flex h-9 w-9 items-center justify-center rounded-full bg-muted text-xs font-medium text-muted-foreground">
                {c.name.split(" ").map((w) => w[0]).join("").slice(0, 2)}
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium truncate">{c.name}</p>
                <p className="text-xs text-muted-foreground font-mono">{c.license}</p>
              </div>
              <span className="hidden sm:inline text-xs text-muted-foreground">{c.email}</span>
              <span className="hidden md:inline text-xs text-muted-foreground">{c.phone}</span>
              <span className="text-xs text-muted-foreground">{c.projects} projects</span>
              <div className="flex items-center gap-2">
                <span className="text-[10px] text-muted-foreground">Portal</span>
                <Switch checked={c.portalAccess} />
              </div>
            </div>
          ))}
        </div>
      </Card>
    </div>
  );
}
