# Deploying F5 in AWS with Terraform
The AWS folder contains various deployments. All deployments utilize the F5 Automation Toolchain components for Declarative Onboarding (DO for L1-L3) and Application Services (AS3 for L4-L7) in order to asist in onboarding the BIG-IP and configuration. Telemetry Streaming (TS for analytics/logging) is also installed and ready for use.

  - **[Infrastructure Only](Infrastructure-only)** (updated March 2021) <br> This Terraform plan uses the AWS provider to build the basic infrastructure with VPC networks, subnets, routes, and internet gateway. Start here if you don't have an existing AWS network stack yet, and then move on to the other templates below. This will build one VPC with three subnets: mgmt, external, internal.
