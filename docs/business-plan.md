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

Both registered at GoDaddy. All infrastructure — Wazuh manager, Metasploit lab, honeypot, website hosting — runs on a single Azure IaaS subscription, split across two isolated VNets: one private for Wazuh + the Metasploit lab, one separate for the public honeypot. Version control via GitHub's free tier.

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
| 2 | Network architecture | Domain 3 — Security Architecture & Engineering (+ Domain 4 — Communication & Network Security) | Design drafted 2026-08-20 ([infra/network-architecture.md](../infra/network-architecture.md)) — 4 decisions pending ruling; nothing provisioned yet |
| 3 | IAM | Domain 5 — Identity & Access Management | Not started |
| 4 | Wazuh + website | Domain 7 — Security Operations (partly) | Website done (redesigned + branded 2026-08-19); Wazuh not started |
| 5 | Metasploit lab | Domain 6 — Security Assessment & Testing | Not started (decision made: Framework over Pro) |
| 6 | Shuffle SOAR | Domain 7 — Security Operations | Not started |
| 7 | Honeypot go-live | Domain 7 — Security Operations | Not started |
| 8 | Ongoing operations | Domain 7 / Domain 8 — Security Operations, Software Development Security | Not started |

Domain 8 (Software Development Security) has the thinnest coverage in this sequence — worth deliberate attention since no phase maps to it directly.

## CISSP tie-in

Aaron is studying for the CISSP exam alongside this build (failed a first attempt on 2026-07-09; his own diagnosis is that the gap is scenario-question parsing under exam conditions, not content recall — he already scores well on Anki drilling from the OSG study guide and practice tests). The intent is to pair each build phase with focused study and scenario-style practice questions on the matching domain, rather than treating the business build and exam prep as separate tracks.

Build order can be re-prioritized once Aaron's ISC2 score report domain breakdown (weak vs. near-proficient vs. strong per domain) is available — right now the sequence above is convenience-ordered (matches the original brainstorm), not weakness-ordered.

## Open questions / deferred decisions

- **Governance docs format** — will be produced as both Markdown (source of truth, versioned in `docs/governance/`) and exported `.docx` copies for formal/audit-ready use.
- **Website format** — single self-contained HTML/CSS/JS file (matches the original concept: dark navy/cyan theme, live-scrolling signal log in the hero, services grid, 5-step engagement process, pricing section).
- **Subagent team** — planned: Alert Triage, Playbook/IR Drafting, Compliance Mapping, Client Reporting, Patch Tracking, as `.claude/agents/` Markdown files, plus a scheduled agent (via Shuffle) that generates client reports by actively triggering Wazuh/Metasploit/honeypot tools through the Claude API. Design deliberately deferred — more planning wanted before building this out.
