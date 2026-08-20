# Infra

Azure IaaS configuration for Data-Frames: two isolated VNets (Wazuh + Metasploit lab private, honeypot separate).

- [x] [`network-architecture.md`](network-architecture.md) — design drafted 2026-08-20 (CISSP Domains 3 & 4). **Four decisions pending a ruling** (§5): honeypot→Wazuh log path, egress control, admin access, backup/imaging
- [ ] Provision anything in Azure — deliberately blocked until §5 is settled
- [ ] `dns/` — GoDaddy zone exports for both domains (BCP §3 assigns this to this phase)

See [../docs/business-plan.md](../docs/business-plan.md) for the infrastructure overview and phase sequence.
