# Data-Frames

IT/cybersecurity consulting business (solo operator, Aaron) targeting SMB clients. Two domains: `data-frames.com` (business site) and `network-packets.com` (public honeypot used as a client-facing sales demo). See [docs/business-plan.md](docs/business-plan.md) for the full plan — positioning, pricing, tool stack, and the phased build sequence. Treat that file as the source of truth; update it as decisions change rather than letting this file and the plan drift apart.

## Tool stack

- **Wazuh** — SIEM/detection
- **Metasploit Framework** — offense/pentesting (chosen over Metasploit Pro; Pro's automated reporting/audit trail only pays off on live paid engagements, not this private lab/demo)
- **Shuffle** — open-source SOAR, drives automated response playbooks
- **T-Pot / Cowrie** — honeypot platform (separate layer from Metasploit)

All infrastructure runs on one Azure IaaS subscription, two isolated VNets (Wazuh + lab private, honeypot separate).

## Repo layout

- `docs/business-plan.md` — the plan (positioning, pricing, stack, build sequence)
- `docs/governance/` — CISSP Domain 1 deliverables (Information Security Policy, BCP/DRP)
- `website/` — the Data-Frames marketing site
- `infra/` — Azure/network configuration
- `.claude/agents/` — the planned subagent team (Alert Triage, Playbook/IR Drafting, Compliance Mapping, Client Reporting, Patch Tracking)

## CISSP study pairing

Aaron is studying for the CISSP exam (failed a first attempt; diagnosed gap is scenario-question parsing, not content recall — more practice with realistic exam-style scenarios helps more than flashcard drilling). Each build phase is paired with its matching CISSP domain in `docs/business-plan.md` — when working a phase, treat it as an opportunity to reinforce that domain, not just ship the deliverable.
