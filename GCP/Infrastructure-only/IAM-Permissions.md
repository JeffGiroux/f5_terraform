# Permissions for Infrastructure-Only Deployment

The access below was requested during Terraform deployment by my service account. Your permissions may or may not be different depending on the items you are trying to deploy.

Terraform Deployment - service account
```
compute.firewalls.create
compute.firewalls.delete
compute.firewalls.get
compute.networks.create
compute.networks.delete
compute.networks.get
compute.networks.updatePolicy
compute.subnetworks.create
compute.subnetworks.delete
compute.subnetworks.get
storage.buckets.create
storage.buckets.delete
storage.buckets.get
storage.buckets.getIamPolicy
storage.objects.delete
storage.objects.list
```