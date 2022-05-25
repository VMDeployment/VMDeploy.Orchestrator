# Changelog

## ???

+ New: Compontent DeploymentData - Gather and persist information for individual deployments
+ New: Command Get-VmoDynamicGuestOSProfile - Retrieve dynamically configured GuestOSProfiles
+ New: Command Get-VmoDynamicHardwareProfile - Retrieve dynamically configured Hardware Profiles
+ Upd: New-VmoVirtualMachine - added support for dynamically selected GuestOSProfiles and Hardware Profiles based on templates selected.
+ Upd: New-VmoVirtualMachine - added validation for name and computername, limiting input length to 15 characters.
+ Upd: Bootstrap for guest - better tooling
+ Fix: New-PdkFile - change in parameter name would cause deployment of shielded VMs to fail on Server 2016 or older servers.

## 1.0.0 (2021-04-07)

+ Initial Release
