# Business Continuity Plan / Disaster Recovery Plan (BCP/DRP)

| | |
|---|---|
| **Document owner** | Aaron — Security Officer role (per [Information Security Policy](information-security-policy.md) §4) |
| **Version** | 1.0 |
| **Effective date** | 2026-08-19 |
| **Review cycle** | Annual, or after any disaster invoking this plan, or any material infrastructure change |
| **CISSP domain mapping** | Domain 1 — Security & Risk Management (BC/DR planning) |
| **Depends on** | [Risk Register](risk-register.md) §2–3 for asset inventory and impact ratings |

## 1. Purpose and Scope

This plan defines how Data-Frames recovers systems and continues operating after a disruptive event — from a single-system outage up to loss of the entire Azure subscription. It complements the [Information Security Policy](information-security-policy.md) (§9–10), which establishes the *obligation* to have this plan; this document is the plan itself.

**Business Continuity (BC)** = keeping the business operating (client commitments, the public site) during a disruption.
**Disaster Recovery (DR)** = restoring the underlying systems to normal.

## 2. Business Impact Analysis (BIA)

RTO (Recovery Time Objective) = how long a system can be down before the impact is unacceptable.
RPO (Recovery Point Objective) = how much data loss (measured in time) is tolerable.

| System | RTO | RPO | Rationale |
|---|---|---|---|
| data-frames.com (GitHub Pages) | Near-zero | Near-zero | Static site; GitHub Pages SLA is high, and every git clone is a full backup — recovery is a redeploy, not a restore |
| GitHub repo / CI | 4 hours | Near-zero | Distributed by nature (any local clone has full history); recreate the remote and re-point CI if GitHub itself is unavailable |
| Azure subscription (root/admin) | 24 hours | N/A (identity, not data) | Not yet revenue-critical, but blocks all lab/SIEM/honeypot work until restored |
| Wazuh manager | 48 hours | 24 hours | Detection capability, not yet monitoring live client environments — degraded visibility is tolerable short-term, not indefinitely |
| Metasploit lab | 48 hours | 24 hours | Rebuildable from scratch if needed; not holding irreplaceable state |
| Shuffle SOAR (once built) | 24 hours | 24 hours | Automation pauses; manual response substitutes short-term |
| network-packets.com honeypot | 72 hours | Continuous (see §3) | Lowest operational urgency of the infra — it's a demo/detection asset, not core to keeping the business running. Captured intelligence is the thing that must not be lost even if the VM itself is |
| GoDaddy registrar / DNS | 4 hours | N/A (config, not data) | High business impact if unavailable during an active DNS issue (site/email unreachable) — fast recovery matters even though it's rarely touched |
| Client engagement data (once operational) | 8 hours during an active engagement | Near-zero | Blocks active client work directly; must be stored somewhere synced/versioned, never solely on one device |
| Admin workstation | 24 hours (replacement device operational) | N/A | See §4 — no Restricted/Confidential data or the only copy of a credential may live *only* on this device, precisely so its RPO can be N/A |

## 3. Backup Strategy

