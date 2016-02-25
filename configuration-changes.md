# Changing configuration and applying it to the cluster

## Modifying DNS and NTP

### Original config and command
```
cat network-environment.yaml
(...)
parameter_defaults:
  ExternalNetCidr: 10.1.1.0/24
  ExternalAllocationPools: [{'start': '10.1.1.2', 'end': '10.1.1.50'}]
  ExternalNetworkVlanID: 100
  # Set to the router gateway on the external network
  ExternalInterfaceDefaultRoute: 10.1.1.1
  # Gateway router for the provisioning network (or Undercloud IP)
  ControlPlaneDefaultRoute: 198.18.53.10
  # The IP address of the EC2 metadata server. Generally the IP of the Undercloud
  EC2MetadataIp: 198.18.53.10
  # Define the DNS servers (maximum 2) for the overcloud nodes
  DnsServers: ["8.8.8.8","8.8.4.4"]
  # Set to "br-ex" if using floating IPs on native VLAN on bridge br-ex
  NeutronExternalNetworkBridge: "''"
  (...)
```

```
openstack overcloud deploy --templates -e /home/stack/environment-basic-network-scenario/network-environment.yaml -e /home/stack/environment-basic-network-scenario/network-isolation-without-api-network.yaml  --control-flavor control --compute-flavor compute --ntp-server pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 1 --compute-scale 1
```

### Original result
```
[root@overcloud-compute-0 ~]# q
-bash: q: command not found
[root@overcloud-compute-0 ~]# grep server /etc/ntp.conf 
# Set up servers for ntpd with next options:
# server - IP address or DNS name of upstream NTP server
# prefer - select preferrable server
server pool.ntp.org
[root@overcloud-compute-0 ~]# grep nameserver /etc/resolv.conf
# No nameservers found; try putting DNS servers into your
nameserver 8.8.8.8
nameserver 8.8.4.4
```

### Modified config and command
```
[stack@poc-undercloud environment-basic-network-scenario]$ grep -i dns network-environment.yaml 
  # Define the DNS servers (maximum 2) for the overcloud nodes
  DnsServers: ["4.2.2.2"]
```

```
openstack overcloud deploy --templates -e /home/stack/environment-basic-network-scenario/network-environment.yaml -e /home/stack/environment-basic-network-scenario/network-isolation-without-api-network.yaml  --control-flavor control --compute-flavor compute --ntp-server 1.rhel.pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 1 --compute-scale 1
```

