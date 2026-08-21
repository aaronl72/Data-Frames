// Storage airlock — the one-way data path out of the honeypot VNet.
// Design: ../../network-architecture.md decision D-01.
//
// This resource is the entire reason R-02 and BCP section 3 can both be true
// at once. The honeypot appends captured intelligence here; Wazuh separately
// reads it. There is no route between the two VNets, and neither side holds a
// credential that works on the other.
//
// It is deployed into its OWN resource group, belonging to neither side. That
// follows the same reasoning main.bicep applies to the two VNets: an RBAC
// assignment scoped to the honeypot resource group must not reach the airlock,
// because the honeypot is the side expected to be compromised.

@description('Azure region.')
param location string

@description('Short environment suffix used in resource names.')
param env string

@description('Tags applied to every resource.')
param tags object

@description('Resource ID of the honeypot subnet. A service endpoint from this subnet is the ONLY network path in for writes.')
param honeypotSubnetId string

@description('Public IP address of the lab side, when Wazuh runs locally rather than in Azure (decision D-05). Leave empty once Wazuh is in the lab VNet and reaches storage over a service endpoint instead.')
param labEgressIpAddress string = ''

@description('Days captured intelligence is held immutable. BCP section 2 rates the honeypot RPO as Continuous — this is what makes that true even when the VM is destroyed.')
param immutableRetentionDays int = 90

// Storage account names: lowercase alphanumeric only, 3-24 chars, and globally
// unique. uniqueString() keeps it deterministic per subscription+RG rather than
// forcing a manually-chosen name that may already be taken.
var storageName = 'stdfairlock${env}${uniqueString(resourceGroup().id)}'
var containerName = 'honeypot-capture'

resource airlock 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: take(storageName, 24)
  location: location
  tags: union(tags, { zone: 'airlock', role: 'one-way-log-transfer' })
  sku: {
    // LRS is deliberate. This holds attacker telemetry that is already
    // duplicated at the point of capture and is not business-critical
    // (BCP section 2 rates honeypot RTO at 72 hours, the most relaxed of any
    // system). Paying for geo-redundancy here protects nothing.
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'

    // No anonymous access to any container, ever.
    allowBlobPublicAccess: false

    // The single most important line in this file.
    //
    // Shared key access disabled means the storage ACCOUNT KEY does not work,
    // and neither does any SAS signed with it. Every caller must authenticate
    // as an Entra identity and pass an RBAC check.
    //
    // This is what makes the D-01 claim literally true: fully compromise the
    // honeypot and the attacker holds a managed-identity token scoped to
    // "append blobs to one container", not a key that opens the account.
    // It also removes the credential-rotation problem D-01 described, because
    // there is no long-lived credential left to rotate.
    allowSharedKeyAccess: false

    networkAcls: {
      // Deny by default. Both entries below are explicit exceptions.
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          // The honeypot's write path. Traffic stays on the Azure backbone and
          // never traverses the public internet.
          id: honeypotSubnetId
          action: 'Allow'
        }
      ]
      ipRules: empty(labEgressIpAddress) ? [] : [
        {
          // Wazuh's read path WHILE IT RUNS LOCALLY (D-05).
          //
          // Known weakness, stated rather than hidden: a residential IP is
          // dynamic, so this rule goes stale without warning and reads start
          // failing. It is a availability nuisance, not a security hole —
          // an attacker who guesses the address still faces the RBAC check.
          // Delete this rule entirely once Wazuh moves into the lab VNet.
          value: labEgressIpAddress
          action: 'Allow'
        }
      ]
    }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: airlock
  name: 'default'
  properties: {
    // Versioning means an append-only credential cannot overwrite history:
    // a write against an existing blob creates a new version rather than
    // replacing the old one.
    isVersioningEnabled: true
    deleteRetentionPolicy: {
      enabled: true
      days: 30
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 30
    }
  }
}

resource captureContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: containerName
  properties: {
    publicAccess: 'None'
    metadata: {
      purpose: 'honeypot-capture-one-way'
      reference: 'network-architecture.md D-01'
    }
  }
}

resource immutability 'Microsoft.Storage/storageAccounts/blobServices/containers/immutabilityPolicies@2023-05-01' = {
  parent: captureContainer
  name: 'default'
  properties: {
    immutabilityPeriodSinceCreationInDays: immutableRetentionDays

    // Append is permitted while immutable — that is the whole point. New
    // evidence can be added; existing evidence cannot be altered or deleted,
    // including by whoever holds the honeypot's credential.
    allowProtectedAppendWrites: true
  }
}

// NOTE: this policy is created UNLOCKED. Unlocked policies can be shortened or
// removed, which is correct while the lab is being learned — a locked policy
// cannot be reversed by anyone, including Microsoft, and would mean paying to
// store mistakes for the full retention period. Lock it deliberately, later,
// if captured data ever needs to survive a compelled deletion.

@description('Name of the airlock storage account.')
output storageAccountName string = airlock.name

@description('Resource ID of the airlock storage account. Used to scope role assignments at VM build time.')
output storageAccountId string = airlock.id

@description('Container the honeypot appends to and Wazuh reads from.')
output containerName string = containerName
