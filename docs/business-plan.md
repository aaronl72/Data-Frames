# Data-Frames — Business Plan

## Overview & positioning

Data-Frames is a solo-operator IT/cybersecurity consulting business. The pitch: **enterprise-level security at SMB-affordable pricing.**

Target markets:
- SMBs generally
- Small healthcare practices (HIPAA angle)
- Legal and accounting firms
- Small manufacturers with supply-chain exposure

## Domains & infrastructure

| Domain | Purpose |
|---|---|
| `data-frames.com` | Business site — services, pricing, contact |
| `network-packets.com` | Public honeypot, used as a live client-facing sales demo (kept isolated from the main site) |

Both registered at GoDaddy.

**Azure vs. budget VPS — evaluated and settled 2026-08-20.** Budget VPS providers are genuinely cheaper on raw compute (Hetzner CX22 at roughly €4.50/mo and DigitalOcean/Vultr at $24/mo for 2 vCPU / 4 GB, against ~$30/mo for an Azure B2s before disks, egress, and IPs). Azure was kept anyway, for three reasons:

1. **Acceptable use.** The lab both runs Metasploit and operates a public honeypot that attracts attack traffic. Hetzner monitors aggressively for scanning and has suspended servers within 1–2 hours of a port scan starting; DigitalOcean's AUP requires written permission for penetration testing with no documented process to obtain it. Azure explicitly permits testing against your own resources under its Rules of Engagement. The cheap option is cheap until the lab is used for what it exists to do.
2. **The Phase 2 design depends on Azure-native constructs** — VNets/NSGs for R-02 isolation, the storage-account airlock for D-01, free Bastion Developer for D-03, Azure Backup for D-04, NSG flow logs for §7. The principles are provider-agnostic; the implementation and the Bicep are not, and would be rebuilt by hand with nftables, a self-managed bastion, and scripted backups. Free Bastion Developer also offsets part of the price gap, since a VPS would otherwise mean exposed SSH or a self-built bastion.
3. **Commercial fit.** Target clients (healthcare, legal, accounting SMBs) are overwhelmingly Microsoft 365 shops, so Azure fluency transfers directly into client engagements.

**Self-hosting on a home connection was also considered and rejected 2026-08-20.** ISP static IPs are typically a business-tier add-on costing more than Azure's ~$4/mo, and hosting the honeypot at home would place a machine expected to be compromised on the same connection as the admin workstation (R-07), geolocate a deliberately-attacked system to Aaron's home address, put R-13 outbound traffic in his own name, and likely breach residential ISP acceptable-use terms. The internet-facing honeypot stays in Azure. The *lab*, which needs isolation rather than exposure, remains a candidate for local hardware â a host-only virtual network gives R-03 a stronger guarantee than an NSG rule, at no monthly cost.

A cheap VPS remains a reasonable fit for one narrow job — nginx serving the marketing site to produce real access logs as a Wazuh source — since that involves no offensive traffic and no honeypot, and therefore no AUP friction. All infrastructure — Wazuh manager, Metasploit lab, honeypot, website hosting — runs on a single Azure IaaS subscription, split across two isolated VNets: one private for Wazuh + the Metasploit lab, one separate for the public honeypot. Version control via GitHub's free tier.

## Tool stack

| Tool | Role | Why |
|---|---|---|
| **Wazuh** | SIEM / detection | Core defense layer, drives alerting |
| **Metasploit Framework** | Offense / pentesting | Chosen over Metasploit Pro (~$15K/yr) — Pro's automated reporting, audit trail, and multi-host automation only earn their cost on live paid client engagements, not a private lab/demo. Revisit Pro once there are paying pentest clients. |
| **Shuffle** | SOAR / automated response | Executes playbooks in response to Wazuh alerts — distinct layer from Wazuh (detection) and Metasploit (offense); one doesn't replace the others |
| **T-Pot / Cowrie** | Honeypot | Public-facing deception layer on network-packets.com, separate from the Metasploit lab |

## Pricing (CAD, monthly)

| Tier | Price |
|---|---|
| Essentials | $500–1,500 |
| Standard | $1,500–3,500 |
| Premium | $3,500+ |
| Honeypot / deception add-on | $300–800 |

Based on Canadian MSSP market research (from earlier planning).

## Build sequence

Prior work (a draft website, two governance docs) only ever existed as artifacts inside a Claude Desktop conversation and had to be rebuilt here from scratch.

