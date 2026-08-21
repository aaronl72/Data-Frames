// Data-Frames network foundation — build order steps 1-2
// See ../network-architecture.md for the design and the decisions behind it.
//
// Deploys the network layer plus the airlock: two isolated VNets with their
// subnets and NSGs, the storage account that carries honeypot data one way,
// and the custom append-only role that constrains what the honeypot can do
// to it. No VMs and no Bastion — those are built by hand first, then
// templated once their real requirements are known rather than guessed.
//
// Cost: VNets, subnets, NSGs and role definitions are free. The storage
// account bills only for what is stored (pennies at honeypot log volumes),
// so the whole template can be deployed long before any VM exists.
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

@description('Public IP of the lab side while Wazuh runs locally on Hyper-V (decision D-05). Leave empty once Wazuh moves into the lab VNet and reaches the airlock over a service endpoint instead.')
param labEgressIpAddress string = ''

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

// The airlock belongs to NEITHER side, so it gets its own resource group for
// the same reason the two VNets do: an RBAC assignment scoped to the honeypot
// resource group must not reach the storage account, because the honeypot is
// the side we expect to be compromised (decision D-01).
resource rgAirlock 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-df-airlock-${env}'
  location: location
  tags: union(tags, { zone: 'airlock' })
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

// ---------------------------------------------------------------------------
// Airlock — the one-way data path (decision D-01)
// ---------------------------------------------------------------------------

module airlock 'modules/storage-airlock.bicep' = {
  name: 'deploy-storage-airlock'
  scope: rgAirlock
  params: {
    location: location
    env: env
    tags: union(tags, { zone: 'airlock' })
    honeypotSubnetId: honeypotNetwork.outputs.honeypotSubnetId
    labEgressIpAddress: labEgressIpAddress
  }
}

// ---------------------------------------------------------------------------
// Append-only role (decision D-01)
// ---------------------------------------------------------------------------
//
// Azure's built-in storage roles are all too broad for this job. The narrowest,
// Storage Blob Data Contributor, still grants read and delete — which would
// hand a compromised honeypot the ability to read back and destroy the very
// evidence it was capturing.
//
// This role grants exactly two data actions: create a blob, and append to one.
// No read, no list, no delete. It is what makes the D-01 blast-radius claim
// literally true rather than aspirational.
//
// Assignment happens at honeypot VM build time, scoped to the airlock storage
// account and granted to the VM's system-assigned managed identity. Using a
// managed identity rather than a SAS means there is no credential written to
// disk on the machine we expect to be compromised, and nothing to rotate.

resource appendOnlyRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(subscription().id, 'df-honeypot-append-only')
  properties: {
    roleName: 'Data-Frames Honeypot Append-Only (${env})'
    description: 'Append and create blobs only. No read, list, or delete. See infra/network-architecture.md D-01.'
    type: 'CustomRole'
    assignableScopes: [ subscription().id ]
    permissions: [
      {
        actions: []
        notActions: []
        dataActions: [
          'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/add/action'
          'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/write/action'
        ]
        notDataActions: []
      }
    ]
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
output airlockResourceGroup string = rgAirlock.name
output airlockStorageAccount string = airlock.outputs.storageAccountName
output airlockContainer string = airlock.outputs.containerName

@description('Custom append-only role. Assign this to the honeypot VM managed identity, scoped to the airlock storage account, at VM build time.')
output appendOnlyRoleId string = appendOnlyRole.id
