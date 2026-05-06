# AI Operator Stack

Programmatic SEO affiliate site for practical AI tools:

- n8n workflows
- OpenClaw alternatives
- restaurant AI tools

The site is static and CSV-backed so content can be refreshed weekly without editing individual HTML pages.

## Build

```bash
ruby scripts/build_site.rb
```

Output lands in:

```text
site/
```

Open `site/index.html` locally or serve the folder with any static host.

## Content Sources

- Tool/program facts: `data/tools.csv`
- Programmatic comparison pages: `data/comparisons.csv`
- Social distribution copy: `data/social_posts.csv`
- Affiliate URL register: `sales/affiliate_links.md`

## Operating Loop

The execution loop is tracked in:

```text
sales/ralph_loop.md
scripts/ralph_revenue_loop.rb
reports/gtm/2026-05-06-money-today/operator-close-packet.md
```

The loop rebuilds pages, writes a content report, and stages social posts for Zernio publishing.
