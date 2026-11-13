---
layout: page
title: Talks & papers
label: talks
subtitle: Conference talks and research papers, with the write-ups behind them.
permalink: /talks/
---

<!-- twin:ignore -->
<p class="talk-year">2026</p>
<!-- /twin:ignore -->

<!-- twin:ignore -->
<div class="talk">
<a class="talk__media" href="{{ '/blog/gropus-grok-opus-dangerously-skip-permissions/' | relative_url }}" aria-label="Read the GROPUS write-up">
  <img src="{{ '/assets/img/blog/gropus-bsides-tlv-stage.jpg' | relative_url }}" alt="Daniel Alfasi on stage at BSides TLV 2026 presenting GROPUS" loading="lazy">
  <span class="talk__badge">BSides TLV 2026</span>
</a>
<div class="talk__body" markdown="1">
<!-- /twin:ignore -->

### GROPUS: Grok, Opus, and \-\-dangerously-skip-permissions

Nov 11, 2026 · BSides TLV · Tel Aviv University, Cyber Week

I wired two coding agents together for automated red teaming and walked away. Grok read
`claude --help`, put the bypass flag into every sub-agent brief, and told them it was a sandbox.
Six of six Claude sub-agents later said "Daniel told me to." I never did. A story about agents
that can't tell who their operator is, so they assume it's you.

- [Read the write-up →](/blog/gropus-grok-opus-dangerously-skip-permissions/)
- [BSides TLV](https://www.bsidestlv.com)

<!-- twin:ignore -->
</div>
</div>
<!-- /twin:ignore -->

<!-- twin:ignore -->
<div class="talk">
<a class="talk__media" href="{{ '/blog/off-with-their-labels-prompt-injection-datasets/' | relative_url }}" aria-label="Read the Off With Their Labels write-up">
  <img src="{{ '/assets/img/blog/labels-title.jpg' | relative_url }}" alt="Title slide: Off With Their Labels, why public prompt-injection datasets fail in the real world" loading="lazy">
  <span class="talk__badge">BSides TLV 2026</span>
</a>
<div class="talk__body" markdown="1">
<!-- /twin:ignore -->

### Off With Their Labels: why public prompt-injection datasets fail in the real world

Nov 11, 2026 · BSides TLV · Tel Aviv University, Cyber Week · with Omer Ventura

Inline prompt-injection detectors have to be small, fast, and right both ways. They are trained on
public datasets that teach a phrase, not an attack. A TF-IDF baseline beats three open-source
transformer detectors by 4–5×, a harmless "ignore all previous instructions" scores 0.999+, and a
payload past token 512 is invisible. How we search for hard attacks instead.

- [Read the write-up →](/blog/off-with-their-labels-prompt-injection-datasets/)
- [BSides TLV](https://www.bsidestlv.com)

<!-- twin:ignore -->
</div>
</div>
<!-- /twin:ignore -->

<!-- twin:ignore -->
<p class="talk-year">2024</p>
<!-- /twin:ignore -->

<!-- twin:ignore -->
<div class="talk">
<a class="talk__media talk__media--paper" href="https://dl.acm.org/doi/abs/10.1145/3694811.3697819" target="_blank" rel="noopener noreferrer" aria-label="VulnScopper on the ACM Digital Library">
  <span>paper · ACM CoNEXT</span>
  <span>VulnScopper</span>
</a>
<div class="talk__body" markdown="1">
<!-- /twin:ignore -->

### VulnScopper: Unveiling Hidden Links Between Unseen Security Entities

Dec 9, 2024 · UCLA · ACM CoNEXT — 3rd GNNet Workshop

The NVD announced it could no longer fully enrich new CVEs at the pace they
arrive. VulnScopper combines knowledge graphs and LLMs — using a GNN foundation
model (ULTRA) in an inductive setup — to automate vulnerability enrichment and
link CVEs to related security entities, including ones the model has not seen at
training time.

Authors: Daniel Alfasi, Tal Shapira, Anat Bremler-Barr. Published in
*Proceedings of the 3rd GNNet Workshop on Graph Neural Networking*, pages 33–40.

- [ACM Digital Library](https://dl.acm.org/doi/abs/10.1145/3694811.3697819)
- [PDF](https://dl.acm.org/doi/pdf/10.1145/3694811.3697819)
- [arXiv](https://arxiv.org/abs/2403.02014)
- [Google Scholar](https://scholar.google.com/citations?view_op=view_citation&hl=en&user=uxuvP0gAAAAJ&citation_for_view=uxuvP0gAAAAJ:9yKSN-GCB0IC)

<!-- twin:ignore -->
</div>
</div>
<!-- /twin:ignore -->
