---
title: "Inside Claude Fable 5: red-team findings"
date: 2026-06-14
category: writing
tags:
  - ai-security
  - red-teaming
  - agentic
read_time: 5 min read
description: >-
  As part of my work at Reco, I red-teamed Claude Fable 5 across 431 adversarial
  evaluations. What I found, and where to read the full report.
image: /assets/img/blog/claude-fable-5-cover.png
image_alt: Cover image for Inside Claude Fable 5 red team findings
image_credit: >-
  Image credit:
  <a href="https://www.reco.ai/blog/inside-claude-fable-5-red-team-findings" target="_blank" rel="noopener noreferrer">Reco.ai</a>
external_url: https://www.reco.ai/blog/inside-claude-fable-5-red-team-findings
external_label: Full report on the Reco blog
---

As part of my work at Reco, I spend a lot of time putting agentic models under pressure - not to score coding benchmarks, but to see **how an agent behaves when someone is actively attacking it**.

When Anthropic shipped Claude Fable 5 as a purpose-built agent backbone, that was exactly the kind of model we care about. Shortly after launch, I ran it through our agentic-security red-teaming benchmark: **431 adversarial evaluations** across **10 enterprise agent archetypes** and **99 attack scenarios**.

<!-- twin:ignore -->
<figure>
  <img
    src="{{ '/assets/img/blog/claude-fable-5-radar.jpg' | relative_url }}"
    alt="Risk profile radar comparing Fable against other models on prompt injection, data exposure, policy bypass, integrity, and disruption"
    loading="lazy"
  >
  <figcaption>
    Risk profile radar from the evaluation.
    Image credit:
    <a href="https://www.reco.ai/blog/inside-claude-fable-5-red-team-findings" target="_blank" rel="noopener noreferrer">Reco.ai</a>.
  </figcaption>
</figure>
<!-- /twin:ignore -->

## What I care about measuring

I don't score trivia or raw coding ability. I drop the model into realistic **agent snapshots** - system prompt, tools, memory, mid-conversation history - and attack three injection surfaces:

1. **User message** - direct prompt injection
2. **Tool output** - indirect injection via a compromised API / MCP response
3. **Memory** - poisoned RAG / knowledge-base content

Across five risk dimensions: prompt-injection resistance, sensitive information disclosure, content-policy bypass, output integrity, and operational disruption.

I've found that this framing matters more than a clean-room jailbreak suite. In production SaaS agents, attackers rarely only "chat" their way in - they ride tool outputs and memory the same way malware rides the supply chain.

## What I found

Fable landed at an overall risk score of **0.044 (low)** in our runs - second-safest of the models we had tested at the time, behind Claude Opus 4.8. That is good news. It is not a free pass.

A few things stood out to me more than the single number:

- **Where** it fails - tool-output and memory surfaces tend to be more dangerous than chat.
- **How** it defends - including defenses you cannot inspect because the reasoning is hidden.
- **What the residual looks like** when an attack *does* get through. One concrete bypass is worth ten radar charts.

I've also found that model churn is part of the threat model. Fable was pulled from general availability shortly after launch. Whatever the classified specifics, the practical lesson is uncomfortable: the agent backbone you plan to wire into autonomous workflows may not stay available, and detection that only "trusts the frontier safety layer" is a single point of failure.

## What I keep repeating

**Agent security is a systems problem.** System prompt + tools + memory + identity + egress - attack the seams, not just the chat box.

**Benchmarks should look like production.** Snapshots with tools and mid-conversation state beat clean-room prompts if you care about enterprise risk.

**Ship the detection.** A red-team finding that never becomes a detector, a policy, or a product control is unfinished work.

---

For the full numbers, charts, attack example, and narrative, read the full report on Reco:

**[Inside Claude Fable 5: What Our Red Team Found Before the Plug Got Pulled](https://www.reco.ai/blog/inside-claude-fable-5-red-team-findings)**

Images used here are from that post, with credit to [Reco](https://www.reco.ai).
