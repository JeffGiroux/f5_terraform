# Deploying F5 in Google GCP with Terraform
The GCP folder contains various deployments. All deployments utilize the F5 Automation Toolchain components for Declarative Onboarding (DO for L1-L3) and Application Services (AS3 for L4-L7) in order to asist in onboarding the BIG-IP and configuration. Telemtry Streaming (TS for analytics/logging) is also installed and ready for use.

  - **[Standalone](Standalone)** (updated June 2020) <br> This Terraform plan uses the Googlerm provider to build the necessary Google objects and a standalone BIG-IP device with 2-NICs. Traffic flows from client to F5 to backend app servers.
