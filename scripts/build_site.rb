#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "cgi"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
SITE = File.join(ROOT, "site")
TOOLS_DIR = File.join(SITE, "tools")
COMPARISONS_DIR = File.join(SITE, "comparisons")
BASE_PATH = ENV.fetch("BASE_PATH", "").sub(%r{/\z}, "")
CHECKOUT_URL = ENV.fetch("CHECKOUT_URL", "https://buy.stripe.com/4gMcN562o9Lo05reOD3sI11")

FileUtils.mkdir_p([SITE, TOOLS_DIR, COMPARISONS_DIR])

def read_csv(path)
  CSV.read(path, headers: true).map(&:to_h)
end

TOOLS = read_csv(File.join(ROOT, "data", "tools.csv")).to_h { |row| [row.fetch("slug"), row] }
COMPARISONS = read_csv(File.join(ROOT, "data", "comparisons.csv"))
OFFERS = read_csv(File.join(ROOT, "data", "offers.csv"))

def h(value)
  CGI.escapeHTML(value.to_s)
end

def u(path)
  "#{BASE_PATH}#{path}"
end

def page(title:, description:, body:)
  <<~HTML
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>#{h(title)}</title>
        <meta name="description" content="#{h(description)}">
        <link rel="stylesheet" href="#{u("/styles.css")}">
      </head>
      <body>
        <header class="topbar">
          <a class="brand" href="#{u("/")}">AI Operator Stack</a>
          <nav aria-label="Primary">
            <a href="#{u("/diagnostic.html")}">$499 Diagnostic</a>
            <a href="#{u("/offers/restaurant-ai-call-leak-diagnostic.html")}">Call Leak Audit</a>
            <a href="#{u("/comparisons/best-restaurant-ai-phone-agents.html")}">Restaurant AI</a>
            <a href="#{u("/comparisons/openclaw-alternatives-for-business-automation.html")}">OpenClaw Alternatives</a>
            <a href="#{u("/comparisons/best-n8n-workflows-for-lead-routing.html")}">n8n Workflows</a>
          </nav>
        </header>
        #{body}
        <footer class="footer">
          <p>Affiliate disclosure: this site may earn commissions when readers apply for or purchase tools through listed partner links. Recommendations are based on use case fit, public program details, and operator practicality.</p>
        </footer>
      </body>
    </html>
  HTML
end

def tool_card(tool)
  href = u("/tools/#{h(tool.fetch("slug"))}.html")
  <<~HTML
    <article class="card">
      <p class="eyebrow">#{h(tool.fetch("category"))}</p>
      <h3><a href="#{href}">#{h(tool.fetch("name"))}</a></h3>
      <p>#{h(tool.fetch("positioning"))}</p>
      <dl>
        <div><dt>Best for</dt><dd>#{h(tool.fetch("ideal_customer"))}</dd></div>
        <div><dt>Affiliate</dt><dd>#{h(tool.fetch("commission"))}</dd></div>
      </dl>
    </article>
  HTML
end

def cta(tool)
  label = tool.fetch("affiliate_status") == "available" ? "View partner page" : "View product"
  <<~HTML
    <a class="button" href="#{h(tool.fetch("affiliate_url"))}" rel="nofollow sponsored">#{label}</a>
  HTML
end

def write(path, content)
  File.write(path, content)
end

def render_index
  featured = COMPARISONS.first(6).map do |comparison|
    <<~HTML
      <a class="link-card" href="#{u("/comparisons/#{h(comparison.fetch("slug"))}.html")}">
        <span>#{h(comparison.fetch("category"))}</span>
        <strong>#{h(comparison.fetch("title"))}</strong>
        <small>#{h(comparison.fetch("summary"))}</small>
      </a>
    HTML
  end.join

  offer_cards = OFFERS.map do |offer|
    <<~HTML
      <a class="link-card" href="#{u("/offers/#{h(offer.fetch("slug"))}.html")}">
        <span>#{h(offer.fetch("price"))}</span>
        <strong>#{h(offer.fetch("title"))}</strong>
        <small>#{h(offer.fetch("pain"))}</small>
      </a>
    HTML
  end.join

  body = <<~HTML
    <main>
      <section class="hero">
        <div>
          <p class="eyebrow">AI workflow diagnostics for specific revenue leaks</p>
          <h1>Fix the automation handoff that is costing calls, leads, or follow-up.</h1>
          <p class="lede">Choose a focused $499 diagnostic for restaurant AI calls, n8n revenue workflows, or OpenClaw-style agent operations. The comparison library supports the recommendation; the paid offer fixes one concrete workflow.</p>
          <div class="actions">
            <a class="button" href="#{u("/offers/ai-workflow-quick-teardown.html")}">$49 Quick Teardown</a>
            <a class="button secondary" href="#{u("/offers/restaurant-ai-call-leak-diagnostic.html")}">Restaurant Call Leak Audit</a>
            <a class="button secondary" href="#{u("/offers/n8n-revenue-workflow-diagnostic.html")}">n8n Revenue Workflow</a>
            <a class="button secondary" href="#{u("/offers/openclaw-agent-ops-diagnostic.html")}">OpenClaw Agent Ops</a>
          </div>
        </div>
      </section>
      <section class="band">
        <div class="section-heading">
          <p class="eyebrow">Same-day offers</p>
          <h2>Specific diagnostics convert better than generic AI help</h2>
        </div>
        <div class="link-grid">#{offer_cards}</div>
      </section>
      <section class="band">
        <div class="section-heading">
          <p class="eyebrow">Money pages</p>
          <h2>Comparison pages built for buyer intent</h2>
        </div>
        <div class="link-grid">#{featured}</div>
      </section>
      <section class="band muted">
        <div class="section-heading">
          <p class="eyebrow">Tool database</p>
          <h2>Tracked offers and traffic targets</h2>
        </div>
        <div class="grid">#{TOOLS.values.map { |tool| tool_card(tool) }.join}</div>
      </section>
    </main>
  HTML

  write(File.join(SITE, "index.html"), page(
    title: "AI Operator Stack: n8n Workflows, OpenClaw Alternatives, Restaurant AI Tools",
    description: "Compare practical AI tools for automation workflows, OpenClaw alternatives, and restaurant AI use cases.",
    body: body
  ))
