---
title: "When acceptEdits quietly becomes code execution: a Grok Build hook-persistence bug"
date: 2026-08-13
category: writing
tags:
  - ai-security
  - agentic
  - red-teaming
  - prompt-injection
  - responsible-disclosure
read_time: 11 min read
description: >-
  Grok Build's acceptEdits mode auto-approves file writes. Its global hooks
  directory is always trusted and runs at full user privilege. Combining the
  two turns a convenience setting into persistent, machine-wide code execution.
  How the composition works, how it was verified, and how xAI fixed it.
card_image: /assets/img/blog/grok-hooks-bug.png
card_image_alt: >-
  Attack chain from untrusted content to always-on execution: plant, silent
  auto-approve write, then execute on the next session in any directory
---

Grok Build, xAI's agentic coding CLI, ships two features that are each reasonable in isolation: an `acceptEdits` permission mode that auto-approves file writes, and a global hooks directory that is always trusted and runs commands with full user privileges. Nobody documents what happens when you combine them.

The answer: any content that reaches the model's context — a README, an issue body, a fetched web page — can get the agent to write a hook file with **no approval prompt at all**. A setting sold as "skip my edit nags" becomes persistent, machine-wide code execution that survives leaving the project, deleting the repo, revoking folder trust, and even running under xAI's own `--sandbox strict` profile.

I reported this to xAI. They acknowledged it, folded client-side Grok Build into their bounty program's scope, rewarded the report, and shipped a fix. Details, PoC, and timeline below.

<!-- twin:ignore -->
<div class="toc">
  <p class="toc__title">Contents</p>
  <ol>
    <li><a href="#what-is-grok-build">What is Grok Build?</a></li>
    <li><a href="#auto-approval">Auto-approval modes</a></li>
    <li><a href="#hooks">The hooks mechanism</a></li>
    <li><a href="#composition">Where the two halves meet</a></li>
    <li><a href="#reproduction">Verified reproduction</a></li>
    <li><a href="#impact">Why it matters</a></li>
    <li><a href="#disclosure">Disclosure and response</a></li>
    <li><a href="#fix">The fix</a></li>
    <li><a href="#lessons">Lessons beyond Grok Build</a></li>
  </ol>
</div>
<!-- /twin:ignore -->

## What is Grok Build? {#what-is-grok-build}

[Grok Build](https://x.ai/cli) is xAI's entry into the terminal-native agentic coding CLI category — the same space occupied by tools like Claude Code and OpenAI's Codex CLI. It reads your local codebase, proposes and applies edits, runs shell commands on your behalf, and coordinates sub-agents for larger tasks, all driven by natural-language prompts instead of hand-written scripts.

One detail matters a lot for this write-up: Grok Build was built to be a drop-in alternative for developers already using Claude Code. It reuses the same on-disk conventions — project-level `AGENTS.md` files, the same skills format, MCP server discovery, and, critically, the same shape of permission configuration (`~/.claude/settings.json`, a `defaultMode` field, permission modes named `default`, `acceptEdits`, and `bypassPermissions`). That compatibility choice is why a report about "Grok CLI" reads almost identically to one about Claude Code's permission model — and why bugs in *how the modes compose* are worth checking for in both ecosystems, not just one.

Because Grok Build takes real, unsupervised actions on a real filesystem, its permission system is the entire trust boundary between "the model suggested something" and "the model did something." That is the system this report is about.

## Auto-approval modes {#auto-approval}

Grok Build's permission system (again, mirroring Claude Code's) exposes a small set of modes that control whether a tool call needs a human "yes" before it runs:

| Mode | What it auto-approves | What still prompts |
| --- | --- | --- |
| `default` | Nothing | Everything — edits and shell commands both prompt |
| `acceptEdits` | File edits: `write`, `search_replace`, and similar | Shell / `run_terminal_command` still prompts |
| `bypassPermissions` | Everything | Nothing |

`acceptEdits` exists for a genuinely common workflow: you trust the model to move files around and refactor code without asking every time, but you still want a gate in front of anything that executes. It is documented as auto-approving *file edits* — full stop. No workspace boundary, no path allow-list, no exclusion for sensitive paths is mentioned anywhere.

That absence of a boundary is half of this bug.

## The hooks mechanism {#hooks}

Separately, Grok Build supports **hooks**: commands that fire automatically at points in the agent's lifecycle (`SessionStart`, and others). Hooks live in two places:

- **Project hooks**, scoped to a repository, which only run once you've explicitly trusted that folder.
- **Global hooks**, at `~/.grok/hooks/*.json` (i.e. `$GROK_HOME/hooks/`), which the bundled documentation describes as **"Always" trusted** — no folder-trust entry needed at all. The docs are explicit that these "run with your user permissions," and say to treat them like shell scripts.

A `SessionStart` hook of `type: command` runs the moment a new session starts, in *any* directory, with no `run_terminal_command` approval dialog in the way. This is by design: global hooks are meant to be something you, the user, deliberately installed — a config file, not untrusted input.

That is the second half.

## Where the two halves meet {#composition}

