# Bicep — network foundation

Implements **steps 1–2** of the build order in [`../network-architecture.md`](../network-architecture.md) §12: two isolated VNets, their subnets, and the NSG rule set from §6.

**Nothing here has been deployed.** These templates are written and reviewable but have never been run — see [Validation status](#validation-status) below.

## What this deploys

| Resource | Cost |
|---|---|
| 2 resource groups | Free |
| 2 VNets, 5 subnets | Free |
| 6 NSGs with the §6 rule set | Free |
| Storage service endpoints | Free |

**The entire deployment is free.** VNets, subnets, NSGs, and service endpoints carry no charge — cost begins with VMs (§11). That is why the network foundation is a safe first step: it can be deployed, inspected, verified, and torn down without spending anything.

Not included, and deliberately so: no VMs, no Bastion, no storage account, no public IPs, and **no VNet peering** (R-02).

## Why Bicep rather than az CLI scripts

Three reasons that matter to this specific project:

1. **The NSG rules become a reviewable document.** R-02's control includes a quarterly firewall rule review. Reviewing a declarative file in git — with rules named `Deny-Outbound-Internet-R13` and comments citing the risk they implement — is a genuinely different activity from clicking through the portal.
2. **Idempotent.** Re-running converges to the declared state instead of erroring or duplicating, so the file stays the truth about what is deployed.
3. **No state file.** Unlike Terraform, Bicep reads current state from Azure itself — one less thing to store, secure, and back up for a solo operator.

The tradeoff: it is a DSL to learn. The files are heavily commented for that reason, and every non-obvious rule cites the risk register entry or design decision it implements.

## Prerequisites

Azure CLI is **not currently installed** on this machine (`az` was not found). Install it first:

```powershell
winget install -e --id Microsoft.AzureCLI
```

Then, in a new shell:

```powershell
az login
az account show                      # confirm the right subscription
az bicep install                     # Bicep compiler, bundled with az
```

## Deploy

Always what-if first. It shows exactly what would change without changing anything:

```powershell
az deployment sub what-if `
  --location canadacentral `
  --template-file infra/bicep/main.bicep
```

Read that output before proceeding. Then:

```powershell
az deployment sub create `
  --location canadacentral `
  --name df-network-foundation `
  --template-file infra/bicep/main.bicep
```

## Verify — build order step 9

§12 step 9 is **not optional**: it is the test that proves R-02 and D-02a are real rather than merely intended. Run these before any VM exists, and again after the honeypot is built but *before* it is exposed.

Check the effective rules Azure actually computed, rather than trusting the template:

```powershell
# Honeypot NSG: confirm outbound Internet is denied and the lab VNet deny exists
az network nsg rule list `
  --resource-group rg-df-honeypot-prod `
  --nsg-name nsg-df-honeypot-prod `
  --query "[?direction=='Outbound'].{name:name, priority:priority, access:access, dest:destinationAddressPrefix}" `
  --output table

# Lab NSG: confirm the R-03 egress deny is present
az network nsg rule list `
  --resource-group rg-df-lab-prod `
  --nsg-name nsg-df-lab-prod `
  --query "[?name=='Deny-Outbound-Internet-R03']" `
  --output table

# Confirm NO peering exists on either VNet - both must return empty
az network vnet peering list --resource-group rg-df-lab-prod --vnet-name vnet-df-lab-prod --output table
az network vnet peering list --resource-group rg-df-honeypot-prod --vnet-name vnet-df-honeypot-prod --output table
```

Once VMs exist, `az network watcher test-ip-flow` verifies the path end to end rather than the rule text — that is the check that actually closes step 9.

## Validation status

**These templates have not been compiled, deployed, or tested.** Azure CLI is not installed here, so `az bicep build` could not be run against them and no syntax or API-version error would have surfaced yet. Treat the first `what-if` as the real review, and expect to fix something.

Specific things to confirm on first deployment:

- **API versions** (`2024-05-01`) are available in your subscription
- **`AzurePlatformDNS` / `AzurePlatformIMDS` service tags** behave as expected once VMs exist. Denying all Internet egress can break DNS resolution and platform health if these allows are wrong — this is the single most likely thing to need adjustment
- **Bastion Developer SKU deploys independently into both VNets** (flagged as *verify at build* in D-03)
- **Honeypot exposed ports** — `honeypotExposedPorts` is deliberately narrow to start; widen at Phase 7 once T-Pot service coverage is chosen

## Next steps (build order §3 onward)

Not yet written: Bastion Developer (step 3), the storage airlock with append-only SAS (step 4), Wazuh VM (step 5), NSG flow logs into Wazuh (step 6), backup policies and golden images (step 7), and the DNS export (step 8).

Step 6 matters more than its position suggests: BCP §5.3's response begins *"If Wazuh alerts on unexpected lateral traffic from the honeypot VNet."* Until flow logs reach Wazuh, that trigger condition can never fire.
