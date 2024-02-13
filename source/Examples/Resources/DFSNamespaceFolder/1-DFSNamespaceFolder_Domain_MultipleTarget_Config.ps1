<#PSScriptInfo
.VERSION 1.0.0
.GUID c99703be-abb1-424a-a856-b69af295ccfe
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT Copyright the DSC Community contributors. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/DfsDsc/blob/main/LICENSE
.PROJECTURI https://github.com/dsccommunity/DfsDsc
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES First version.
.PRIVATEDATA 2019-Datacenter,2019-Datacenter-Server-Core
#>

#Requires -module DfsDsc

<#
    .DESCRIPTION
        Create an AD Domain V2 based DFS namespace called software in the domain contoso.com with
        four targets on the servers ca-fileserver, ma-fileserver, ny-fileserver01 and ny-filerserver02. It also
        creates a IT folder in each namespace. The ny-fileserver02 IT folder target's state is configured to be offline.

#>
Configuration DFSNamespaceFolder_Domain_MultipleTarget_Config
{
    param
    (
        [Parameter()]
        [PSCredential]
        $Credential
    )

    Import-DscResource -ModuleName 'DFSDsc'

    Node localhost
    {
        <#
            Install the Prerequisite features first
            Requires Windows Server 2012 R2 Full install
        #>
        WindowsFeature RSATDFSMgmtConInstall
        {
            Ensure = 'Present'
            Name = 'RSAT-DFS-Mgmt-Con'
        }

        WindowsFeature DFS
        {
            Name = 'FS-DFS-Namespace'
            Ensure = 'Present'
        }

       # Configure the namespace
        DFSNamespaceRoot DFSNamespaceRoot_Domain_Software_CA
        {
            Path                 = '\\contoso.com\software'
            State                = 'Online'
            TargetPath           = '\\ca-fileserver\software'
            Ensure               = 'Present'
            Type                 = 'DomainV2'
            Description          = 'AD Domain based DFS namespace for storing software installers'
            PsDscRunAsCredential = $Credential
        } # End of DFSNamespaceRoot Resource

        DFSNamespaceRoot DFSNamespaceRoot_Domain_Software_MA
        {
            Path                 = '\\contoso.com\software'
            State                = 'Online'
            TargetPath           = '\\ma-fileserver\software'
            Ensure               = 'Present'
            Type                 = 'DomainV2'
            Description          = 'AD Domain based DFS namespace for storing software installers'
            PsDscRunAsCredential = $Credential
        } # End of DFSNamespaceRoot Resource

        DFSNamespaceRoot DFSNamespaceRoot_Domain_Software_NY_01
        {
            Path                 = '\\contoso.com\software'
            State                = 'Online'
            TargetPath           = '\\ny-fileserver01\software'
            Ensure               = 'Present'
            Type                 = 'DomainV2'
            Description          = 'AD Domain based DFS namespace for storing software installers'
            PsDscRunAsCredential = $Credential
        } # End of DFSNamespaceRoot Resource

        DFSNamespaceRoot DFSNamespaceRoot_Domain_Software_NY_02
        {
            Path                 = '\\contoso.com\software'
            State                = 'Online'
            TargetPath           = '\\ny-fileserver02\software'
            TargetState          = 'Offline'
            Ensure               = 'Present'
            Type                 = 'DomainV2'
            Description          = 'AD Domain based DFS namespace for storing software installers'
            PsDscRunAsCredential = $Credential
        } # End of DFSNamespaceRoot Resource

        # Configure the namespace folders
        DFSNamespaceFolder DFSNamespaceFolder_Domain_SoftwareIT_CA
        {
            Path                 = '\\contoso.com\software\it'
            State                = 'Online'
            TargetPath           = '\\ca-fileserver\it'
            Ensure               = 'Present'
            Description          = 'AD Domain based DFS namespace for storing IT specific software installers'
            PsDscRunAsCredential = $Credential
        } # End of DFSNamespaceFolder Resource

        DFSNamespaceFolder DFSNamespaceFolder_Domain_SoftwareIT_MA
        {
            Path                 = '\\contoso.com\software\it'
            State                = 'Online'
            TargetPath           = '\\ma-fileserver\it'
            Ensure               = 'Present'
            Description          = 'AD Domain based DFS namespace for storing IT specific software installers'
            PsDscRunAsCredential = $Credential
        } # End of DFSNamespaceFolder Resource

        DFSNamespaceFolder DFSNamespaceFolder_Domain_SoftwareIT_NY_01
        {
            Path                 = '\\contoso.com\software\it'
            State                = 'Online'
            TargetPath           = '\\ny-fileserver01\it'
            Ensure               = 'Present'
            Description          = 'AD Domain based DFS namespace for storing IT specific software installers'
            PsDscRunAsCredential = $Credential
        } # End of DFSNamespaceFolder Resource

        DFSNamespaceFolder DFSNamespaceFolder_Domain_SoftwareIT_NY_02
        {
            Path                 = '\\contoso.com\software\it'
            State                = 'Online'
            TargetPath           = '\\ny-fileserver02\it'
            Ensure               = 'Present'
            TargetState          = 'Offline'
            Description          = 'AD Domain based DFS namespace for storing IT specific software installers'
            PsDscRunAsCredential = $Credential
        } # End of DFSNamespaceFolder Resource
    }
}
