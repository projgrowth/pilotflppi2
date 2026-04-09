import { cn } from "@/lib/utils";
import { LucideIcon } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";

interface KpiCardProps {
  label: string;
  value: string | number;
  icon: LucideIcon;
  accent?: boolean;
  destructive?: boolean;
  onClick?: () => void;
  loading?: boolean;
}

export function KpiCard({ label, value, icon: Icon, accent, destructive, onClick, loading }: KpiCardProps) {
  if (loading) {
    return (
      <Card className="shadow-subtle">
        <CardContent className="p-5">
          <div className="h-4 w-16 rounded bg-muted animate-pulse mb-3" />
          <div className="h-8 w-12 rounded bg-muted animate-pulse" />
        </CardContent>
      </Card>
    );
  }

  return (
    <Card
      className={cn(
        "shadow-subtle transition-all",
        onClick && "cursor-pointer hover:shadow-md hover:border-accent/30"
      )}
      onClick={onClick}
    >
      <CardContent className="p-5">
        <div className="flex items-center gap-1.5 mb-2">
          <Icon className={cn(
            "h-3.5 w-3.5",
            destructive ? "text-destructive" : accent ? "text-accent" : "text-muted-foreground"
          )} />
          <span className="text-[11px] font-medium text-muted-foreground uppercase tracking-wider">{label}</span>
        </div>
        <p className={cn(
          "text-3xl font-semibold tracking-tight",
          destructive ? "text-destructive" : "text-foreground"
        )}>
          {value}
        </p>
      </CardContent>
    </Card>
  );
}
