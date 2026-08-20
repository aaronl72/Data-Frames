// Data-Frames network foundation — build order steps 1-2
// See ../network-architecture.md for the design and the decisions behind it.
//
// Deploys ONLY networking: two isolated VNets, their subnets, and NSGs.
// No VMs, no Bastion, no storage account. Everything here is free.
//
// The two VNets are deployed into SEPARATE resource groups deliberately.
// It is not cosmetic: it means an RBAC assignment scoped to one resource
// group cannot reach the other, so the separation holds at the control
// plane as well as the data plane (risk register R-02, Policy section 6).

targetScope = 'subscription'

@description('Azure region. Canada Central chosen for data residency and because Bastion Developer SKU is available there (decision D-03).')
param location string = 'canadacentral'

@description('Short environment suffix used in resource names.')
param env string = 'prod'

@description('Inbound ports deliberately exposed on the honeypot. Deliberately narrow to start; widen at the honeypot build phase (Phase 7) once T-Pot service coverage is chosen.')
param honeypotExposedPorts array = [
  '22'
  '23'
  '80'
  '443'
  '445'
  '3389'
]

var tags = {
  project: 'Data-Frames'
  managedBy: 'bicep'
  reference: 'infra/network-architecture.md'
}

// ---------------------------------------------------------------------------
// Resource groups
// ---------------------------------------------------------------------------

resource rgLab 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-df-lab-${env}'
  location: location
  tags: union(tags, { zone: 'private-lab' })
}

resource rgHoneypot 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-df-honeypot-${env}'
  location: location
  tags: union(tags, { zone: 'honeypot-isolated' })
}

// ---------------------------------------------------------------------------
// Networks
// ---------------------------------------------------------------------------

module labNetwork 'modules/lab-network.bicep' = {
  name: 'deploy-lab-network'
  scope: rgLab
  params: {
    location: location
    env: env
    tags: union(tags, { zone: 'private-lab' })
  }
}

module honeypotNetwork 'modules/honeypot-network.bicep' = {
  name: 'deploy-honeypot-network'
  scope: rgHoneypot
  params: {
    location: location
    env: env
    tags: union(tags, { zone: 'honeypot-isolated' })
    exposedPorts: honeypotExposedPorts
    labAddressSpace: labNetwork.outputs.addressSpace
  }
}

// NOTE: there is deliberately NO virtualNetworkPeering resource anywhere in
// this template. Risk register R-02 forbids a trust path between these two
// VNets, and BCP section 5.3 names that segmentation as THE control that
// stops a honeypot pivot. If a future change adds peering here, it should be
// treated as a governance change requiring a risk register amendment, not as
// a routine infrastructure edit.

output labVnetId string = labNetwork.outputs.vnetId
output honeypotVnetId string = honeypotNetwork.outputs.vnetId
output labResourceGroup string = rgLab.name
output honeypotResourceGroup string = rgHoneypot.name