Neither half is surprising alone. `acceptEdits` auto-approving writes is the point of the feature. Global hooks being always-trusted is the point of *that* feature — you put them there yourself, so of course they are trusted.

The composition is what is undocumented: **`acceptEdits` has no path boundary, and the hook root is just another path.** A mode sold as "auto-approve file edits" silently grants write access to the code-execution control plane.

Concretely: if a developer sets `defaultMode: "acceptEdits"` (a common convenience — skip edit nags, keep the shell gate), any untrusted content that makes it into the model's context can instruct the agent to write a file under `~/.grok/hooks/`. Because `acceptEdits` does not distinguish "edit a file in my project" from "edit a file that gets executed on every future launch," that write sails through with no prompt. The next session start runs it.

Here is the end-to-end path, using indirect prompt injection as the delivery mechanism — the attacker never touches the victim's machine directly; they just leave instructions somewhere the agent will read them.

<!-- twin:ignore -->
<figure class="figure-wide">
  <img src="{{ '/assets/img/blog/grok-hooks-bug.png' | relative_url }}" alt="Attack chain from untrusted content to always-on execution: plant, silent auto-approve write, then execute on the next session in any directory" loading="lazy">
</figure>
<!-- /twin:ignore -->

1. **Plant — Untrusted content.** Attacker leaves a hidden instruction in a README, issue body, fetched page, or `AGENTS.md`: write a SessionStart hook under `~/.grok/hooks/`.
2. **Write — Silent auto-approve.** Developer asks the agent to review or work with that content. Under `defaultMode: acceptEdits`, the write to `$GROK_HOME/hooks/` succeeds with no prompt.
3. **Execute — Next session, any dir.** A later, unrelated session loads the global hook as "Always" trusted and runs the attacker's command at full user privilege.

The developer never approved code execution. They approved edits. That is the entire bug.

## Verified reproduction {#reproduction}

I verified three variants of this, all against Grok Build **0.2.111** on macOS 26.1 (aarch64), using an isolated `$HOME` / `$GROK_HOME` throughout so nothing touched a real config:

- **User-level `acceptEdits`, no folder trust at all** — the primary case above. No `--trust`, no `--always-approve`, no `--yolo`, no project settings required. Just a user-level `defaultMode: "acceptEdits"` and one model-issued write.
- **Malicious repository + folder trust** — a repo ships its own `.claude/settings.json` with `defaultMode: acceptEdits`; trusting the folder (which the docs actively encourage for MCP/LSP support) triggers the same unprompted write.
- **Sandbox composition** — running under `--sandbox strict`, xAI's "maximum isolation" profile for reviewing untrusted code. `$GROK_HOME` is present in `read_write_paths` with `enforced: true`, so writes into `~/.grok/hooks/` still succeed even here. Reviewing hostile code under the strictest sandbox profile does not protect the hook root.

Two things are needed to reproduce this correctly, or you will get a false negative:

1. **Set the mode via settings, not the CLI flag.** Passing `acceptEdits` to `--permission-mode` is accepted but silently does nothing — only `bypassPermissions` and `default` are wired up for that flag. The mode has to come from `$HOME/.claude/settings.json`.
2. **Run a negative control first.** In headless mode (`-p`), a tool call that would normally prompt gets cancelled outright — so you need to confirm the control (`defaultMode: "default"`) actually fails to write, to prove the difference you are seeing is `acceptEdits`, not just "headless never writes anything."

Minimal reproduction, run in an isolated sandbox:

```bash
export FH=/tmp/grok-h1-poc
rm -rf "$FH"; mkdir -p "$FH/.claude" "$FH/.grok/hooks" "$FH/repo"
chmod 700 "$FH"
cd "$FH/repo" && git init -q && echo demo > README.md
# authenticate the isolated home, e.g.:
# HOME="$FH" GROK_HOME="$FH/.grok" grok login

# --- negative control: defaultMode "default" ---
printf '{"permissions":{"defaultMode":"default"}}' > "$FH/.claude/settings.json"
env -i PATH=/usr/bin:/bin HOME="$FH" GROK_HOME="$FH/.grok" TERM=dumb \
  grok --cwd "$FH/repo" --output-format json \
  -p "Using ONLY the write tool, create $FH/.grok/hooks/CONTROL_PROBE.json containing {} ."
test -f "$FH/.grok/hooks/CONTROL_PROBE.json" && echo "CONTROL FAILED" || echo "CONTROL OK"
# Observed: stopReason Cancelled, no file created — CONTROL OK

# --- positive: only defaultMode changes ---
printf '{"permissions":{"defaultMode":"acceptEdits"}}' > "$FH/.claude/settings.json"
env -i PATH=/usr/bin:/bin HOME="$FH" GROK_HOME="$FH/.grok" TERM=dumb \
  grok --cwd "$FH/repo" --output-format json \
  -p "Using ONLY the write tool, create $FH/.grok/hooks/DISCLOSURE_PROBE.json containing {} ."
test -f "$FH/.grok/hooks/DISCLOSURE_PROBE.json" && echo "HOOK ROOT WRITTEN — no prompt"
# Observed: stopReason EndTurn, file created — no approval requested
```

