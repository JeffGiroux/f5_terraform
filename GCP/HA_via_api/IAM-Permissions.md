# Permissions for BIG-IP Standalone Deployment

The access below was requested during Terraform deployment by my service account. Your permissions may or may not be different depending on the items you are trying to deploy.

Terraform Deployment - service account
```
compute.addresses.create
compute.addresses.delete
compute.addresses.get
compute.addresses.use
compute.disks.create
compute.forwardingRules.create
compute.forwardingRules.delete
compute.forwardingRules.get
compute.instances.create
compute.instances.delete
compute.instances.get
compute.instances.setMetadata
compute.instances.setLabels
compute.instances.setServiceAccount
compute.instances.setTags
compute.instances.use
compute.instances.updateNetworkInterface
compute.subnetworks.use
compute.subnetworks.useExternalIp
compute.targetInstances.create
compute.targetInstances.delete
compute.targetInstances.get
compute.targetInstances.use
compute.zones.get
iam.serviceAccounts.actAs
iam.serviceAccounts.get
iam.serviceAccounts.list
resourcemanager.projects.get
```