### What does Heat modify?
```
[root@poc-undercloud ~]# heat resource-list -n5 overcloud | grep -iv complete
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| resource_name                                 | physical_resource_id                          | resource_type                                     | resource_status    | updated_time         | parent_resource                               |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| InternalApiVirtualIP                          | 2bbf6ac0-f46d-4f6a-bff2-1bac96ca54ac          | OS::TripleO::Network::Ports::InternalApiVipPort   | UPDATE_IN_PROGRESS | 2016-02-25T04:42:49Z |                                               |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
[root@poc-undercloud ~]# for i in `seq 1 100`;do heat resource-list -n5 overcloud | grep -iv complete;sleep 60;done
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| resource_name                                 | physical_resource_id                          | resource_type                                     | resource_status    | updated_time         | parent_resource                               |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| Controller                                    | df0d78fb-87e1-4606-9be9-50cc2e8e874f          | OS::Heat::ResourceGroup                           | UPDATE_IN_PROGRESS | 2016-02-25T04:43:23Z |                                               |
| 0                                             | 5fab0e18-b9a1-4c4f-a4c0-0e5c5941c903          | OS::TripleO::Controller                           | UPDATE_IN_PROGRESS | 2016-02-25T04:43:26Z | Controller                                    |
| Compute                                       | 55d5f50f-df6c-4820-907e-d492340a036d          | OS::Heat::ResourceGroup                           | UPDATE_IN_PROGRESS | 2016-02-25T04:43:27Z |                                               |
| 0                                             | 69ea3a08-4eed-4fcf-a08f-6f920fd86ded          | OS::TripleO::Compute                              | UPDATE_IN_PROGRESS | 2016-02-25T04:43:33Z | Compute                                       |
| NodeUserData                                  | bf5cf07a-66be-4304-8c3f-84d15c815841          | OS::TripleO::NodeUserData                         | UPDATE_IN_PROGRESS | 2016-02-25T04:43:56Z | 0                                             |
| StoragePort                                   | 10c5f2da-a062-4618-9170-15126c47b1b7          | OS::TripleO::Controller::Ports::StoragePort       | UPDATE_IN_PROGRESS | 2016-02-25T04:44:04Z | 0                                             |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| resource_name                                 | physical_resource_id                          | resource_type                                     | resource_status    | updated_time         | parent_resource                               |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| Controller                                    | df0d78fb-87e1-4606-9be9-50cc2e8e874f          | OS::Heat::ResourceGroup                           | UPDATE_IN_PROGRESS | 2016-02-25T04:43:23Z |                                               |
| 0                                             | 5fab0e18-b9a1-4c4f-a4c0-0e5c5941c903          | OS::TripleO::Controller                           | UPDATE_IN_PROGRESS | 2016-02-25T04:43:26Z | Controller                                    |
| Compute                                       | 55d5f50f-df6c-4820-907e-d492340a036d          | OS::Heat::ResourceGroup                           | UPDATE_IN_PROGRESS | 2016-02-25T04:43:27Z |                                               |
| 0                                             | 69ea3a08-4eed-4fcf-a08f-6f920fd86ded          | OS::TripleO::Compute                              | UPDATE_IN_PROGRESS | 2016-02-25T04:43:33Z | Compute                                       |
| TenantPort                                    | 05ea65fd-1a61-426d-b41e-9028d8c312af          | OS::TripleO::Compute::Ports::TenantPort           | UPDATE_IN_PROGRESS | 2016-02-25T04:44:21Z | 0                                             |
| StoragePort                                   | 43ac4754-b570-4404-bcfc-bfb3e36b190a          | OS::TripleO::Compute::Ports::StoragePort          | UPDATE_IN_PROGRESS | 2016-02-25T04:45:05Z | 0                                             |
| NetIpMap                                      | 9a138318-1af3-4c27-abc8-5d456735b840          | OS::TripleO::Network::Ports::NetIpMap             | UPDATE_IN_PROGRESS | 2016-02-25T04:45:22Z | 0                                             |
| InternalApiPort                               | 1e0aeb4b-94bb-422a-893c-27f23c3d7f6f          | OS::TripleO::Compute::Ports::InternalApiPort      | UPDATE_IN_PROGRESS | 2016-02-25T04:45:23Z | 0                                             |
| NetIpSubnetMap                                | 641d1319-0c84-4407-a2d7-9cdcacae4f41          | OS::TripleO::Network::Ports::NetIpSubnetMap       | UPDATE_IN_PROGRESS | 2016-02-25T04:45:52Z | 0                                             |
| NetworkConfig                                 | 7c5999d9-a29c-4719-add5-b1d2b9063c99          | OS::TripleO::Controller::Net::SoftwareConfig      | UPDATE_IN_PROGRESS | 2016-02-25T04:46:06Z | 0                                             |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| resource_name                                 | physical_resource_id                          | resource_type                                     | resource_status    | updated_time         | parent_resource                               |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| Controller                                    | df0d78fb-87e1-4606-9be9-50cc2e8e874f          | OS::Heat::ResourceGroup                           | UPDATE_IN_PROGRESS | 2016-02-25T04:43:23Z |                                               |
| 0                                             | 5fab0e18-b9a1-4c4f-a4c0-0e5c5941c903          | OS::TripleO::Controller                           | UPDATE_IN_PROGRESS | 2016-02-25T04:43:26Z | Controller                                    |
| Compute                                       | 55d5f50f-df6c-4820-907e-d492340a036d          | OS::Heat::ResourceGroup                           | UPDATE_IN_PROGRESS | 2016-02-25T04:43:27Z |                                               |
| 0                                             | 69ea3a08-4eed-4fcf-a08f-6f920fd86ded          | OS::TripleO::Compute                              | UPDATE_IN_PROGRESS | 2016-02-25T04:43:33Z | Compute                                       |
| ControllerDeployment                          | 955d3150-14bb-4cdd-a1ef-40bc50b3ebe6          | OS::TripleO::SoftwareDeployment                   | UPDATE_IN_PROGRESS | 2016-02-25T04:46:54Z | 0                                             |
| NovaComputeDeployment                         | 119bbadf-df1d-4b5e-843b-8c9d645a5b11          | OS::TripleO::SoftwareDeployment                   | UPDATE_IN_PROGRESS | 2016-02-25T04:46:59Z | 0                                             |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| resource_name                                 | physical_resource_id                          | resource_type                                     | resource_status    | updated_time         | parent_resource                               |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| Compute                                       | 55d5f50f-df6c-4820-907e-d492340a036d          | OS::Heat::ResourceGroup                           | UPDATE_IN_PROGRESS | 2016-02-25T04:43:27Z |                                               |
| SwiftDevicesAndProxyConfig                    | 8cb4e77c-7ace-4827-84e4-c22b08ad725d          | OS::TripleO::SwiftDevicesAndProxy::SoftwareConfig | UPDATE_IN_PROGRESS | 2016-02-25T04:48:41Z |                                               |
| VipDeployment                                 | f1c4bade-46ea-423e-93b1-b8fb923ee3f0          | OS::Heat::StructuredDeployments                   | UPDATE_IN_PROGRESS | 2016-02-25T04:48:47Z |                                               |
| AllNodesValidationConfig                      | 2e7d0062-2c49-4d53-a386-2c6ffa756578          | OS::TripleO::AllNodes::Validation                 | UPDATE_IN_PROGRESS | 2016-02-25T04:48:55Z |                                               |
| ControllerIpListMap                           | eda07b4f-52c8-4911-9fad-7e5bbad8ea9a          | OS::TripleO::Network::Ports::NetIpListMap         | UPDATE_IN_PROGRESS | 2016-02-25T04:48:59Z |                                               |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| resource_name                                 | physical_resource_id                          | resource_type                                     | resource_status    | updated_time         | parent_resource                               |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| CephStorageCephDeployment                     | 23c14e03-48cf-473a-9b3d-62580c59074e          | OS::Heat::StructuredDeployments                   | UPDATE_IN_PROGRESS | 2016-02-25T04:50:03Z |                                               |
| BlockStorageAllNodesValidationDeployment      | a51d13e0-1fb5-4e7f-b993-411d1b032abe          | OS::Heat::StructuredDeployments                   | UPDATE_IN_PROGRESS | 2016-02-25T04:50:04Z |                                               |
| ControllerCephDeployment                      | 60f0f0a0-a690-4c7f-a4e2-e8a18995bdb5          | OS::Heat::StructuredDeployments                   | UPDATE_IN_PROGRESS | 2016-02-25T04:50:05Z |                                               |
| ComputeCephDeployment                         | fa3c73ab-34e4-4886-a208-34c7838e84b2          | OS::Heat::StructuredDeployments                   | UPDATE_IN_PROGRESS | 2016-02-25T04:50:14Z |                                               |
| ControllerAllNodesValidationDeployment        | 55fe8cfb-1664-4896-b95a-4dd2686230ed          | OS::Heat::StructuredDeployments                   | UPDATE_IN_PROGRESS | 2016-02-25T04:50:20Z |                                               |
| CephStorageAllNodesValidationDeployment       | 5cd9ed5e-c51b-46ab-87ca-26fb6e01f193          | OS::Heat::StructuredDeployments                   | UPDATE_IN_PROGRESS | 2016-02-25T04:50:30Z |                                               |
| ObjectStorageAllNodesValidationDeployment     | 6af17367-1b68-4de5-8e4d-2e27ba07e9b5          | OS::Heat::StructuredDeployments                   | UPDATE_IN_PROGRESS | 2016-02-25T04:50:32Z |                                               |
| ComputeAllNodesValidationDeployment           | 1fc63421-72b0-4f16-a1ed-e3769ceece81          | OS::Heat::StructuredDeployments                   | UPDATE_IN_PROGRESS | 2016-02-25T04:50:33Z |                                               |
| StoragePostPuppetDeployment                   | 6f1f9588-3887-4ac0-9a9d-3511ab21008e          | OS::TripleO::Tasks::StoragePostPuppet             | UPDATE_IN_PROGRESS | 2016-02-25T04:50:57Z | ObjectStorageNodesPostDeployment              |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| resource_name                                 | physical_resource_id                          | resource_type                                     | resource_status    | updated_time         | parent_resource                               |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| ComputeNodesPostDeployment                    | 0f078c60-c73b-4e99-8708-7eec0cc3e588          | OS::TripleO::ComputePostDeployment                | UPDATE_IN_PROGRESS | 2016-02-25T04:50:48Z |                                               |
| ControllerNodesPostDeployment                 | f86346a9-0440-4bdc-bcf5-24c3fd2604f9          | OS::TripleO::ControllerPostDeployment             | UPDATE_IN_PROGRESS | 2016-02-25T04:51:18Z |                                               |
| ComputePuppetDeployment                       | 0972fbb3-0bcd-46aa-aa33-69b895d8c419          | OS::Heat::StructuredDeployments                   | UPDATE_IN_PROGRESS | 2016-02-25T04:51:23Z | ComputeNodesPostDeployment                    |
| ControllerPrePuppet                           | 86cc67d7-d4c2-4a36-a226-99c691122ae0          | OS::TripleO::Tasks::ControllerPrePuppet           | UPDATE_IN_PROGRESS | 2016-02-25T04:51:43Z | ControllerNodesPostDeployment                 |
| ControllerPrePuppetMaintenanceModeDeployment  | 5f386fe8-2cf9-44b4-a3ab-276e0c7021fa          | OS::Heat::SoftwareDeployments                     | UPDATE_IN_PROGRESS | 2016-02-25T04:51:47Z | ControllerPrePuppet                           |
| 0                                             | c7f68450-c864-4c26-8b4c-7830b566071e          | OS::Heat::SoftwareDeployment                      | UPDATE_IN_PROGRESS | 2016-02-25T04:51:49Z | ControllerPrePuppetMaintenanceModeDeployment  |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| resource_name                                 | physical_resource_id                          | resource_type                                     | resource_status    | updated_time         | parent_resource                               |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| ControllerNodesPostDeployment                 | f86346a9-0440-4bdc-bcf5-24c3fd2604f9          | OS::TripleO::ControllerPostDeployment             | UPDATE_IN_PROGRESS | 2016-02-25T04:51:18Z |                                               |
| ControllerRingbuilderDeployment_Step3         | f018636d-3192-4cc6-a74c-f921a4f9fc39          | OS::Heat::StructuredDeployments                   | UPDATE_IN_PROGRESS | 2016-02-25T04:54:15Z | ControllerNodesPostDeployment                 |
| 0                                             | b955ff11-ce59-4493-9db1-32872315ddfb          | OS::Heat::StructuredDeployment                    | UPDATE_IN_PROGRESS | 2016-02-25T04:54:17Z | ControllerRingbuilderDeployment_Step3         |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| resource_name                                 | physical_resource_id                          | resource_type                                     | resource_status    | updated_time         | parent_resource                               |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| ControllerNodesPostDeployment                 | f86346a9-0440-4bdc-bcf5-24c3fd2604f9          | OS::TripleO::ControllerPostDeployment             | UPDATE_IN_PROGRESS | 2016-02-25T04:51:18Z |                                               |
| ControllerOvercloudServicesDeployment_Step4   | a4a9f7f4-d122-4440-b9f1-416d230238ff          | OS::Heat::StructuredDeployments                   | UPDATE_IN_PROGRESS | 2016-02-25T04:55:30Z | ControllerNodesPostDeployment                 |
| 0                                             | 71beb005-3cf6-44e3-a9eb-c842a2aa0071          | OS::Heat::StructuredDeployment                    | UPDATE_IN_PROGRESS | 2016-02-25T04:55:40Z | ControllerOvercloudServicesDeployment_Step4   |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| resource_name                                 | physical_resource_id                          | resource_type                                     | resource_status    | updated_time         | parent_resource                               |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| ControllerNodesPostDeployment                 | f86346a9-0440-4bdc-bcf5-24c3fd2604f9          | OS::TripleO::ControllerPostDeployment             | UPDATE_IN_PROGRESS | 2016-02-25T04:51:18Z |                                               |
| ControllerOvercloudServicesDeployment_Step5   | cb10a37f-e99e-431d-9704-03ab086dc195          | OS::Heat::StructuredDeployments                   | UPDATE_IN_PROGRESS | 2016-02-25T04:57:53Z | ControllerNodesPostDeployment                 |
| 0                                             | 8c1f33d4-b4de-472e-81e1-4d38f69255d7          | OS::Heat::StructuredDeployment                    | UPDATE_IN_PROGRESS | 2016-02-25T04:58:27Z | ControllerOvercloudServicesDeployment_Step5   |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| resource_name                                 | physical_resource_id                          | resource_type                                     | resource_status    | updated_time         | parent_resource                               |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| ControllerNodesPostDeployment                 | f86346a9-0440-4bdc-bcf5-24c3fd2604f9          | OS::TripleO::ControllerPostDeployment             | UPDATE_IN_PROGRESS | 2016-02-25T04:51:18Z |                                               |
| ControllerOvercloudServicesDeployment_Step5   | cb10a37f-e99e-431d-9704-03ab086dc195          | OS::Heat::StructuredDeployments                   | UPDATE_IN_PROGRESS | 2016-02-25T04:57:53Z | ControllerNodesPostDeployment                 |
| 0                                             | 8c1f33d4-b4de-472e-81e1-4d38f69255d7          | OS::Heat::StructuredDeployment                    | UPDATE_IN_PROGRESS | 2016-02-25T04:58:27Z | ControllerOvercloudServicesDeployment_Step5   |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| resource_name                                 | physical_resource_id                          | resource_type                                     | resource_status    | updated_time         | parent_resource                               |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| ControllerNodesPostDeployment                 | f86346a9-0440-4bdc-bcf5-24c3fd2604f9          | OS::TripleO::ControllerPostDeployment             | UPDATE_IN_PROGRESS | 2016-02-25T04:51:18Z |                                               |
| ControllerOvercloudServicesDeployment_Step6   | 92dec97c-fb13-48e1-b4c9-e248aabb44f4          | OS::Heat::StructuredDeployments                   | UPDATE_IN_PROGRESS | 2016-02-25T05:00:32Z | ControllerNodesPostDeployment                 |
| 0                                             | 05bc8e19-64c6-412a-8aa0-9f64df6057ba          | OS::Heat::StructuredDeployment                    | UPDATE_IN_PROGRESS | 2016-02-25T05:01:02Z | ControllerOvercloudServicesDeployment_Step6   |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| resource_name                                 | physical_resource_id                          | resource_type                                     | resource_status    | updated_time         | parent_resource                               |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| ControllerNodesPostDeployment                 | f86346a9-0440-4bdc-bcf5-24c3fd2604f9          | OS::TripleO::ControllerPostDeployment             | UPDATE_IN_PROGRESS | 2016-02-25T04:51:18Z |                                               |
| ControllerOvercloudServicesDeployment_Step6   | 92dec97c-fb13-48e1-b4c9-e248aabb44f4          | OS::Heat::StructuredDeployments                   | UPDATE_IN_PROGRESS | 2016-02-25T05:00:32Z | ControllerNodesPostDeployment                 |
| 0                                             | 05bc8e19-64c6-412a-8aa0-9f64df6057ba          | OS::Heat::StructuredDeployment                    | UPDATE_IN_PROGRESS | 2016-02-25T05:01:02Z | ControllerOvercloudServicesDeployment_Step6   |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| resource_name                                 | physical_resource_id                          | resource_type                                     | resource_status    | updated_time         | parent_resource                               |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| ControllerNodesPostDeployment                 | f86346a9-0440-4bdc-bcf5-24c3fd2604f9          | OS::TripleO::ControllerPostDeployment             | UPDATE_IN_PROGRESS | 2016-02-25T04:51:18Z |                                               |
| ControllerOvercloudServicesDeployment_Step7   | 53088005-404a-49ed-95a2-92db39aceae1          | OS::Heat::StructuredDeployments                   | UPDATE_IN_PROGRESS | 2016-02-25T05:03:55Z | ControllerNodesPostDeployment                 |
| 0                                             | bc29be3e-6165-4b12-baa7-b3f73396a3c5          | OS::Heat::StructuredDeployment                    | UPDATE_IN_PROGRESS | 2016-02-25T05:04:44Z | ControllerOvercloudServicesDeployment_Step7   |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| resource_name                                 | physical_resource_id                          | resource_type                                     | resource_status    | updated_time         | parent_resource                               |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| ControllerNodesPostDeployment                 | f86346a9-0440-4bdc-bcf5-24c3fd2604f9          | OS::TripleO::ControllerPostDeployment             | UPDATE_IN_PROGRESS | 2016-02-25T04:51:18Z |                                               |
| ControllerOvercloudServicesDeployment_Step7   | 53088005-404a-49ed-95a2-92db39aceae1          | OS::Heat::StructuredDeployments                   | UPDATE_IN_PROGRESS | 2016-02-25T05:03:55Z | ControllerNodesPostDeployment                 |
| 0                                             | bc29be3e-6165-4b12-baa7-b3f73396a3c5          | OS::Heat::StructuredDeployment                    | UPDATE_IN_PROGRESS | 2016-02-25T05:04:44Z | ControllerOvercloudServicesDeployment_Step7   |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
^C... terminating heat client

[root@poc-undercloud ~]# for i in `seq 1 100`;do heat resource-list -n5 overcloud | grep -iv complete;sleep 120;done
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| resource_name                                 | physical_resource_id                          | resource_type                                     | resource_status    | updated_time         | parent_resource                               |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| ControllerNodesPostDeployment                 | f86346a9-0440-4bdc-bcf5-24c3fd2604f9          | OS::TripleO::ControllerPostDeployment             | UPDATE_IN_PROGRESS | 2016-02-25T04:51:18Z |                                               |
| ControllerPostPuppet                          | 1e5d4167-8547-47df-bb90-967cd221ffe0          | OS::TripleO::Tasks::ControllerPostPuppet          | UPDATE_IN_PROGRESS | 2016-02-25T05:07:45Z | ControllerNodesPostDeployment                 |
| ControllerPostPuppetMaintenanceModeDeployment | e0dfe6b6-62a7-44be-9223-213230dbafa9          | OS::Heat::SoftwareDeployments                     | UPDATE_IN_PROGRESS | 2016-02-25T05:08:00Z | ControllerPostPuppet                          |
| 0                                             | 260adbb4-cead-4169-951a-9293f6729fe6          | OS::Heat::SoftwareDeployment                      | UPDATE_IN_PROGRESS | 2016-02-25T05:08:27Z | ControllerPostPuppetMaintenanceModeDeployment |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| resource_name                                 | physical_resource_id                          | resource_type                                     | resource_status    | updated_time         | parent_resource                               |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| ControllerNodesPostDeployment                 | f86346a9-0440-4bdc-bcf5-24c3fd2604f9          | OS::TripleO::ControllerPostDeployment             | UPDATE_IN_PROGRESS | 2016-02-25T04:51:18Z |                                               |
| ControllerPostPuppet                          | 1e5d4167-8547-47df-bb90-967cd221ffe0          | OS::TripleO::Tasks::ControllerPostPuppet          | UPDATE_IN_PROGRESS | 2016-02-25T05:07:45Z | ControllerNodesPostDeployment                 |
| ControllerPostPuppetRestartDeployment         | cfa491ce-c9c7-4174-83a0-97ec53e7e779          | OS::Heat::SoftwareDeployments                     | UPDATE_IN_PROGRESS | 2016-02-25T05:09:52Z | ControllerPostPuppet                          |
| 0                                             | 7d84f75b-6bcc-4a4d-86cd-9e02d4944902          | OS::Heat::SoftwareDeployment                      | UPDATE_IN_PROGRESS | 2016-02-25T05:11:00Z | ControllerPostPuppetRestartDeployment         |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| resource_name                                 | physical_resource_id                          | resource_type                                     | resource_status    | updated_time         | parent_resource                               |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| ControllerNodesPostDeployment                 | f86346a9-0440-4bdc-bcf5-24c3fd2604f9          | OS::TripleO::ControllerPostDeployment             | UPDATE_IN_PROGRESS | 2016-02-25T04:51:18Z |                                               |
| ControllerPostPuppet                          | 1e5d4167-8547-47df-bb90-967cd221ffe0          | OS::TripleO::Tasks::ControllerPostPuppet          | UPDATE_IN_PROGRESS | 2016-02-25T05:07:45Z | ControllerNodesPostDeployment                 |
| ControllerPostPuppetRestartDeployment         | cfa491ce-c9c7-4174-83a0-97ec53e7e779          | OS::Heat::SoftwareDeployments                     | UPDATE_IN_PROGRESS | 2016-02-25T05:09:52Z | ControllerPostPuppet                          |
| 0                                             | 7d84f75b-6bcc-4a4d-86cd-9e02d4944902          | OS::Heat::SoftwareDeployment                      | UPDATE_IN_PROGRESS | 2016-02-25T05:11:00Z | ControllerPostPuppetRestartDeployment         |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
^C... terminating heat client

[root@poc-undercloud ~]# for i in `seq 1 100`;do heat resource-list -n5 overcloud | grep -iv complete;sleep 240;done
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| resource_name                                 | physical_resource_id                          | resource_type                                     | resource_status    | updated_time         | parent_resource                               |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
| CephStorageNodesPostDeployment                | 1ab7d975-a923-4d24-8570-a7371f2b39e5          | OS::TripleO::CephStoragePostDeployment            | UPDATE_IN_PROGRESS | 2016-02-25T05:17:04Z |                                               |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+-----------------------------------------------+
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+-----------------+----------------------+-----------------------------------------------+
| resource_name                                 | physical_resource_id                          | resource_type                                     | resource_status | updated_time         | parent_resource                               |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+-----------------+----------------------+-----------------------------------------------+
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+-----------------+----------------------+-----------------------------------------------+
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+-----------------+----------------------+-----------------------------------------------+
| resource_name                                 | physical_resource_id                          | resource_type                                     | resource_status | updated_time         | parent_resource                               |
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+-----------------+----------------------+-----------------------------------------------+
+-----------------------------------------------+-----------------------------------------------+---------------------------------------------------+-----------------+----------------------+-----------------------------------------------+
```

### Result of modification
```
[heat-admin@overcloud-controller-0 ~]$ grep nameserver /etc/resolv.conf
# No nameservers found; try putting DNS servers into your
nameserver 8.8.8.8
nameserver 8.8.4.4
[heat-admin@overcloud-controller-0 ~]$ grep 8.8. /etc/sysconfig/network* -R
/etc/sysconfig/network-scripts/ifcfg-br-ex:DNS1=8.8.8.8
/etc/sysconfig/network-scripts/ifcfg-br-ex:DNS2=8.8.4.4
[heat-admin@overcloud-controller-0 ~]$ grep server /etc/ntp.conf 
# Set up servers for ntpd with next options:
# server - IP address or DNS name of upstream NTP server
# prefer - select preferrable server
server 1.rhel.pool.ntp.org
```