- **Website/repo**: git itself is the backup (distributed, every clone is complete). No separate backup process needed.
- **Azure VMs (Wazuh, Metasploit lab, Shuffle)**: daily automated snapshot once built (network architecture phase) — not yet in place, tracked as risk register R-08 dependency.
- **Honeypot captured data**: forwarded continuously to a store outside the honeypot VNet (e.g., the Wazuh manager or a separate storage account) rather than left only on the honeypot VM — so a honeypot rebuild never loses the intelligence that justified running it. Not yet implemented; design requirement for the honeypot build phase.
- **DNS records**: exported/documented outside the registrar (so a GoDaddy account issue doesn't also destroy the record of what the records *were*). Not yet implemented — add to the network architecture phase.
- **Credentials/secrets**: password manager / Azure Key Vault, never solely on the admin workstation (Policy §6, this doc §4).
- **Client data**: synced/versioned storage, never solely on one device, per the Restricted-data handling rules in Policy §5.

## 4. Design Principle: No Single Point of Total Failure

The admin workstation is a known single point of *access* (risk register R-07) — but it must never become a single point of *data loss*. Every credential, every piece of Confidential/Restricted data, and every configuration must be recoverable from somewhere other than that one device (Key Vault, password manager, git, cloud storage). If the workstation is destroyed today, the answer to "what's permanently lost" should always be "nothing, only time."

## 5. Disaster Scenarios and Response

### 5.1 Azure region outage
Affects Wazuh, Metasploit lab, Shuffle, honeypot if co-located in one region. **Response**: check Azure Status; at current lab/pre-revenue scale, waiting for Microsoft's own recovery is an accepted posture (documented, not silent) rather than paying for multi-region redundancy. Reassess this acceptance once a paying client's monitoring depends on live uptime.

### 5.2 GitHub / GitHub Pages outage
**Response**: monitor GitHub Status; no action typically needed given the near-zero RTO tolerance — communicate proactively only if a client demo is scheduled during the window.

### 5.3 Honeypot compromise attempts pivot into the private lab VNet (ties to risk register R-02)
**Response**: the VNet segmentation is the primary control. If Wazuh alerts on unexpected lateral traffic from the honeypot VNet: isolate the honeypot VNet immediately, verify no lateral movement succeeded, rotate any credential that was reachable from that boundary even if unconfirmed, rebuild the honeypot from a clean image, run a post-incident review updating the risk register.

### 5.4 Admin workstation compromise (ties to risk register R-07)
**Response**: disconnect the device from the network immediately. Rotate every credential accessible from it — Azure, GitHub, GoDaddy, Key Vault/password manager master credential — treating "possibly exposed" as "assume exposed." Rebuild the device from a clean image; re-enroll MFA rather than restoring old device state.

### 5.5 DNS hijack via registrar account takeover (ties to risk register R-05)
**Response**: regain registrar account control via GoDaddy support and MFA recovery. Restore DNS records from the documented backup (§3). Monitor for residual malicious DNS caching post-recovery. Notify any active clients if trust in the domain during the window is a concern for them.

### 5.6 Client Restricted-data breach during an active engagement (ties to risk register R-06)
**Response**: activate incident response per Policy §9 (triage within 4 hours). Scope the breach, preserve evidence before remediating, notify the affected client per their engagement agreement and any applicable regulatory breach-notification window (e.g., HIPAA for a healthcare client), then run a post-incident review that updates the risk register and this plan if it revealed a gap.

## 6. Roles and Activation

| Role | Responsibility during a disaster |
|---|---|
| Business Owner | Declares the disaster, decides on client communication and any risk-acceptance tradeoffs made under time pressure |
| System Administrator | Executes technical recovery per §5 |
| Incident Responder | Leads response specifically for security-incident-triggered disasters (§5.3, §5.4, §5.5, §5.6) |

All three roles are currently Aaron. **This is itself an accepted limitation**, not an oversight: at single-operator scale, recovery is inherently serial (one person can't isolate a breach and communicate with a client simultaneously). Revisit this once the business has a second person who can hold any one of these roles independently — that's the point at which "all roles = Aaron" stops being an acceptable answer to a CISSP-style "who executes this in parallel" question.

## 7. Communication Plan

- **Internal**: none required beyond the Business Owner being informed — there's no one else yet.
- **Client-facing**: per the notification timeline in the specific engagement agreement, and never later than the legally required breach-notification window for the client's industry/jurisdiction (Policy §12).
- **Public-facing**: only if the marketing site itself is down during a period where prospective clients would notice (e.g., an active sales conversation) — a brief, honest status note is preferable to silence.

## 8. Testing and Review

- **Tabletop exercise**: annual, minimum — walk through each scenario in §5 on paper and confirm the plan still matches reality (this is possible today even before all the infrastructure exists).
- **Technical DR test**: once the Azure infrastructure is built (network architecture phase), simulate an actual VM loss and time the real restore against the RTO/RPO targets in §2 — a plan that's never been tested against real numbers is a guess, not a plan.
- Any gap found during testing, or any real invocation of this plan, triggers an update to this document and the risk register before the next scheduled review.
