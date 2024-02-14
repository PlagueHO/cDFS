Configuration DSC_DFSNamespaceServerConfiguration_Config {
    Import-DscResource -ModuleName DFSDsc

    Node localhost {
        DFSNamespaceServerConfiguration Integration_Test {
            IsSingleInstance             = 'Yes'
            LdapTimeoutSec               = $Node.LdapTimeoutSec
            SyncIntervalSec              = $Node.SyncIntervalSec
            UseFQDN                      = $Node.UseFQDN
        }
    }
}
