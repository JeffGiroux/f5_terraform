# Permissions for Infrastructure-Only Deployment

The access below was requested during Terraform deployment by my service account. Your permissions may or may not be different depending on the items you are trying to deploy.

Terraform Deployment - service account
```
compute.firewalls.create
compute.firewalls.delete
compute.networks.create
compute.networks.delete
compute.networks.updatePolicy
compute.subnetworks.create
compute.subnetworks.delete
storage.buckets.create
storage.buckets.delete
storage.buckets.getIamPolicy
```