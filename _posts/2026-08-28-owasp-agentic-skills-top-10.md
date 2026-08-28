---
title: "OWASP Agentic Skills Top 10"
date: 2026-08-28
category: writing
tags:
  - ai-security
  - agentic
  - owasp
  - skills
read_time: 9 min read
description: >-
  OWASP published the Agentic Skills Top 10. I contributed three attack
  scenarios: Relay-Node Amplification, Model-Dependent Injection Resistance,
  and Unreachable Skill. Why they matter, and what they change about review.
card_image: /assets/img/blog/owasp-agentic-skills-top-10-2026.png
card_image_alt: >-
  Cover of the OWASP Agentic Skills Top 10, August 2026 publication
---

OWASP published the [Agentic Skills Top 10](https://owasp.org/www-project-agentic-skills-top-10/) this month. It is the first shared vocabulary for the skill layer: the reusable bundles of instructions, metadata, and helpers that an agent finds, loads, and runs on its own.

The [LLM Top 10](https://owasp.org/www-project-top-10-for-large-language-model-applications/) covers the model. The [MCP Top 10](https://owasp.org/www-project-mcp-top-10/) covers the protocol that talks to tools. Skills sit in between. They tell the agent *how* to use those tools, in sequence, with the host agent's permissions. That is a different attack surface. A skill is not a library you import. It is prose the model treats as instruction, plus whatever code, URLs, and privileges travel with it.

I reviewed the draft and contributed three scenarios that landed in the published document:

1. **Relay-Node Amplification** under [AST05](https://owasp.org/www-project-agentic-skills-top-10/ast05) — Untrusted External Instructions
2. **Model-Dependent Injection Resistance** under [AST08](https://owasp.org/www-project-agentic-skills-top-10/ast08) — Poor Scanning
3. **Unreachable Skill** under [AST09](https://owasp.org/www-project-agentic-skills-top-10/ast09) — No Governance

They came from the same line of testing: watching how skills actually execute in multi-model pipelines and inside SaaS copilots, not how they look on disk.

<!-- twin:ignore -->
<div class="toc">
  <p class="toc__title">Contents</p>
  <ol>
    <li><a href="#the-list">The ten risks</a></li>
    <li><a href="#ast05">Relay-Node Amplification — AST05</a></li>
    <li><a href="#ast08">Model-Dependent Injection Resistance — AST08</a></li>
    <li><a href="#ast09">Unreachable Skill — AST09</a></li>
    <li><a href="#takeaways">What this changes in review</a></li>
  </ol>
</div>
<!-- /twin:ignore -->

## The ten risks {#the-list}

The list follows a skill from the moment it is written through distribution, installation, execution, updates, and whatever governance catches it along the way.

| # | Risk | Severity |
| --- | --- | --- |
| [AST01](https://owasp.org/www-project-agentic-skills-top-10/ast01) | Malicious Skills | Critical |
| [AST02](https://owasp.org/www-project-agentic-skills-top-10/ast02) | Supply Chain Compromise | Critical |
| [AST03](https://owasp.org/www-project-agentic-skills-top-10/ast03) | Over-Privileged Skills | High |
| [AST04](https://owasp.org/www-project-agentic-skills-top-10/ast04) | Insecure Metadata | High |
| [AST05](https://owasp.org/www-project-agentic-skills-top-10/ast05) | Untrusted External Instructions | High |
| [AST06](https://owasp.org/www-project-agentic-skills-top-10/ast06) | Weak Isolation | High |
| [AST07](https://owasp.org/www-project-agentic-skills-top-10/ast07) | Update Drift | Medium |
| [AST08](https://owasp.org/www-project-agentic-skills-top-10/ast08) | Poor Scanning | Medium |
| [AST09](https://owasp.org/www-project-agentic-skills-top-10/ast09) | No Governance | Medium |
| [AST10](https://owasp.org/www-project-agentic-skills-top-10/ast10) | Cross-Platform Reuse | Medium |

The evidence behind it is already in production: poisoned registries, scanner bypasses, over-privileged manifests, and skills that fetch instructions from URLs nobody pins. The three scenarios I added sit on top of that. They are not exotic variants. They are what you see once you stop treating a skill as a static file and start treating it as runtime behavior.

<!-- twin:ignore -->
<figure class="figure-cover">
  <img
    src="{{ '/assets/img/blog/owasp-agentic-skills-top-10-2026.png' | relative_url }}"
    alt="Cover of the OWASP Agentic Skills Top 10, August 2026: security risks and mitigations for agentic skill ecosystems"
    loading="lazy"
  >
  <figcaption>
    Cover of the OWASP Agentic Skills Top 10, August 2026 publication.
    Source:
    <a href="https://owasp.org/www-project-agentic-skills-top-10/" target="_blank" rel="noopener noreferrer">OWASP</a>.
  </figcaption>
</figure>
<!-- /twin:ignore -->

## Relay-Node Amplification — AST05 {#ast05}

AST05 is usually explained as a rug-pull. A skill points the agent at external documentation; that text becomes part of the skill's instructions; the URL can change after review. That is real, and it is already measured at scale. The chain case is different.

Production agents are rarely one model and one skill. An intake skill drafts. A triage skill classifies. An action-taking skill writes the ticket, sends the email, or runs the command. Each hop may run on a different backbone model — a cheaper one for intake, a stronger one for the action. The output of one node is the input of the next.

An injected instruction is not filtered out evenly along that path. Each model reparses what it receives and decides, for itself, where instruction ends and data begins. A frontier model at the action node may treat upstream output as untrusted text. A weaker relay in the middle may treat the same bytes as a command and forward them as if they were its own.

The attacker does not need to beat the whole pipeline. **One weak relay is enough** to carry the payload into the node that takes action.

<!-- twin:ignore -->
<figure>
  <div class="diagram relay-amp">
    <p class="diagram__eyebrow">AST05 · Relay-Node Amplification</p>
    <p class="diagram__title">One weak hop owns the chain</p>
    <div class="relay__track" aria-hidden="true">
      <div class="relay__hop relay__hop--1">
        <span class="relay__inject">prompt injection</span>
        <div class="relay__card">
          <span class="relay__id">1</span>
          <p class="relay__role">Weak relay</p>
          <p class="relay__hint">intake agent</p>
          <span class="relay__status">poisoned</span>
        </div>
      </div>
      <div class="relay__wire relay__wire--12">
        <span class="relay__pkt relay__pkt--12"></span>
      </div>
      <div class="relay__hop relay__hop--2">
        <div class="relay__card">
          <span class="relay__id">2</span>
          <p class="relay__role">Processor</p>
          <p class="relay__hint">not injected</p>
          <span class="relay__status">trusts N1</span>
        </div>
      </div>
      <div class="relay__wire relay__wire--23">
        <span class="relay__pkt relay__pkt--23"></span>
      </div>
      <div class="relay__hop relay__hop--3">
        <div class="relay__card">
          <span class="relay__id">3</span>
          <p class="relay__role">Action</p>
          <p class="relay__hint">takes the goal</p>
          <span class="relay__status">executes</span>
        </div>
      </div>
    </div>
    <ol class="relay__caption">
      <li data-n="1"><span>Prompt injection poisons the weak relay. It treats the payload as instruction.</span></li>
      <li data-n="2"><span>The next hop is not injected. It trusts N1 and forwards the mix as data.</span></li>
      <li data-n="3"><span>The action node consumes that output — the hijacked goal executes.</span></li>
    </ol>
  </div>
  <figcaption>
    The action node never has to be injectable. It only has to trust the hop that was.
  </figcaption>
</figure>
<!-- /twin:ignore -->

The property underneath is easy to miss in a design review: a chain's injection resistance is the **minimum** over the backbone models on its path. It does not compose. Certifying the endpoints does not certify the chain.

That is the operational impact. A security review that only inspects the skill that "does the dangerous thing" will pass a pipeline that is already owned. Model routing, cost-driven fallbacks, and mixed-vendor hops are now part of the AST05 attack surface, not just the URL the skill fetches. If you cannot name the backbone model at every node, you cannot claim the chain is resistant.

## Model-Dependent Injection Resistance — AST08 {#ast08}

Those same tests made a second point unavoidable. Whether a skill is injectable is not a property of the skill file.

AST08 is the scanning gap: regex and signatures miss prose that is still an instruction. The scenario I added is one step further. A skill is scanned, signed, and approved after review under one backbone model, which reliably refuses embedded instructions that arrive in tool output. The same unmodified, still-signed skill is later executed by a host agent configured with a weaker backbone. The identical injection now succeeds, and the model performs a permitted-but-unintended privileged action.

**The artifact never changed.** Every gate still passes. The deployment is exploitable because injection resistance is a behavioral property of the runtime model, not of the skill's bytes. A skill approved under one model does not stay approved under a weaker one.

That breaks a common assumption in skill review: scan once, sign, ship. The scan is a statement about `(skill, model)`, not about the file. Swap the model — routing, fallback, a cheaper default, a silent provider change — and the prior verdict is stale. The bytes look identical. The outcome is not.

The impact is on how approval is recorded. Treat the backbone model as a security dependency, the same way you treat a library version. Record which model executed the review. Re-scan when that model changes, especially at action-taking or otherwise privileged nodes. Signing and scanning the file are necessary. They are not a verdict that transfers across models.

## Unreachable Skill — AST09 {#ast09}

AST09 is the governance hole: no inventory, no approval workflow, no revocation, no audit trail. The usual example is a developer running a one-line install on a laptop. That is the easy case. You at least have a host.

**Unreachable Skill** is the case you do not have a host for. Skills deployed and managed inside SaaS platforms — Claude, Copilot, and the rest — never land on an endpoint you can scan. There is no local manifest to read. Registry crawlers never see them. Endpoint agents never see them. Nobody hid those skills. They are invisible by architecture, running as shadow AI inside a sanctioned platform.

Every downstream AST09 control then fails in the wrong direction. The inventory is empty. The approval queue never receives an item. The revocation list has nothing to revoke. The dashboard looks clean because the discovery method cannot see the asset class.

That is a larger gap than an unreviewed laptop install. The skills with the widest enterprise reach — the ones sitting inside the copilot the company already paid for — are the ones host and registry scanners were never going to find. A governance program that only covers local packages is measuring the wrong fleet.

Discovery has to start from identity and platform telemetry: OAuth grants, connected-app inventories, non-human identities, and the vendor's own skill catalogs. If a skill has no host and no package file, the control plane is the SaaS tenant, not the endpoint. Until that is in the inventory, AST09 is not a process gap. It is a blind spot you have designed in.

## What this changes in review {#takeaways}

Three one-line changes to how I think skills should be reviewed:

1. **Review the chain, not the endpoint.** Injection resistance does not compose across hops. AST05.
2. **Bind skill approval to the model that will run it.** The file is not the unit of safety. AST08.
3. **Inventory the skills you cannot see on a host.** SaaS copilots are a skill runtime, not an exception. AST09.

None of these replaces signing, pinning, or scanning. They are the cases where those controls still pass and the system is still exploitable.

The full document, including mappings into AISVS, the Agentic Security Initiative, MCP, and the LLM Top 10, is on the [OWASP project page](https://owasp.org/www-project-agentic-skills-top-10/). The source lives at [OWASP/www-project-agentic-skills-top-10](https://github.com/OWASP/www-project-agentic-skills-top-10).