| # | Phase | CISSP Domain | Status |
|---|---|---|---|
| 1 | Governance | Domain 1 — Security & Risk Management | Markdown deliverables complete 2026-08-19 (Info Security Policy, Risk Register, BCP/DRP) — branded `.docx` exports still pending |
| 2 | Network architecture | Domain 3 — Security Architecture & Engineering (+ Domain 4 — Communication & Network Security) | Design complete ([infra/network-architecture.md](../infra/network-architecture.md)) — **v1.1**, five decisions accepted; D-05 added 2026-08-20 and D-01 amended. Bicep written for VNets/subnets/NSGs **plus the storage airlock and a custom append-only role** ([infra/bicep/](../infra/bicep/)). **Nothing deployed — templates have never been compiled or run.** |
| 3 | IAM | Domain 5 — Identity & Access Management | Not started |
| 4 | Wazuh + website | Domain 7 — Security Operations (partly) | Website done (redesigned + branded 2026-08-19); Wazuh not started |
| 5 | Metasploit lab | Domain 6 — Security Assessment & Testing | Not started (decision made: Framework over Pro) |
| 6 | Shuffle SOAR | Domain 7 — Security Operations | Not started |
| 7 | Honeypot go-live | Domain 7 — Security Operations | Not started |
| 8 | Ongoing operations | Domain 7 / Domain 8 — Security Operations, Software Development Security | Not started |

Domain 8 (Software Development Security) has the thinnest coverage in this sequence — worth deliberate attention since no phase maps to it directly.

### Schedule constraint — CISSP boot camp, 2026-09-07 to early November

An 8-week CISSP boot camp starts **7 September 2026** ($500 CAD, on top of the $1,500 exam fee). It will consume the time the build would otherwise take, so **Phases 3 to 7 are deferred to November.**

One exception, decided 2026-08-21: **the honeypot is deployed before the boot camp starts, not after.** It is the only component that produces value unattended — it collects into the airlock whether or not anyone is watching, at roughly $20/month. Deploying it in the ~17 days before 7 September means emerging from the boot camp in November with **around ten weeks of real attack data already captured**, instead of starting a 30-day collection clock from zero. Total cost of doing so is about $50, against $2,000 already committed to the certification.

It also pairs with the study rather than competing with it: Domain 7 (Security Operations) covers honeypots, detection and incident response, and having a live one running during that module is applied practice rather than a distraction.

**This requires a heartbeat.** An Azure Monitor alert on *"no new blob written to the capture container in 24 hours"* — monitoring the outcome rather than the VM, since that single signal catches a stopped VM, a crashed Cowrie, a broken managed identity, a misconfigured NSG, or a full disk. Without it, an unattended honeypot that dies in week two is not discovered until November.

The airlock read path is **not** configured during this period. Wazuh does not exist yet, so `labEgressIpAddress` is left empty — writes from the honeypot subnet only, no IP rule to go stale while unattended.

**Deliberately not done during the boot camp:** further refinement of the planning documents. Planning is materially complete; the gap is that nothing runs. Short, bounded items only — the contact form fix, the SPF verification, and the governance `.docx` exports.

## CISSP tie-in

Aaron is studying for the CISSP exam alongside this build (failed a first attempt on 2026-07-09; his own diagnosis is that the gap is scenario-question parsing under exam conditions, not content recall — he already scores well on Anki drilling from the OSG study guide and practice tests). The intent is to pair each build phase with focused study and scenario-style practice questions on the matching domain, rather than treating the business build and exam prep as separate tracks.

Build order can be re-prioritized once Aaron's ISC2 score report domain breakdown (weak vs. near-proficient vs. strong per domain) is available — right now the sequence above is convenience-ordered (matches the original brainstorm), not weakness-ordered.

## Open questions / deferred decisions

- **Governance docs format** — will be produced as both Markdown (source of truth, versioned in `docs/governance/`) and exported `.docx` copies for formal/audit-ready use.
- **Website format** — single self-contained HTML/CSS/JS file (matches the original concept: dark navy/cyan theme, live-scrolling signal log in the hero, services grid, 5-step engagement process, pricing section).
- **Subagent team** — planned: Alert Triage, Playbook/IR Drafting, Compliance Mapping, Client Reporting, Patch Tracking, as `.claude/agents/` Markdown files, plus a scheduled agent (via Shuffle) that generates client reports by actively triggering Wazuh/Metasploit/honeypot tools through the Claude API. Design deliberately deferred — more planning wanted before building this out.