end

def render_tool(tool)
  related = COMPARISONS.select { |comparison| comparison.fetch("tools").split("|").include?(tool.fetch("slug")) }
  related_links = related.map do |comparison|
    %(<li><a href="#{u("/comparisons/#{h(comparison.fetch("slug"))}.html")}">#{h(comparison.fetch("title"))}</a></li>)
  end.join

  body = <<~HTML
    <main>
      <section class="article-hero">
        <p class="eyebrow">#{h(tool.fetch("category"))}</p>
        <h1>#{h(tool.fetch("name"))} Review: Best Use Cases, Affiliate Details, and Alternatives</h1>
        <p class="lede">#{h(tool.fetch("positioning"))}</p>
        <div class="actions">#{cta(tool)}</div>
      </section>
      <article class="article">
        <h2>Who #{h(tool.fetch("name"))} is best for</h2>
        <p>#{h(tool.fetch("name"))} is strongest for #{h(tool.fetch("primary_use"))}. The best-fit buyer is #{h(tool.fetch("ideal_customer"))}.</p>
        <h2>Affiliate and pricing notes</h2>
        <p>Current affiliate status: <strong>#{h(tool.fetch("affiliate_status"))}</strong>. Public commission detail: <strong>#{h(tool.fetch("commission"))}</strong>. Pricing note: #{h(tool.fetch("pricing_note"))}.</p>
        <p>Source checked: <a href="#{h(tool.fetch("source_url"))}">#{h(tool.fetch("source_url"))}</a>.</p>
        <h2>Related comparisons</h2>
        <ul>#{related_links}</ul>
      </article>
    </main>
  HTML

  write(File.join(TOOLS_DIR, "#{tool.fetch("slug")}.html"), page(
    title: "#{tool.fetch("name")} Review and Affiliate Details",
    description: "#{tool.fetch("name")} review for #{tool.fetch("primary_use")}, including best-fit customers and affiliate details.",
    body: body
  ))
end

def render_comparison(comparison)
  tools = comparison.fetch("tools").split("|").map { |slug| TOOLS[slug] }.compact
  rows = tools.map do |tool|
    <<~HTML
      <tr>
        <td><a href="#{u("/tools/#{h(tool.fetch("slug"))}.html")}">#{h(tool.fetch("name"))}</a></td>
        <td>#{h(tool.fetch("primary_use"))}</td>
        <td>#{h(tool.fetch("ideal_customer"))}</td>
        <td>#{h(tool.fetch("commission"))}</td>
      </tr>
    HTML
  end.join

  recommendations = tools.map do |tool|
    <<~HTML
      <section>
        <h2>Choose #{h(tool.fetch("name"))} when...</h2>
        <p>#{h(tool.fetch("positioning"))}</p>
        <p>Affiliate status: #{h(tool.fetch("affiliate_status"))}. Source: <a href="#{h(tool.fetch("source_url"))}">program details</a>.</p>
        #{cta(tool)}
      </section>
    HTML
  end.join

  body = <<~HTML
    <main>
      <section class="article-hero">
        <p class="eyebrow">#{h(comparison.fetch("category"))}</p>
        <h1>#{h(comparison.fetch("title"))}</h1>
        <p class="lede">#{h(comparison.fetch("summary"))}</p>
      </section>
      <article class="article">
        <h2>Quick verdict</h2>
        <p>For #{h(comparison.fetch("intent"))}, start by matching the tool to the operational constraint: technical workflow control, restaurant call handling, menu modernization, or non-technical automation.</p>
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Tool</th>
                <th>Primary use</th>
                <th>Best customer</th>
                <th>Public affiliate detail</th>
              </tr>
            </thead>
            <tbody>#{rows}</tbody>
          </table>
        </div>
        #{recommendations}
      </article>
    </main>
  HTML

  write(File.join(COMPARISONS_DIR, "#{comparison.fetch("slug")}.html"), page(
    title: comparison.fetch("title"),
    description: comparison.fetch("summary"),
    body: body
  ))
end

def render_diagnostic
  body = <<~HTML
    <main>
      <section class="article-hero">
        <p class="eyebrow">Same-day paid offer</p>
        <h1>AI Workflow Revenue Diagnostic</h1>
        <p class="lede">A $499 operator review for one AI workflow, affiliate funnel, or restaurant AI stack. Built for teams that need a short path from confusing automation ideas to a deployable revenue workflow.</p>
        <div class="actions">
          <a class="button" href="#{h(CHECKOUT_URL)}">Book for $499</a>
          <a class="button secondary" href="#{u("/comparisons/best-restaurant-ai-phone-agents.html")}">See restaurant AI research</a>
        </div>
      </section>
      <article class="article">
        <h2>What the buyer gets today</h2>
        <ul>
          <li>One workflow or funnel audit across intake, qualification, handoff, tracking, and follow-up.</li>
          <li>A prioritized fix list with the highest-leverage automation first.</li>
          <li>A simple implementation map for n8n, OpenClaw-style agents, or restaurant AI tooling.</li>
          <li>Affiliate and vendor recommendations only where the tool fit is defensible.</li>
          <li>A checkout-confirmed intake path and written close packet.</li>
        </ul>
        <h2>Best fit</h2>
        <p>This is for founders, operators, consultants, and agencies who already know there is money in the workflow but do not have a reliable system for turning buyer intent into tracked action.</p>
        <h2>Not a fit</h2>
        <p>This is not a generic AI brainstorming call, a guaranteed SEO ranking promise, or a claim that a tool will produce revenue without distribution.</p>
        <div class="actions">
          <a class="button" href="#{h(CHECKOUT_URL)}">Book the diagnostic</a>
        </div>
      </article>
    </main>
  HTML

  write(File.join(SITE, "diagnostic.html"), page(
    title: "AI Workflow Revenue Diagnostic",
    description: "Book a same-day AI workflow revenue diagnostic for affiliate funnels, n8n automations, OpenClaw alternatives, or restaurant AI stacks.",
    body: body
  ))
end

def render_offer(offer)
  deliverables = offer.fetch("deliverables").split("|").map { |item| "<li>#{h(item)}</li>" }.join
  body = <<~HTML
    <main>
      <section class="article-hero">
        <p class="eyebrow">$#{h(offer.fetch("price"))} same-day diagnostic</p>
        <h1>#{h(offer.fetch("title"))}</h1>
        <p class="lede">For #{h(offer.fetch("audience"))}: #{h(offer.fetch("pain"))}.</p>
        <div class="actions">
          <a class="button" href="#{h(offer.fetch("checkout_url"))}">Book for $#{h(offer.fetch("price"))}</a>
          <a class="button secondary" href="#{u("/diagnostic.html")}">General diagnostic</a>
        </div>
      </section>
      <article class="article">
        <h2>Why this is urgent</h2>
        <p>#{h(offer.fetch("proof_angle"))}. The point is not to buy another AI tool. The point is to find the exact workflow break and define the first fix that can be implemented.</p>
        <h2>Deliverables</h2>
        <ul>#{deliverables}</ul>
        <h2>How it closes</h2>
        <p>After checkout, the buyer sends the current URL, workflow, vendor stack, or process notes. The output is a written diagnostic and implementation-ready close packet for one workflow.</p>
        <div class="actions">
          <a class="button" href="#{h(offer.fetch("checkout_url"))}">Book #{h(offer.fetch("title"))}</a>
        </div>
      </article>
    </main>
  HTML

  offers_dir = File.join(SITE, "offers")
  FileUtils.mkdir_p(offers_dir)
  write(File.join(offers_dir, "#{offer.fetch("slug")}.html"), page(
    title: offer.fetch("title"),
    description: "#{offer.fetch("title")} for #{offer.fetch("audience")}: #{offer.fetch("pain")}.",
    body: body
  ))
end

render_index
render_diagnostic
OFFERS.each { |offer| render_offer(offer) }
TOOLS.values.each { |tool| render_tool(tool) }
COMPARISONS.each { |comparison| render_comparison(comparison) }

puts "Built #{TOOLS.length} tool pages, #{COMPARISONS.length} comparison pages, #{OFFERS.length} offer pages, and 1 diagnostic page into #{SITE}"