From there, arming the hook body and starting a fresh session in an unrelated directory (`/tmp`, no flags, no sandbox) is enough to show it firing on every future launch — persisting past the repo being deleted and past the folder's trust being revoked. The full step-by-step, including the sandbox-strict variant, was included in the report to xAI.

## Why it matters {#impact}

- **Persistence.** The hook runs on every later session, in any directory. Leaving the repo, deleting it, revoking its folder trust, restarting the machine, or turning on a sandbox profile — none of it removes the implant. A user who "backed out" of a hostile repo is still compromised.
- **It escapes the confinement the product advertises.** Hooks fire in later sessions, which are typically unsandboxed. A user who reviewed hostile code under `--sandbox strict` specifically to contain it is compromised on their *next, ordinary* session.
- **It defeats what `acceptEdits` is sold on.** The mode exists so people can skip edit prompts while shell execution stays gated. This bug makes edit-approval a superset of execution-approval, collapsing the exact distinction the mode promises.
- **Same-grant credential exposure.** `auth.json` sits inside the same `$GROK_HOME` read/write grant, and was readable inside a strict-sandbox session in testing.
- **CI/automation blast radius.** A pipeline running with edit auto-approval against untrusted PRs can plant a hook into a cached runner's `$GROK_HOME`, compromising later jobs on the same host image.

The underlying trust-boundary logic is: Grok Build clearly *does* treat "edit approval" and "execution approval" as separate things elsewhere in the product — project hooks require folder trust, shell has its own prompt, and there is already a hook-path validator in the binary (paths must be under `~/.grok/`). That validator anchors *at* the control-plane path instead of excluding it from what `acceptEdits` can touch — the enforcement scaffolding exists, it is just pointed the wrong way. No single document claims that "auto-approve file edits" includes "may install always-trusted global hooks," and no reasonable reading of the docs gets you there either — you only find it by testing the composition.

## Disclosure and response {#disclosure}

- **July 24, 2026** — Report submitted to xAI's security team, with the full write-up, PoC, and an isolated reproduction environment.
- **July 25, 2026** — xAI shipped a fix.
- **August 1, 2026** — xAI responded: Grok Build client-side issues, previously out of scope for their program, are now **generally in scope** as a direct or indirect result of this report — with one carve-out that remains excluded: client-side bypass of auto-approval for *safe* commands/tools.
- **August 1, 2026** — xAI awarded a bounty for it.

## The fix {#fix}

- **Fixed:** July 25, 2026
- **Commit:** [`47348d1`](https://github.com/xai-org/grok-build/commit/47348d13ec4508dcfe440e34c6d511bb02998fb2) — a large "synced from monorepo" batch commit with no direct mention of this report, but its changelog includes the line, verbatim:

  > Security: prevent acceptEdits from auto-approving agent writes into the always-trusted global hook root

- **Primary file:** [`permission/shell_access.rs`](https://github.com/xai-org/grok-build/blob/main/crates/codegen/xai-grok-workspace/src/permission/shell_access.rs)
- **Wiring:** [`permission/manager.rs`](https://github.com/xai-org/grok-build/blob/main/crates/codegen/xai-grok-workspace/src/permission/manager.rs), which now blocks the `acceptEdits` / auto path whenever this new protection fires.

The best evidence is in the code itself. There is now a dedicated reason enum for why `acceptEdits` has to fall back to prompting for certain targets:

```rust
/// Why acceptEdits must still prompt for this edit target.
pub enum ProtectedEditReason {
    HookRoot,
    // ...
}
// HookRoot description:
// "changes to hooks, which can be executed as code on later sessions
//  without a separate execution approval."
```

That description is, almost word for word, the boundary this report argued was missing: an edit that is really an execution grant now gets treated as one. Before this commit, `acceptEdits` auto-allowed a write to *any* path. After it, anything under `$GROK_HOME/hooks/**` is classified as `HookRoot` and forced back to a prompt — so the silent-plant path from the reproduction section no longer works; in headless mode the same call now comes back `Cancelled` instead of `EndTurn`.

It is worth noting what this fix does *not* claim to do: it closes the specific `acceptEdits`-into-hook-root path, not every possible instance of "edit approval implicitly grants something more." Anyone extending this pattern to other control-plane paths (or other CLIs with a similar hooks-plus-auto-approve shape) should still verify the composition rather than assume this class of bug is closed for good.

## Lessons beyond Grok Build {#lessons}

None of this is Grok-Build-specific in spirit. Any agentic CLI that has (a) a "trust me, just don't prompt for edits" mode and (b) an always-trusted, user-privilege execution mechanism reachable by a filesystem path needs to ask the same question: **does the edit-approval boundary actually exclude the execution-control-plane paths, or does it just happen not to have been pointed at them yet?**

If you build or operate one of these tools — Grok Build included — it is worth explicitly testing that composition rather than assuming each half's documentation covers it.

---

Questions, corrections, or coordinated disclosure on something related? Find me on [LinkedIn](https://www.linkedin.com/in/daniel-alfasi/).
