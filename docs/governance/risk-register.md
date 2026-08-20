# Risk Register

| | |
|---|---|
| **Document owner** | Aaron — Security Officer role (per [Information Security Policy](information-security-policy.md) §4) |
| **Version** | 1.1 |
| **Effective date** | 2026-08-19 (v1.1 amendments effective 2026-08-20 — see §5) |
| **Review cycle** | Annual, or after any material infrastructure change or security incident |
| **CISSP domain mapping** | Domain 1 — Security & Risk Management |

## 1. Methodology

Risk is scored **qualitatively** (Likelihood × Impact) rather than quantitatively. A true quantitative model (Single Loss Expectancy × Annualized Rate of Occurrence = Annualized Loss Expectancy) needs defensible historical loss data and asset valuations that don't exist yet at pre-revenue stage — forcing numbers there would produce false precision, not better decisions. This register is revisited toward a quantitative model once there's real incident/financial history to base one on.

**Likelihood** (1–5): 1 = Rare, 2 = Unlikely, 3 = Possible, 4 = Likely, 5 = Almost certain
**Impact** (1–5): 1 = Negligible, 2 = Minor, 3 = Moderate, 4 = Major, 5 = Severe
**Risk score** = Likelihood × Impact

| Score | Rating |
|---|---|
| 1–4 | Low |
| 5–9 | Medium |
| 10–15 | High |
| 16–25 | Critical |

**Treatment options**: Mitigate (reduce likelihood/impact via a control), Accept (retain as-is, documented rationale required), Transfer (insurance, contract terms), Avoid (eliminate the activity generating the risk).

## 2. Asset Inventory

| Asset | Classification (Policy §5) | Owner |
|---|---|---|
| data-frames.com site content + GitHub repo | Public (content) / Confidential (repo secrets, CI tokens) | Aaron |
| GitHub account (source control, Actions CI/CD) | Confidential | Aaron |
| Azure subscription (root/admin identity) | Restricted | Aaron |
| Wazuh manager (private VNet) | Confidential | Aaron |
| Metasploit lab VM(s) (private VNet) | Confidential | Aaron |
| Shuffle SOAR instance + its stored automation credentials | Restricted | Aaron |
| network-packets.com honeypot (isolated VNet) | Internal (intentionally exposed by design) | Aaron |
| Honeypot log airlock storage account (captured intelligence, append-only) | Internal | Aaron |
| GoDaddy registrar account (both domains, DNS) | Restricted | Aaron |
| Client engagement data (contracts, scope, findings, PII) | Restricted | Aaron |
| Admin workstation (used for Azure/GitHub/client access) | Restricted (by inheritance — holds keys to everything else) | Aaron |
| Credential/secrets store | Restricted | Aaron |
| Business financial records | Internal | Aaron |

## 3. Risk Register

