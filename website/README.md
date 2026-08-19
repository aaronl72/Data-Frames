# Website

The Data-Frames marketing site — `index.html`, a single self-contained HTML/CSS/JS file. Live at https://aaronl72.github.io/Data-Frames/, auto-deployed via `.github/workflows/deploy-pages.yml` on every push touching this folder.

Design: light/off-white "editorial boutique consulting" theme (serif display headings, deep teal accent) — deliberately not a dark navy/cyan "hacker/SOC" look, since the target audience is non-technical SMB owners (healthcare, legal, manufacturing). Sections: hero with live-scrolling signal log, services grid, 5-step engagement process, About (founder narrative + credentials), FAQ, an honestly-labeled "building our track record" placeholder (no fabricated testimonials/case studies), pricing, contact form.

Status: redesigned 2026-08-19 (first pass was 2026-08-18, dark theme). Still needed before this can go fully live:
- Contact form has no backend — submitting just shows a client-side "thanks" message, nothing is actually sent anywhere yet. Needs wiring to a real endpoint (e.g. an email service or Azure Function) before launch.
- Credentials section leads with "30+ years in IT & Security" and lists CISSP as "in progress," per Aaron's decision not to imply certification before it's official — revisit once he passes, along with adding his license number.
- Custom domain (data-frames.com) intentionally not yet connected — deferred until the CISSP pass/license-number update, done as one combined pass.
- "Results" section placeholder should be replaced with real case studies once there are actual clients, or tied more concretely to the network-packets.com live demo once that's built.
