// Port of ~/.claude/hooks/block-bash-on-main.py (same regex, same fail-open rule).
import { execFileSync } from "node:child_process"

export function isRisky(command) {
  const cmd = command.replace(/\d?>>?\s*(\/dev\/null|&\d)/g, "")
  return /(^|[;&|]\s*|&&\s*)(rtk\s+)?git\s+(-C\s+\S+\s+)?(commit|push)\b|(^|[^>])>>?\s*[^\s&|>]|\bsed\s+(-\w*i|--in-place)|\btee\b/.test(cmd)
}

export function currentBranch(cwd) {
  try {
    return execFileSync("git", ["-C", cwd, "rev-parse", "--abbrev-ref", "HEAD"], { encoding: "utf8", timeout: 5000 }).trim()
  } catch {
    return "" // fail open, like the Python hook
  }
}

export function blockMessage(command, cwd) {
  if (!isRisky(command)) return null
  const name = currentBranch(cwd)
  if (name !== "main" && name !== "master") return null
  return `Blocked: this command commits, pushes or writes files while the repo is on '${name}'. Create a feature branch first: git checkout -b <type>/<issue>-<slug>.`
}
