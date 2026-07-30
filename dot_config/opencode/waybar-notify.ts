import type { Plugin } from "@opencode-ai/plugin"

export default (async ({ $ }) => {
  const home = process.env.HOME ?? ""
  let last = { id: "", at: 0 }

  return {
    async event({ event }) {
      if (event.type !== "session.idle") return
      const sid: string =
        (event as { properties?: { sessionID?: string } }).properties?.sessionID ?? ""
      const now = Date.now()
      if (sid && sid === last.id && now - last.at < 800) return
      last = { id: sid, at: now }
      await $`bash ${home}/.config/waybar/ai-notify.sh`.nothrow().quiet()
    },
  }
}) satisfies Plugin