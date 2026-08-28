# frozen_string_literal: true

# After the HTML build, write markdown twins plus /llms.txt and /llms-full.txt.
# GitHub Pages serves *.md as text/markdown when those files exist in _site.

require "date"
require "fileutils"
require "yaml"

module AgentMarkdown
  SITEMAP_NOTE = <<~MD.freeze
    ## Sitemap

    See the full [sitemap](/sitemap.md) for all pages.
  MD

  SITE_ORDER = %w[/ /about/ /talks/ /blog/].freeze

  module_function

  def markdown_path(url)
    path = url.to_s.sub(/index\.html\z/, "").sub(/\.html\z/, "")
    return "/index.md" if path.empty? || path == "/"

    "#{path.chomp("/")}.md"
  end

  def content_page?(page)
    url = page.url.to_s
    return false if url.end_with?(".txt", ".xml", ".json", ".css", ".js")
    return false if url.include?("404")
    return false unless %w[.md .html].include?(File.extname(page.path))

    true
  end

  def posts_newest(site)
    site.posts.docs.sort_by(&:date).reverse
  end

  def ordered_docs(site)
    by_url = {}
    site.pages.each { |page| by_url[page.url] = page if content_page?(page) }

    SITE_ORDER.filter_map { |url| by_url[url] } + posts_newest(site)
  end

  def write!(site)
    mirrors = ordered_docs(site).filter_map do |doc|
      body = body_for(site, doc)
      next if body.nil? || body.strip.empty?

      markdown = "#{frontmatter_for(site, doc)}#{body.strip}\n\n#{SITEMAP_NOTE}"
      write_file(site, markdown_path(doc.url), markdown)
      [doc, markdown]
    end

    write_file(site, "/llms.txt", llms_txt(site, mirrors.map(&:first)))
    write_file(site, "/llms-full.txt", llms_full(site, mirrors))
  end

  def body_for(site, doc)
    case doc.url
    when "/" then homepage_md(site)
    when "/blog/" then blog_index_md(site)
    else
      return unless File.extname(doc.path) == ".md"

      expand_relative_urls(site, strip_frontmatter(File.read(doc.path)))
    end
  end

  def homepage_md(site)
    author = site.config["author"] || {}
    posts = posts_newest(site)

    [
      "# #{site.config["title"]}",
      "",
      "#{site.config["tagline"]} at [#{author["company"]}](#{author["company_url"]}).",
      "",
      "I break (and sometimes build) agentic systems, coding agents, and LLM applications - then ship the detection logic that catches the same attack in production. Findings that stay in a slide deck aren't findings.",
      "",
      "More: [blog](/blog.md) · [talks & papers](/talks.md) · [about](/about.md)",
      "",
      "- [LinkedIn](#{author["linkedin"]})",
      "- [X](#{author["x"]})",
      "- [Google Scholar](#{author["scholar"]})",
      "",
      "## Research that ships",
      "",
      posts.first(2).map { |post| post_item(post) },
      "",
      "## Latest from the blog",
      "",
      posts.first(5).map { |post| post_item(post) },
      "",
      "## What I work on",
      "",
      "Agentic red teaming at scale: prompt injection, tool misuse, memory and RAG poisoning, scenario generation, and turning research into production detections.",
      "",
      "Focus: agentic AI security, AI red teaming, prompt injection, LLM applications, knowledge graphs, GNN + NLP."
    ].flatten.join("\n")
  end

  def blog_index_md(site)
    [
      "# Writing",
      "",
      "Short notes and longer writeups on agentic AI security, red teaming, and the loop from research to detection.",
      "",
      posts_newest(site).map { |post| post_item(post) }
    ].flatten.join("\n")
  end

  def post_item(post)
    date = format_date(post.date)
    desc = one_line(post.data["description"])
    link = "[#{post.data["title"]}](#{markdown_path(post.url)})"
    desc.empty? ? "- #{link} (#{date})" : "- #{link} (#{date}): #{desc}"
  end

  def frontmatter_for(site, doc)
    data = {
      "title" => doc.data["title"] || site.config["title"],
      "canonical_url" => absolute(site, doc.url),
      "last_updated" => last_updated(site, doc)
    }
    description = one_line(
      doc.data["description"] ||
        doc.data["subtitle"] ||
        (doc.url == "/" ? site.config["description"] : nil)
    )
    data["description"] = description unless description.empty?

    "#{YAML.dump(data, line_width: -1).rstrip}\n---\n\n"
  end

  def llms_txt(site, docs)
    title = site.config["title"]
    summary = one_line(site.config["description"])
    pages, posts = docs.partition { |doc| SITE_ORDER.include?(doc.url) }

    lines = []
    lines << "# #{title}"
    lines << ""
    lines << "> #{summary}"
    lines << ""
    lines << "## Site"
    pages.each { |doc| lines << llms_item(site, doc) }
    unless posts.empty?
      lines << ""
      lines << "## Writing"
      posts.each { |doc| lines << llms_item(site, doc) }
    end
    "#{lines.join("\n")}\n"
  end

  def llms_item(site, doc)
    href = absolute(site, markdown_path(doc.url))
    title = case doc.url
            when "/" then "Home"
            when "/blog/" then "Blog"
            else doc.data["title"]
            end
    desc = one_line(doc.data["description"] || doc.data["subtitle"] || (doc.url == "/" ? site.config["description"] : nil))
    desc.empty? ? "- [#{title}](#{href})" : "- [#{title}](#{href}): #{desc}"
  end

  def llms_full(site, mirrors)
    title = site.config["title"]
    summary = one_line(site.config["description"])
    parts = ["# #{title}\n\n> #{summary}\n"]
    mirrors.each { |_doc, markdown| parts << markdown.strip }
    "#{parts.join("\n\n")}\n"
  end

  def last_updated(site, doc)
    if %w[/ /blog/].include?(doc.url) && site.posts.docs.any?
      return format_date(posts_newest(site).first.date)
    end

    value = doc.data["last_modified_at"] || doc.data["date"]
    format_date(value) || format_date(File.mtime(doc.path))
  end

  def format_date(value)
    return if value.nil?

    if value.respond_to?(:strftime)
      value.strftime("%Y-%m-%d")
    else
      Date.parse(value.to_s).strftime("%Y-%m-%d")
    end
  rescue Date::Error
    value.to_s
  end

  def one_line(text)
    text.to_s.gsub(/\s+/, " ").strip
  end

  def absolute(site, path)
    base = site.config["url"].to_s.chomp("/")
    path = path.start_with?("/") ? path : "/#{path}"
    "#{base}#{path}"
  end

  def strip_frontmatter(raw)
    raw.sub(/\A---[ \t]*\r?\n.*?\r?\n---[ \t]*\r?\n/m, "")
  end

  def expand_relative_urls(site, text)
    base = site.config["baseurl"].to_s
    text.gsub(/\{\{\s*['"]([^'"]+)['"]\s*\|\s*relative_url\s*\}\}/) do
      "#{base}#{Regexp.last_match(1)}"
    end
  end

  def write_file(site, path, content)
    dest = File.join(site.dest, path)
    FileUtils.mkdir_p(File.dirname(dest))
    File.write(dest, content)
  end
end

class AgentMarkdownUrlGenerator < Jekyll::Generator
  safe true
  priority :low

  def generate(site)
    AgentMarkdown.ordered_docs(site).each do |doc|
      doc.data["markdown_url"] = AgentMarkdown.markdown_path(doc.url)
    end
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  AgentMarkdown.write!(site)
end
