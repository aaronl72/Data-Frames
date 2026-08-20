# Website — build notes

Notes on the Data-Frames marketing site. **These live in `docs/` deliberately, not in `website/`.**

The Pages workflow publishes the entire `website/` folder, so anything placed there is served publicly. A `README.md` previously sat in that folder and was reachable at `https://data-frames.com/README.md`, where it told any visitor that the contact form had no backend, that the CISSP was "in progress," and that the case studies were placeholders. Moved out 2026-08-20. Keep build notes, TODOs, and anything candid out of `website/`.

## What it is

[`website/index.html`](../website/index.html) — a single self-contained HTML/CSS/JS file.

**Live at https://data-frames.com** (custom domain connected 2026-08-20; `www` and apex both serve, HTTP 301s to HTTPS). Auto-deployed via [`.github/workflows/deploy-pages.yml`](../.github/workflows/deploy-pages.yml) on every push touching `website/`.

`website/CNAME` must stay in that folder — with Actions-based Pages deployment the file has to be inside the published artifact, not at the repo root, or Pages serves 404 for the custom domain. (It contains only the domain name, which is public, so it being served is harmless.)

Design: light/off-white "editorial boutique consulting" theme (serif display headings, deep teal accent) — deliberately not a dark navy/cyan "hacker/SOC" look, since the target audience is non-technical SMB owners (healthcare, legal, manufacturing). Sections: hero with live-scrolling signal log, services grid, Who We Serve, Our Toolset, 5-step engagement process, About (founder narrative + credentials), FAQ, an honestly-labeled "building our track record" placeholder (no fabricated testimonials/case studies), pricing, contact form.

Supporting files: `404.html` (branded), `robots.txt`, `sitemap.xml`, `assets/og-image.png` (1200×630 social card), `assets/logos/` (Wazuh, Metasploit, Shuffle, T-Pot).

---

## Outstanding

### Blocking a real launch

- **The contact form discards every submission.** It calls `preventDefault()`, shows *"Thanks — we'll be in touch shortly."*, and resets. No `action`, no `fetch`, no `mailto`. Enquiries are lost while the visitor is told they succeeded — worse than having no form. This is the site's only conversion path. Options: a form backend service (Formspree/Web3Forms — free tiers, ~5 min, but a third party then holds client enquiries, which interacts with Policy §5 data handling); a `mailto:` submission (no third party, but exposes the address to scrapers and needs a configured mail client); replacing the form with direct contact details; or at minimum changing the copy so it stops claiming success.
- **No privacy policy exists.** Nothing is currently collected, so nothing is being mishandled — but a security and compliance consultancy with no privacy policy is a gap a healthcare or legal prospect may check. Becomes strictly necessary if any cookie-based analytics is added.

### Visitor tracking — nothing in place

GitHub Pages exposes **no server logs**, so there is no IP or visitor data available, retroactively or going forward. Anything must be added deliberately:

| Approach | Gives | Raw IPs | Cost |
|---|---|---|---|
| Cloudflare Web Analytics, GoatCounter, Plausible, Fathom | Pageviews, referrers, country, device | No, by design | Free to ~$9/mo |
| Google Analytics 4 | Behaviour and funnels | No (anonymised) | Free, needs cookie consent |
| Cloudflare proxying the site | Edge analytics, bot/threat data, basic WAF | Cloudflare sees them; you get aggregates | Free tier; nameservers move to Cloudflare |
| Self-hosted Umami/Matomo on Azure | Whatever is configured; data is yours | **Yes** | Azure compute |
| Move hosting (Azure Static Web Apps, VM + nginx) | Real access logs | **Yes** | Varies; loses free Pages hosting |

Only the last two yield IP-level data. Note the tie-in with later phases: self-hosted analytics or nginx access logs are a log source Wazuh can ingest, making the marketing site a monitored asset and a live demo of the SIEM. Also note that collecting visitor IPs makes Data-Frames a collector of personal information under PIPEDA, with retention and disclosure obligations that clients in regulated sectors will ask about.

### QA not yet performed

The 2026-08-20 pass covered HTTP status, links and anchors, image assets, mixed content, meta tags, accessibility markup, tag structure, redirects, DNS, and which files the artifact exposes. It did **not** cover:

- **Visual rendering** — viewport meta and media queries are present, but the page has never been rendered at mobile widths to confirm it actually looks right
- **Colour contrast** — one WCAG contrast failure was fixed in the 2026-08-19 round; the rest of the palette has not been re-verified against the CSS variables
- **Copy proofreading** — no spelling or grammar pass has been done on the prose

### Waiting on the CISSP result

- Credentials section leads with "30+ years in IT & Security" and lists CISSP as "in progress," per Aaron's decision not to imply certification before it's official. Revisit on a pass, along with adding the license number.
- "Results" placeholder should become real case studies once there are clients, or tie to the `network-packets.com` live demo once built.

---

## Fixed 2026-08-20

**Custom domain connected.** Nine DNS records at GoDaddy (4 × A, 4 × AAAA, 1 × `www` CNAME), custom domain set in Pages, Enforce HTTPS on. Required adding `CNAME` inside `website/` — see above.

**QA pass (commit `988309a`).** Contact form had zero `<label>` elements (placeholder-only labelling fails WCAG 1.3.1/3.3.2) — added visually-hidden labels bound to real ids, wrapped inputs in `.field` divs to preserve the two-column grid, added `role="status" aria-live="polite"`. Inputs had no `name` attributes, so nothing would submit even with a backend — added, with `autocomplete` hints. Added `og:url`, `og:image`, `og:site_name`, Twitter card tags, and a canonical link, plus a generated `og-image.png`. Added `robots.txt`, `sitemap.xml`, and a branded `404.html`.

**Build notes removed from the published artifact.** See the note at the top.
