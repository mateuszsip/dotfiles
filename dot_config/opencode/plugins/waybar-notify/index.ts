import { Plugin } from "@opencode/plugin"
import { spawn } from "node:child_process"
import { homedir } from "node:os"
import { join } from "node:path"

// Pings the waybar AI indicator when a session finishes, so a turn that ends
// while you are looking elsewhere leaves a mark. The actual store/clear logic
// lives in ~/.config/waybar/ai-notify.sh (shared with the Claude Code hook).
const notify = join(homedir(), ".config", "waybar", "ai-notify.sh")

export default Plugin.define({
  id: "waybar-notify",
  setup(ctx) {
    const controller = new AbortController()
    // session.idle can repeat in a burst; the same session is only announced
    // once per turn.
    let last = { id: "", at: 0 }

    void (async () => {
      try {
        for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
          if (event.type !== "session.idle") continue
          const sid =
            (event as { properties?: { sessionID?: string } }).properties?.sessionID ?? ""
          const now = Date.now()
          if (sid && sid === last.id && now - last.at < 800) continue
          last = { id: sid, at: now }
          const child = spawn("bash", [notify], { detached: true, stdio: "ignore" })
          child.on("error", (err) => console.error("waybar-notify:", err))
          child.unref()
        }
      } catch (err) {
        if (!controller.signal.aborted) console.error("waybar-notify:", err)
      }
    })()

    return () => controller.abort()
  },
})
