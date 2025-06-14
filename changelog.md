# Changelog - azure.synapse.tools

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [0.26.0] - 2025-06-05
* Fixed: Supports for Az.Accounts v.5.0 and its breaking change in terms of `Get-AzAccessToken` #41 (thanks [vi7us](https://github.com/vi7us) !)

## [0.25.0] - 2025-01-12
* Fixed: bug where updating values on Managed Private Endpoints failed while using JSON config file.

## [0.24.0] - 2024-03-26
* Incremental Deployment #30. Creates and updates a deployment state file in a storage account. See [readme](README.md#incremental-deployment) for details.

## [0.23.0] - 2024-03-25
* Added: DeleteIfNotInSource. Deletes objects in target Synapse workspace that does not exist in the source. Note: Credential objects are not yet supported.

## [0.22.0] - 2023-07-29
* Fixed: Deployment fails for pipeline with single element in an array after update of properties (#15)
* Updated links to AzurePlayer after renranding this year

## [0.21.0] - 2022-05-30
* Fixed: Support dynamic references from pipeline's execute notebook activity (#13)
* Fixed: `Get-SynapseObjectBy` internal functions to support notebooks
* Added first unit tests

## [0.20.0] - 2022-05-23
* Spark Job Definition objects are supported now

## [0.19.0] - 2022-05-23
* Pretending that Spark pool exists in order to deploy referring objects (#11)

## [0.18.0] - 2022-01-20
* Fixed Stop/Start triggers while publishing (#8)
* Added Start-SynapseTriggers cmdlet

## [0.17.0] - 2022-01-19
* Added cmdlet generates dependencies diagram (Get-SynapseDocDiagram)
* Fixed issue #7: Replacing all properties environment-related fails

## [0.16.0] - 2022-01-15
* Fixed multiple issues (#1)

## [0.15.0] - 2022-01-15
### Added
* Added support for: (being deployed via Rest API)
  * SQL Scripts 
  * KQL Scripts
  * Notebooks