| ID | Asset | Threat / Vulnerability | L | I | Score | Rating | Existing / Planned Controls | Treatment | Status |
|---|---|---|---|---|---|---|---|---|---|
| R-01 | Azure subscription | Compromised admin credentials (phishing, credential stuffing) → full control of Wazuh/lab/honeypot infra | 2 | 5 | 10 | High | MFA mandatory (Policy §6); no shared credentials; Key Vault for secrets; short-lived, auto-rotated service credentials in place of long-lived admin keys where Azure supports it | Mitigate | Control in place |
| R-02 | Honeypot VNet / private lab VNet boundary | Misconfigured peering/firewall rule lets a compromised honeypot pivot into the private lab VNet | 2 | 5 | 10 | High | Two-VNet architecture with no routine trust relationship between them (Policy §6); no VNet peering; honeypot→Wazuh data path via one-way storage airlock rather than a routed path; explicit cross-VNet deny rules for auditability; planned: quarterly firewall rule review | Mitigate | **Design complete 2026-08-20** — see [Network Architecture](../../infra/network-architecture.md) D-01, §6; not yet built |
| R-03 | Metasploit lab | Scope/target misconfiguration causes offensive tooling to reach a real third-party host instead of the isolated lab or an authorized client target | 2 | 5 | 10 | High | Signed rules-of-engagement required before any offensive activity (Policy §7, no exceptions); planned: **technical** control — NSG default-deny egress on the lab subnet so a mistyped target range fails closed rather than relying on operator discipline ([Network Architecture](../../infra/network-architecture.md) D-02b); planned: target-scope pre-flight checklist | Mitigate | Administrative control in place; technical control designed 2026-08-20, not yet built. **Re-score likelihood once egress deny is live** |
| R-04 | GitHub repo / CI | Leaked deploy token or overly-broad Actions permissions → malicious push to the live site | 2 | 3 | 6 | Medium | Repo is public but deploy credentials are scoped to Actions-only tokens, not personal PATs; planned: move to OIDC-based short-lived tokens minted per workflow run instead of a long-lived stored secret, so a leaked token is only useful for the remainder of that run | Mitigate | Control in place; OIDC migration planned |
| R-05 | GoDaddy registrar account | Account takeover (weak auth) → DNS hijack of data-frames.com or network-packets.com | 2 | 4 | 8 | Medium | MFA mandatory (Policy §6) | Mitigate | Control in place |
| R-06 | Client engagement data | Restricted data (findings, PII) stored on an unmanaged device or retained past the engagement | 2 | 5 | 10 | High | Classification + handling rules defined (Policy §5); planned: formal data retention/destruction schedule | Mitigate | Policy control in place; retention schedule not yet built |
| R-07 | Admin workstation | Malware/phishing compromise of the single device used to administer every system — a single point of failure for the whole business | 2 | 5 | 10 | High | MFA limits blast radius even if the device is compromised; planned: dedicated hardening baseline (disk encryption, EDR, no local admin for daily use) | Mitigate | Partially in place |
| R-08 | Wazuh manager | Unpatched vulnerability in the SIEM itself disables or blinds logging right when it's needed most | 2 | 4 | 8 | Medium | Patch cadence defined: monthly scheduled patching for Wazuh/Shuffle/lab hosts ([Network Architecture](../../infra/network-architecture.md) §9) | Mitigate | Cadence defined 2026-08-20; VM not yet built |
| R-09 | Shuffle SOAR | Compromise of Shuffle inherits every credential it holds, letting an attacker trigger actions across Wazuh/Metasploit/honeypot through one compromised component — automation concentrates blast radius | 1 | 5 | 5 | Medium | Planned: least-privilege, per-integration credentials rather than one broad service account (Policy §6) | Mitigate | Design decision for Shuffle build phase |
| R-10 | Honeypot itself being probed/attacked | Attackers interact with, scan, or attempt to compromise network-packets.com | 5 | 1 | 5 | Medium | This is the intended function of the system, not a defect — no treatment needed beyond the boundary control at R-02 | Accept | N/A — accepted by design |
| R-11 | Vendor availability (Azure, GitHub, GoDaddy) | Vendor-side outage or breach affects Data-Frames' availability or data | 2 | 3 | 6 | Medium | Static site on GitHub Pages is inherently resilient; Azure/GoDaddy single points of failure accepted at current scale | Accept | Reassess if/when revenue justifies multi-vendor redundancy |
| R-12 | Business financial records | Loss or unauthorized disclosure of internal financials | 2 | 2 | 4 | Low | Standard access control (Policy §6) sufficient at current classification | Accept | N/A |
| R-13 | network-packets.com honeypot (outbound) | Compromised honeypot is used to attack third parties from a Data-Frames-owned IP — legal/liability exposure, and a direct conflict with the Policy §7 prohibition on offensive traffic reaching unauthorized third parties | 3 | 4 | 12 | High | NSG default-deny outbound with a narrow allowlist (storage endpoint, Azure platform essentials, time-boxed update window) ([Network Architecture](../../infra/network-architecture.md) D-02a); accepted tradeoff: blocking egress reduces honeypot realism, but the attempted URL is the intelligence, not the payload; planned: Azure Firewall FQDN filtering once revenue justifies the cost | Mitigate | Identified 2026-08-20 during network architecture design; control designed, not yet built |

## 4. Review

This register is reviewed on the cadence in the header table, and immediately after: any new system is added to the asset inventory, any control listed as "Planned" is completed (update Status), or any security incident occurs (per Policy §9). Risk acceptance decisions (Accept rows) are re-affirmed at each review, not left to expire silently.

## 5. Change Log

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-08-19 | Initial register (R-01 through R-12) |
| 1.1 | 2026-08-20 | Amended following CISSP Domain 3/4 network architecture design ([infra/network-architecture.md](../../infra/network-architecture.md)). **Added R-13** — compromised honeypot attacking third parties, a gap not covered by R-02 (inward pivot) or R-10 (being attacked). Added the honeypot log airlock storage account to the asset inventory. Updated R-02 (design complete, one-way data path), R-03 (technical egress control designed; likelihood to be re-scored once live), and R-08 (patch cadence defined). |
