# Infra

Azure IaaS configuration for Data-Frames: two isolated VNets (Wazuh + Metasploit lab private, honeypot separate).

- [x] [`network-architecture.md`](network-architecture.md) — **v1.0, all four decisions accepted 2026-08-20** (CISSP Domains 3 & 4)
- [x] [`bicep/`](bicep/) — build order steps 1–2: VNets, subnets, NSGs. **Written, never deployed or compiled**
- [ ] Deploy the network foundation (free — VNets/subnets/NSGs carry no charge) and run the §12 step 9 verification
- [ ] Steps 3–8: Bastion Developer, storage airlock, Wazuh VM, NSG flow logs, backup/golden images
- [ ] `dns/` — GoDaddy zone exports for both domains (BCP §3 assigns this to this phase)

**Nothing is provisioned in Azure yet.** Azure CLI is not installed on the workstation — see [`bicep/README.md`](bicep/README.md) for prerequisites and the deploy/verify commands.

See [../docs/business-plan.md](../docs/business-plan.md) for the infrastructure overview and phase sequence.
