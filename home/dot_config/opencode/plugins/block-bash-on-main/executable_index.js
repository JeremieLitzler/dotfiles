import { Plugin } from "@opencode/plugin"
import { appendFileSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { blockMessage } from "./core.js"

// UNVERIFIED against V2 docs: the shell tool name and where the command sits in event.input.
// Run once with OPENCODE_GUARD_DEBUG=1 and read the log to confirm both before trusting the guard.
export default Plugin.define({
  id: "local.block-bash-on-main",
  async setup(ctx) {
    await ctx.tool.hook("execute.before", (event) => {
      const input = event.input ?? {}
      if (process.env.OPENCODE_GUARD_DEBUG) {
        appendFileSync(join(tmpdir(), "opencode-guard-debug.log"), JSON.stringify({ tool: event.tool, keys: Object.keys(input) }) + "\n")
      }
      if (event.tool !== "shell" && event.tool !== "bash") return
      const command = input.command
      if (typeof command !== "string") return
      const message = blockMessage(command, input.cwd ?? input.workdir ?? ctx.location.directory)
      if (message) throw new Error(message)
    })
  },
})
