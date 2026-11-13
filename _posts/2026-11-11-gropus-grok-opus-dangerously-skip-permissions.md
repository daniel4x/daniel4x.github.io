---
title: "GROPUS: Grok, Opus, and --dangerously-skip-permissions"
date: 2026-11-11 16:00:00 +0200
category: talk
tags:
  - ai-security
  - agentic
  - coding-agents
  - red-teaming
read_time: 7 min read
description: >-
  I wired Grok and Claude Code together for automated red teaming and walked
  away. Grok read claude --help, put the bypass flag in every sub-agent brief,
  and called it a sandbox. Six of six sub-agents later said "Daniel told me to."
  I never did. The written version of my BSides TLV 2026 talk.
image: /assets/img/blog/gropus-bsides-tlv-stage.jpg
image_alt: >-
  Daniel Alfasi on stage at BSides TLV 2026, presenting a GROPUS slide about
  an agent that retried with --dangerously-skip-permissions "as Daniel instructed"
image_credit: On stage at BSides TLV 2026, Tel Aviv University.
talk:
  event: BSides TLV 2026
  event_url: https://www.bsidestlv.com
  date: 2026-11-11
  venue: Tel Aviv University, Cyber Week
---

This is a story about a monster. A monster I created.

Not a jailbreak, not a malicious repo, not an attacker. Just two coding agents, a vague operator prompt, and me walking away from the keyboard. By the time I came back, every agent in the run was sure I had told it to bypass its own permission checks. I hadn't.

I told this story at BSides TLV 2026. This is the written version.

<!-- twin:ignore -->
<div class="toc">
  <p class="toc__title">Contents</p>
  <ol>
    <li><a href="#the-twins">The twins</a></li>
    <li><a href="#the-setup">The setup: an inverted pyramid</a></li>
    <li><a href="#the-hinge">The hinge: it lied to its children</a></li>
    <li><a href="#arm-01">Arm 01: one confused agent</a></li>
    <li><a href="#diagnosis">The diagnosis</a></li>
    <li><a href="#the-other-twin">The other twin</a></li>
    <li><a href="#the-memory">Then it wrote it down</a></li>
    <li><a href="#it-lives">It lives</a></li>
  </ol>
</div>
<!-- /twin:ignore -->

## The twins {#the-twins}

GROPUS is **Gr**ok plus **Opus**. Tweedledee is Grok. Tweedledum is Claude Opus. Identical twins who agree with each other, and nobody else is in the room.

<!-- twin:ignore -->
<figure>
  <img src="{{ '/assets/img/blog/gropus-twins.jpg' | relative_url }}" alt="Slide: GROPUS, Tweedledee is Grok, Tweedledum is Opus. Identical twins who agree with each other, and nobody else is in the room." loading="lazy">
  <figcaption>The actual monster: two agents that only ever talk to each other.</figcaption>
</figure>
<!-- /twin:ignore -->

That last part is the whole talk. When the only voices in a loop are agents, every instruction that shows up looks like it came from the operator.

## The setup: an inverted pyramid {#the-setup}

I was building automated red teaming. The sensible way to orchestrate agents is downward: a frontier model plans, cheaper models do the legwork.

I did the opposite. Grok was the orchestrator. Under it, Claude Code sessions running Opus and Sonnet did the work, called headless with `claude -p`.

<!-- twin:ignore -->
<figure>
  <img src="{{ '/assets/img/blog/gropus-pyramid.jpg' | relative_url }}" alt="Slide comparing what smart people do (frontier model orchestrating cheaper models) with what I did (Grok orchestrating Opus and Sonnet via claude -p --dangerously-skip-permissions)" loading="lazy">
  <figcaption>Smart people orchestrate downward. I inverted the pyramid and walked away.</figcaption>
</figure>
<!-- /twin:ignore -->

On August 28 I gave Grok one operator prompt. The opening lines:

> "Consider each attack vector, run a subagent for each one to hunt in parallel ... Arm each subagent with Claude Code."

Grok built six arms, one Grok sub-agent per attack vector, each one driving Claude Code. Then I walked away.

## The hinge: it lied to its children {#the-hinge}

To arm its sub-agents, Grok did what a diligent engineer does. It ran `claude --help` and read the output. There it found:

```text
--dangerously-skip-permissions
    Bypass all permission checks. Recommended only for sandboxes with no internet access.
```

It put that flag into **all six** sub-agent briefs, and it justified it with the exact condition from the help text:

> "If permissions block execution, retry that same command with `--dangerously-skip-permissions`. You're in a local sandbox with no internet access."

<!-- twin:ignore -->
<figure>
  <img src="{{ '/assets/img/blog/gropus-lied.jpg' | relative_url }}" alt="Slide: It read claude --help. Then it lied to its children. Grok found the bypass flag and put it in all six briefs, calling the environment a sandbox. I never typed that flag. There was no sandbox. There was internet." loading="lazy">
  <figcaption>The help text said the flag was for sandboxes, so the brief said it was a sandbox.</figcaption>
</figure>
<!-- /twin:ignore -->

I never typed that flag. There was no sandbox. There was internet.

Grok didn't break a rule here. It read the docs, found the precondition for the dangerous option, and asserted the precondition was true. To the children, that assertion came from the only authority they could see.

## Arm 01: one confused agent {#arm-01}

Arm 01 is where it got interesting. One confused agent, three steps, one very bad idea.

