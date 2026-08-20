// Private lab VNet — Wazuh, Metasploit lab, Shuffle
// Design: ../../network-architecture.md section 4.1 and section 6

@description('Azure region.')
param location string

@description('Short environment suffix used in resource names.')
param env string

@description('Tags applied to every resource.')
param tags object

var addressSpace = '10.10.0.0/16'
var snetWazuh = '10.10.1.0/24'
var snetLab = '10.10.2.0/24'
var snetShuffle = '10.10.3.0/24'
var snetMgmt = '10.10.4.0/24'

// 10.10.250.0/26 is RESERVED for AzureBastionSubnet and deliberately not
// deployed. Bastion Developer SKU (decision D-03) needs no subnet, but a later
// upgrade to Basic/Standard/Premium requires one and downgrades are not
// supported. Reserving the range now means that upgrade is additive rather
// than a re-addressing exercise on a live lab.

// ---------------------------------------------------------------------------
// NSG: Wazuh manager
// ---------------------------------------------------------------------------

resource nsgWazuh 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-df-wazuh-${env}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        // Agent traffic from the lab subnet ONLY - not VNet-wide. Least
        // privilege applied to a network path (design principle 3).
        name: 'Allow-WazuhAgent-From-Lab'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: snetLab
          sourcePortRange: '*'
          destinationAddressPrefix: snetWazuh
          destinationPortRanges: [ '1514', '1515' ]
          description: 'Wazuh agent enrollment and event traffic from snet-lab only'
        }
      }
      {
        name: 'Deny-Inbound-Internet'
        properties: {
          priority: 4000
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          description: 'No public management plane (design principle 4). Admin access is via Bastion.'
        }
      }
      {
        // Wazuh PULLS honeypot logs from the storage airlock (decision D-01).
        // The lab side initiates; the honeypot side never does. Direction of
        // initiation is the control.
        name: 'Allow-Outbound-Storage'
        properties: {
          priority: 1000
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: snetWazuh
          sourcePortRange: '*'
          destinationAddressPrefix: 'Storage'
          destinationPortRange: '443'
          description: 'Pull honeypot logs from the append-only storage airlock (D-01)'
        }
      }
      {
        name: 'Allow-Outbound-AzurePlatformDNS'
        properties: {
          priority: 1010
          direction: 'Outbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'AzurePlatformDNS'
          destinationPortRange: '*'
          description: 'Azure platform DNS. Required or the VM cannot resolve anything.'
        }
      }
      {
        name: 'Allow-Outbound-AzurePlatformIMDS'
        properties: {
          priority: 1020
          direction: 'Outbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'AzurePlatformIMDS'
          destinationPortRange: '*'
          description: 'Instance metadata service. Required for platform health and agent operation.'
        }
      }
      {
        name: 'Deny-Outbound-Internet'
        properties: {
          priority: 4010
          direction: 'Outbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRange: '*'
          description: 'Fail secure (design principle 2). Relax deliberately and temporarily for patching windows (section 9).'
        }
      }
    ]
  }
}

// ---------------------------------------------------------------------------
// NSG: Metasploit lab — the R-03 control
// ---------------------------------------------------------------------------

resource nsgLab 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-df-lab-${env}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Deny-Inbound-Internet'
        properties: {
          priority: 4000
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          description: 'No public management plane (design principle 4)'
        }
      }
      {
        // Attacker VM to targets, within the lab subnet. This is where all
        // offensive traffic is intended to stay.
        name: 'Allow-Outbound-IntraSubnet'
        properties: {
          priority: 1000
          direction: 'Outbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: snetLab
          sourcePortRange: '*'
          destinationAddressPrefix: snetLab
          destinationPortRange: '*'
          description: 'Metasploit attacker to lab targets'
        }
      }
      {
        name: 'Allow-Outbound-WazuhAgent'
        properties: {
          priority: 1010
          direction: 'Outbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: snetLab
          sourcePortRange: '*'
          destinationAddressPrefix: snetWazuh
          destinationPortRanges: [ '1514', '1515' ]
          description: 'Wazuh agents on lab hosts report to the manager'
        }
      }
      {
        name: 'Allow-Outbound-AzurePlatformDNS'
        properties: {
          priority: 1020
          direction: 'Outbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'AzurePlatformDNS'
          destinationPortRange: '*'
          description: 'Azure platform DNS'
        }
      }
      {
        name: 'Allow-Outbound-AzurePlatformIMDS'
        properties: {
          priority: 1030
          direction: 'Outbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'AzurePlatformIMDS'
          destinationPortRange: '*'
          description: 'Instance metadata service'
        }
      }
      {
        // THE R-03 CONTROL.
        //
        // Risk R-03's only prior control was administrative: "signed
        // rules-of-engagement required before any offensive activity."
        // That does not stop a typo'd CIDR in an msfconsole target range.
        // This rule does: a mistyped target fails closed instead of
        // reaching a real third party (decision D-02b, Policy section 7).
        //
        // Removing this rule is a governance decision, not a convenience.
        name: 'Deny-Outbound-Internet-R03'
        properties: {
          priority: 4010
          direction: 'Outbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRange: '*'
          description: 'R-03: offensive tooling must never reach a third party. Relax only in a deliberate, time-boxed patching window, then re-tighten.'
        }
      }
    ]
  }
}

// ---------------------------------------------------------------------------
// NSGs: Shuffle and management (placeholders, same fail-secure posture)
// ---------------------------------------------------------------------------

resource nsgShuffle 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-df-shuffle-${env}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Deny-Inbound-Internet'
        properties: {
          priority: 4000
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          description: 'Phase 6 will add the specific rules Shuffle needs. Default-deny until then.'
        }
      }
    ]
  }
}

resource nsgMgmt 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-df-mgmt-${env}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Deny-Inbound-Internet'
        properties: {
          priority: 4000
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          description: 'Reserved subnet, nothing deployed. Default-deny.'
        }
      }
    ]
  }
}

// ---------------------------------------------------------------------------
// VNet
// ---------------------------------------------------------------------------

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-df-lab-${env}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [ addressSpace ]
    }
    subnets: [
      {
        name: 'snet-wazuh'
        properties: {
          addressPrefix: snetWazuh
          networkSecurityGroup: { id: nsgWazuh.id }
          // Service endpoint so the Wazuh pull of honeypot logs traverses the
          // Azure backbone rather than the public internet (decision D-01).
          serviceEndpoints: [ { service: 'Microsoft.Storage' } ]
        }
      }
      {
        name: 'snet-lab'
        properties: {
          addressPrefix: snetLab
          networkSecurityGroup: { id: nsgLab.id }
        }
      }
      {
        name: 'snet-shuffle'
        properties: {
          addressPrefix: snetShuffle
          networkSecurityGroup: { id: nsgShuffle.id }
        }
      }
      {
        name: 'snet-mgmt'
        properties: {
          addressPrefix: snetMgmt
          networkSecurityGroup: { id: nsgMgmt.id }
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output addressSpace string = addressSpace
