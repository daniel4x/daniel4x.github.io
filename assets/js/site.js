// Progressive enhancements only: the site works fully without this file.

// Code blocks: keyboard access for scrollable blocks, plus a copy button.
for (const block of document.querySelectorAll("div.highlighter-rouge")) {
  const pre = block.querySelector("pre");
  if (!pre) continue;

  if (pre.scrollWidth > pre.clientWidth) {
    pre.tabIndex = 0;
    pre.setAttribute("role", "region");
    pre.setAttribute("aria-label", "Code example");
  }

  const button = document.createElement("button");
  button.type = "button";
  button.className = "copy-button";
  button.textContent = "copy";

  // The live region sits outside the button so the result is announced.
  const status = document.createElement("span");
  status.className = "visually-hidden";
  status.setAttribute("role", "status");

  let timer;
  button.addEventListener("click", async () => {
    let ok = true;
    try {
      await navigator.clipboard.writeText(pre.innerText.trim());
    } catch {
      ok = false;
    }
    clearTimeout(timer);
    button.removeAttribute("data-copied");
    button.removeAttribute("data-failed");
    button.setAttribute(ok ? "data-copied" : "data-failed", "");
    button.textContent = ok ? "copied ✓" : "failed ✕";
    status.textContent = ok ? "Copied" : "Copy failed";
    timer = setTimeout(() => {
      button.removeAttribute("data-copied");
      button.removeAttribute("data-failed");
      button.textContent = "copy";
      status.textContent = "";
    }, 2000);
  });

  block.append(button, status);
}

// WebMCP (early preview in Chromium): expose the site's content to in-browser
// agents as read-only tools. Ignored everywhere the API does not exist.
if (document.modelContext?.registerTool) {
  const fetchJson = async (signal) => {
    const response = await fetch("/feed.json", { signal });
    return response.ok ? response.json() : null;
  };

  document.modelContext.registerTool({
    name: "list_posts",
    description:
      "Lists every blog post on danielalfasi.com with its title, summary, tags, date, and URLs. Use to find writing on AI security, agentic systems, or red teaming.",
    inputSchema: { type: "object", properties: {} },
    async execute(_input, { signal }) {
      const feed = await fetchJson(signal);
      if (!feed) return { error: "Could not load the post index. Fetch /llms.txt instead." };
      return feed.items.map((item) => ({
        title: item.title,
        summary: item.summary,
        tags: item.tags,
        date: item.date_published,
        url: item.url,
        markdownUrl: item._markdown_url,
      }));
    },
    annotations: { readOnlyHint: true },
  });

  document.modelContext.registerTool({
    name: "get_page_markdown",
    description:
      "Returns the full Markdown source of a page or post on danielalfasi.com. Use to read or quote content; cite the canonical_url from its front matter.",
    inputSchema: {
      type: "object",
      properties: {
        path: {
          type: "string",
          description:
            "Site path of the page, such as /about/ or /blog/owasp-agentic-skills-top-10/. Omit for the page currently open.",
        },
      },
    },
    async execute({ path } = {}, { signal }) {
      const target = typeof path === "string" && path.startsWith("/") ? path : location.pathname;
      const trimmed = target.replace(/index\.html$/, "").replace(/\/$/, "");
      const response = await fetch(`${trimmed || "/index"}.md`, { signal });
      if (!response.ok) {
        return { error: `No Markdown found for "${target}". Call list_posts for valid paths.` };
      }
      return { path: target, markdown: await response.text() };
    },
    annotations: { readOnlyHint: true },
  });
}
