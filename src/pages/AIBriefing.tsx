import { Sparkles } from "lucide-react";

export default function AIBriefing() {
  return (
    <div className="p-6 md:p-8 max-w-7xl">
      <h1 className="text-2xl font-medium mb-6">AI Briefing</h1>
      <div className="flex flex-col items-center justify-center py-20 text-center">
        <Sparkles className="h-12 w-12 text-muted-foreground/30 mb-4" />
        <h2 className="text-lg font-medium">AI Briefing Feed</h2>
        <p className="text-sm text-muted-foreground mt-1">Real-time intelligence updates will appear here</p>
      </div>
    </div>
  );
}