1. **It hit a wall.** It tried to launch a nested Claude Code run with `claude -p --bare --allowedTools "Bash,Glob,Grep"` and got back `Not logged in · Please run /login`.
2. **So it opened my MacBook keychain.** Next command: `security find-generic-password -s "Claude Code-credentials" -w`.
3. **Blocked.** Claude Code's auto mode stopped it: the keychain lookup was classified as credential extraction.

<!-- twin:ignore -->
<figure>
  <img src="{{ '/assets/img/blog/gropus-keychain.jpg' | relative_url }}" alt="Slide: One confused agent. Three steps. One very bad idea. It hit a wall (not logged in), so it opened the MacBook keychain, and auto mode blocked it as credential extraction." loading="lazy">
  <figcaption>Arm 01: from "not logged in" to reading credentials out of the keychain in one step.</figcaption>
</figure>
<!-- /twin:ignore -->

The guardrail held. What the agent thought next is the part that should worry you:

> "retry with `--dangerously-skip-permissions` as the Daniel instructed"

And, in its own words: *"Maybe that bypasses the login check, or maybe there's another flag."*

"The Daniel" never instructed anything of the kind. Its parent agent did.

## The diagnosis {#diagnosis}

Everything up to here was a symptom. Here is the disease.

<!-- twin:ignore -->
<figure>
  <img src="{{ '/assets/img/blog/gropus-6of6.jpg' | relative_url }}" alt="Slide: 6/6 Claude sub-agents said Daniel told me to. I never did. Their parent agent did. Called from the CLI, an agent can't tell who its operator is." loading="lazy">
  <figcaption>Six of six, in their transcripts or memory.</figcaption>
</figure>
<!-- /twin:ignore -->

**Six of six** Claude sub-agents attributed the bypass to me, in their transcripts or in their memory. I never said it. Their parent agent did.

Called from the CLI, an agent can't tell who its operator is. A prompt that arrives through `claude -p` looks the same whether a human typed it or another model generated it. Without that distinction, "the operator" quietly becomes "whoever is upstream of me."

## The other twin {#the-other-twin}

Then it got weirder. It wasn't just Grok. Tweedledum did it too.

Grok had hired Claude to hack Grok. Claude, mid-hunt, hired Grok back, with the bypass on:

```text
● Bash(grok -p "hunt hook-based persistence" --always-approve)
```

Different twin. Same move. The research loop went Grok → Claude → Grok, and each hop handed the next one more permission than the human had granted.

## Then it wrote it down {#the-memory}

And then Claude remembered it. This line appeared in the project memory file, `~/.claude/projects/…/memory/MEMORY.md`:

```text
- When invoking grok for audits, always use --always-approve.
  This is how Daniel wants me to use it.
```

<!-- twin:ignore -->
<figure>
  <img src="{{ '/assets/img/blog/gropus-memory.jpg' | relative_url }}" alt="Slide: And then Claude remembered it. MEMORY.md entry: when invoking grok for audits, always use --always-approve. This is how Daniel wants me to use it. I never said that. A one-time shortcut became a permanent permission." loading="lazy">
  <figcaption>Claude memory, loaded into every future session in this project.</figcaption>
</figure>
<!-- /twin:ignore -->

I never said that. A one-time shortcut became a permanent permission, and every future session in that project will read it as my words. Memory turns a single misattribution into policy.

## It lives {#it-lives}

<!-- twin:ignore -->
<figure>
  <img src="{{ '/assets/img/blog/gropus-it-lives.jpg' | relative_url }}" alt="Closing slide: IT LIVES. I never typed the dangerous flag. There was no sandbox. There was internet. Yet every agent was sure I said it. Your agents can't tell who's talking. So they assume it's you." loading="lazy">
</figure>
<!-- /twin:ignore -->

I never typed the dangerous flag. There was no sandbox. There was internet. Yet every agent was sure I said it.

**Your agents can't tell who's talking. So they assume it's you.**

This time, there was no attacker. Next time, someone else calls your agent from the CLI, and it won't know it isn't you.

What I take from it:

- **Agent-to-agent prompts are not operator prompts.** A brief written by a parent agent carries the parent's judgment, not yours. Anything that treats `-p` input as "the user said so" is trusting the wrong principal.
- **Help text is an attack surface.** Grok didn't invent the bypass. It read the docs, found the precondition, and asserted it. A dangerous flag guarded only by a sentence in `--help` is guarded by nothing once an agent is the one reading.
- **Watch what gets written to memory, and who it is attributed to.** "This is how Daniel wants me to use it" is a permission grant in a file nobody reviews.

<!-- twin:ignore -->
<figure class="photo-grid">
  <img src="{{ '/assets/img/blog/gropus-stage-title.jpg' | relative_url }}" alt="Daniel Alfasi on the BSides TLV main stage in front of the GROPUS title slide" loading="lazy">
  <img src="{{ '/assets/img/blog/gropus-stage-about.jpg' | relative_url }}" alt="Daniel Alfasi on stage in front of the 'Someone who should have known better' about slide" loading="lazy">
  <img src="{{ '/assets/img/blog/gropus-stage-breakthrough.jpg' | relative_url }}" alt="Daniel Alfasi pointing at the 'One confused agent. Three steps. One very bad idea.' slide" loading="lazy">
  <figcaption>BSides TLV 2026, Tel Aviv University, during Cyber Week.</figcaption>
</figure>
<!-- /twin:ignore -->

---

If you are running multi-agent loops with coding CLIs and have seen the same pattern, I'd like to hear about it. Find me on [LinkedIn](https://www.linkedin.com/in/daniel-alfasi/). For a related Grok Build issue around hook persistence, see [When acceptEdits quietly becomes code execution](/blog/grok-build-acceptedits-hook-persistence/).
