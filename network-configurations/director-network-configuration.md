# Variant 1
## Command
```
openstack overcloud deploy --templates -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml  -e /home/stack/environment-netapp/network-environment.yaml   --control-flavor control --compute-flavor compute --ntp-server pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 1 --compute-scale 1
Deploying templates in the directory /usr/share/openstack-tripleo-heat-templates
```

## /environment-netapp/network-environment.yaml

```
resource_registry:
  OS::TripleO::BlockStorage::Net::SoftwareConfig: /usr/share/openstack-tripleo-heat-templates/network/config/single-nic-vlans/cinder-storage.yaml
  OS::TripleO::Compute::Net::SoftwareConfig: /usr/share/openstack-tripleo-heat-templates/network/config/single-nic-vlans/compute.yaml
  OS::TripleO::Controller::Net::SoftwareConfig: /usr/share/openstack-tripleo-heat-templates/network/config/single-nic-vlans/controller.yaml
  OS::TripleO::ObjectStorage::Net::SoftwareConfig: /usr/share/openstack-tripleo-heat-templates/network/config/single-nic-vlans/swift-storage.yaml
  OS::TripleO::CephStorage::Net::SoftwareConfig: /usr/share/openstack-tripleo-heat-templates/network/config/single-nic-vlans/ceph-storage.yaml

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
```

## Neutron
```
[stack@poc-undercloud ~]$ neutron net-list
+--------------------------------------+--------------+-----------------------------------------------------+
| id                                   | name         | subnets                                             |
+--------------------------------------+--------------+-----------------------------------------------------+
| 0f4ec0d9-7d7b-484c-b27f-0f44e4798c80 | external     | 561f2f04-7cb4-4c0b-87f4-b8648c07fd98 10.1.1.0/24    |
| 53845278-9018-4883-be18-7645a8e9b6ba | tenant       | 53c761a5-6140-43e3-81c2-5ed74a7384f8 172.16.0.0/24  |
| a9c274b9-89f2-48b6-bf65-e0b831d293fe | internal_api | b6e17cf6-298e-4676-a48d-2565b2e62665 172.16.2.0/24  |
| ba433781-d3f5-4e78-b3f9-17affb5cc92b | ctlplane     | 5694ef8e-10a2-413f-80e6-45dcf0f0a1b8 198.18.53.0/26 |
| ed8639a1-add3-468a-9343-16327f7e74cb | storage      | 92a1e65c-a9cd-4987-8111-88aa19c49f7f 172.16.1.0/24  |
| f3ed8ec5-90e2-47d0-87da-9c9e9cafe1b8 | storage_mgmt | 36d0efed-5fe0-4587-9715-44ef90b14f5f 172.16.3.0/24  |
+--------------------------------------+--------------+-----------------------------------------------------+
```

## Controller
```
[heat-admin@overcloud-controller-0 ~]$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN 
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: ens3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 52:54:00:45:fe:c4 brd ff:ff:ff:ff:ff:ff
    inet6 fe80::5054:ff:fe45:fec4/64 scope link 
       valid_lft forever preferred_lft forever
3: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master ovs-system state UP qlen 1000
    link/ether 52:54:00:9c:06:83 brd ff:ff:ff:ff:ff:ff
4: ovs-system: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN 
    link/ether 56:df:23:18:91:b7 brd ff:ff:ff:ff:ff:ff
5: br-ex: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether 52:54:00:9c:06:83 brd ff:ff:ff:ff:ff:ff
    inet 198.18.53.21/24 brd 198.18.53.255 scope global br-ex
       valid_lft forever preferred_lft forever
    inet6 fe80::5054:ff:fe9c:683/64 scope link 
       valid_lft forever preferred_lft forever
6: vlan20: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether ca:65:59:21:87:c0 brd ff:ff:ff:ff:ff:ff
    inet 172.16.2.7/24 brd 172.16.2.255 scope global vlan20
       valid_lft forever preferred_lft forever
    inet6 fe80::c865:59ff:fe21:87c0/64 scope link 
       valid_lft forever preferred_lft forever
7: vlan30: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether 46:12:67:34:f5:82 brd ff:ff:ff:ff:ff:ff
    inet 172.16.1.6/24 brd 172.16.1.255 scope global vlan30
       valid_lft forever preferred_lft forever
    inet6 fe80::4412:67ff:fe34:f582/64 scope link 
       valid_lft forever preferred_lft forever
8: vlan100: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether 26:c2:d2:6f:1d:42 brd ff:ff:ff:ff:ff:ff
    inet 10.1.1.3/24 brd 10.1.1.255 scope global vlan100
       valid_lft forever preferred_lft forever
    inet6 fe80::24c2:d2ff:fe6f:1d42/64 scope link 
       valid_lft forever preferred_lft forever
9: vlan40: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether 0a:89:c3:2f:c6:50 brd ff:ff:ff:ff:ff:ff
    inet 172.16.3.5/24 brd 172.16.3.255 scope global vlan40
       valid_lft forever preferred_lft forever
    inet6 fe80::889:c3ff:fe2f:c650/64 scope link 
       valid_lft forever preferred_lft forever
10: vlan50: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether 52:1a:18:1b:10:d6 brd ff:ff:ff:ff:ff:ff
    inet 172.16.0.5/24 brd 172.16.0.255 scope global vlan50
       valid_lft forever preferred_lft forever
    inet6 fe80::501a:18ff:fe1b:10d6/64 scope link 
       valid_lft forever preferred_lft forever
```

## Compute
```
[heat-admin@overcloud-compute-0 ~]$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN 
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: ens3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 52:54:00:4f:b9:9b brd ff:ff:ff:ff:ff:ff
3: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master ovs-system state UP qlen 1000
    link/ether 52:54:00:af:0c:c4 brd ff:ff:ff:ff:ff:ff
4: ovs-system: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN 
    link/ether 82:91:53:d0:4b:2d brd ff:ff:ff:ff:ff:ff
5: br-ex: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether 52:54:00:af:0c:c4 brd ff:ff:ff:ff:ff:ff
    inet 198.18.53.22/24 brd 198.18.53.255 scope global br-ex
       valid_lft forever preferred_lft forever
    inet6 fe80::5054:ff:feaf:cc4/64 scope link 
       valid_lft forever preferred_lft forever
6: vlan20: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether fe:ff:8d:d3:ef:91 brd ff:ff:ff:ff:ff:ff
    inet 172.16.2.6/24 brd 172.16.2.255 scope global vlan20
       valid_lft forever preferred_lft forever
    inet6 fe80::fcff:8dff:fed3:ef91/64 scope link 
       valid_lft forever preferred_lft forever
7: vlan30: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether 02:0f:16:9b:08:f2 brd ff:ff:ff:ff:ff:ff
    inet 172.16.1.5/24 brd 172.16.1.255 scope global vlan30
       valid_lft forever preferred_lft forever
    inet6 fe80::f:16ff:fe9b:8f2/64 scope link 
       valid_lft forever preferred_lft forever
8: vlan50: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether ce:7c:1b:e0:cf:92 brd ff:ff:ff:ff:ff:ff
    inet 172.16.0.4/24 brd 172.16.0.255 scope global vlan50
       valid_lft forever preferred_lft forever
    inet6 fe80::cc7c:1bff:fee0:cf92/64 scope link 
       valid_lft forever preferred_lft forever
```

# Variant 2
## Command 
```
openstack overcloud deploy --templates --control-flavor control --compute-flavor compute --ntp-server pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 1 --compute-scale 1
```

## /environment-netapp/network-environment.yaml

```
resource_registry:
  OS::TripleO::BlockStorage::Net::SoftwareConfig: /usr/share/openstack-tripleo-heat-templates/network/config/single-nic-vlans/cinder-storage.yaml
  OS::TripleO::Compute::Net::SoftwareConfig: /usr/share/openstack-tripleo-heat-templates/network/config/single-nic-vlans/compute.yaml
  OS::TripleO::Controller::Net::SoftwareConfig: /usr/share/openstack-tripleo-heat-templates/network/config/single-nic-vlans/controller.yaml
  OS::TripleO::ObjectStorage::Net::SoftwareConfig: /usr/share/openstack-tripleo-heat-templates/network/config/single-nic-vlans/swift-storage.yaml
  OS::TripleO::CephStorage::Net::SoftwareConfig: /usr/share/openstack-tripleo-heat-templates/network/config/single-nic-vlans/ceph-storage.yaml

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
```

## Neutron
```
[stack@poc-undercloud ~]$ neutron net-list
+--------------------------------------+----------+-----------------------------------------------------+
| id                                   | name     | subnets                                             |
+--------------------------------------+----------+-----------------------------------------------------+
| ba433781-d3f5-4e78-b3f9-17affb5cc92b | ctlplane | 5694ef8e-10a2-413f-80e6-45dcf0f0a1b8 198.18.53.0/26 |
+--------------------------------------+----------+-----------------------------------------------------+
```
## Controller
```
[heat-admin@overcloud-controller-0 ~]$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN 
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: ens3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 52:54:00:45:fe:c4 brd ff:ff:ff:ff:ff:ff
3: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master ovs-system state UP qlen 1000
    link/ether 52:54:00:9c:06:83 brd ff:ff:ff:ff:ff:ff
4: ovs-system: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN 
    link/ether d2:27:fd:96:ea:99 brd ff:ff:ff:ff:ff:ff
5: br-ex: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether 52:54:00:9c:06:83 brd ff:ff:ff:ff:ff:ff
    inet 198.18.53.26/26 brd 198.18.53.63 scope global dynamic br-ex
       valid_lft 82315sec preferred_lft 82315sec
    inet6 fe80::5054:ff:fe9c:683/64 scope link 
       valid_lft forever preferred_lft forever
```

## Compute
```
[root@overcloud-compute-0 heat-config]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN 
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: ens3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 52:54:00:4f:b9:9b brd ff:ff:ff:ff:ff:ff
    inet6 fe80::5054:ff:fe4f:b99b/64 scope link 
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 52:54:00:af:0c:c4 brd ff:ff:ff:ff:ff:ff
    inet 198.18.53.27/26 brd 198.18.53.63 scope global dynamic eth1
       valid_lft 82963sec preferred_lft 82963sec
    inet6 fe80::5054:ff:feaf:cc4/64 scope link 
       valid_lft forever preferred_lft forever
```

# Variant 3
## Command
```
openstack overcloud deploy --template -e /home/stack/environment-netapp/network-environment.yaml -e /home/stack/environment-netapp/storage-environment.yaml   --control-flavor control --compute-flavor compute --ntp-server pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 1 --compute-scale 1
```

## /environment-netapp/network-environment.yaml

```
resource_registry:
  OS::TripleO::BlockStorage::Net::SoftwareConfig: /usr/share/openstack-tripleo-heat-templates/network/config/single-nic-vlans/cinder-storage.yaml
  OS::TripleO::Compute::Net::SoftwareConfig: /usr/share/openstack-tripleo-heat-templates/network/config/single-nic-vlans/compute.yaml
  OS::TripleO::Controller::Net::SoftwareConfig: /usr/share/openstack-tripleo-heat-templates/network/config/single-nic-vlans/controller.yaml
  OS::TripleO::ObjectStorage::Net::SoftwareConfig: /usr/share/openstack-tripleo-heat-templates/network/config/single-nic-vlans/swift-storage.yaml
  OS::TripleO::CephStorage::Net::SoftwareConfig: /usr/share/openstack-tripleo-heat-templates/network/config/single-nic-vlans/ceph-storage.yaml

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
```

## neutron
```
[stack@poc-undercloud ~]$ neutron net-list
+--------------------------------------+----------+-----------------------------------------------------+
| id                                   | name     | subnets                                             |
+--------------------------------------+----------+-----------------------------------------------------+
| ba433781-d3f5-4e78-b3f9-17affb5cc92b | ctlplane | 5694ef8e-10a2-413f-80e6-45dcf0f0a1b8 198.18.53.0/26 |
+--------------------------------------+----------+-----------------------------------------------------+
```

## Compute
```
[heat-admin@overcloud-controller-0 ~]$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN 
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: ens3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 52:54:00:45:fe:c4 brd ff:ff:ff:ff:ff:ff
    inet6 fe80::5054:ff:fe45:fec4/64 scope link 
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master ovs-system state UP qlen 1000
    link/ether 52:54:00:9c:06:83 brd ff:ff:ff:ff:ff:ff
4: ovs-system: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN 
    link/ether 66:d3:df:92:d2:a7 brd ff:ff:ff:ff:ff:ff
5: br-ex: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether 52:54:00:9c:06:83 brd ff:ff:ff:ff:ff:ff
    inet 198.18.53.30/24 brd 198.18.53.255 scope global br-ex
       valid_lft forever preferred_lft forever
    inet 198.18.53.28/32 brd 198.18.53.255 scope global br-ex
       valid_lft forever preferred_lft forever
    inet 198.18.53.29/32 brd 198.18.53.255 scope global br-ex
       valid_lft forever preferred_lft forever
    inet6 fe80::5054:ff:fe9c:683/64 scope link 
       valid_lft forever preferred_lft forever
6: vlan20: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether 6a:3f:07:71:8d:e7 brd ff:ff:ff:ff:ff:ff
    inet 198.18.53.30/24 brd 198.18.53.255 scope global vlan20
       valid_lft forever preferred_lft forever
    inet6 fe80::683f:7ff:fe71:8de7/64 scope link 
       valid_lft forever preferred_lft forever
7: vlan30: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether 0e:61:23:93:72:d5 brd ff:ff:ff:ff:ff:ff
    inet 198.18.53.30/24 brd 198.18.53.255 scope global vlan30
       valid_lft forever preferred_lft forever
    inet6 fe80::c61:23ff:fe93:72d5/64 scope link 
       valid_lft forever preferred_lft forever
8: vlan100: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether 5e:50:bb:3d:da:64 brd ff:ff:ff:ff:ff:ff
    inet 198.18.53.30/24 brd 198.18.53.255 scope global vlan100
       valid_lft forever preferred_lft forever
    inet6 fe80::5c50:bbff:fe3d:da64/64 scope link 
       valid_lft forever preferred_lft forever
9: vlan40: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether d2:79:3b:08:51:40 brd ff:ff:ff:ff:ff:ff
    inet 198.18.53.30/24 brd 198.18.53.255 scope global vlan40
       valid_lft forever preferred_lft forever
    inet6 fe80::d079:3bff:fe08:5140/64 scope link 
       valid_lft forever preferred_lft forever
10: vlan50: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether fe:35:d3:4a:71:38 brd ff:ff:ff:ff:ff:ff
    inet 198.18.53.30/24 brd 198.18.53.255 scope global vlan50
       valid_lft forever preferred_lft forever
    inet6 fe80::fc35:d3ff:fe4a:7138/64 scope link 
       valid_lft forever preferred_lft forever
11: br-int: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN 
    link/ether f2:ba:b0:5c:2b:4a brd ff:ff:ff:ff:ff:ff
12: br-tun: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN 
    link/ether 8e:0f:2c:36:71:41 brd ff:ff:ff:ff:ff:ff
[heat-admin@overcloud-controller-0 ~]$ ip r
169.254.169.254 via 198.18.53.10 dev br-ex 
198.18.53.0/24 dev br-ex  proto kernel  scope link  src 198.18.53.30 
198.18.53.0/24 dev vlan20  proto kernel  scope link  src 198.18.53.30 
198.18.53.0/24 dev vlan30  proto kernel  scope link  src 198.18.53.30 
198.18.53.0/24 dev vlan100  proto kernel  scope link  src 198.18.53.30 
198.18.53.0/24 dev vlan40  proto kernel  scope link  src 198.18.53.30 
198.18.53.0/24 dev vlan50  proto kernel  scope link  src 198.18.53.30 
```

## Control
```
[heat-admin@overcloud-compute-0 ~]$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN 
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: ens3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 52:54:00:4f:b9:9b brd ff:ff:ff:ff:ff:ff
    inet6 fe80::5054:ff:fe4f:b99b/64 scope link 
       valid_lft forever preferred_lft forever
3: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master ovs-system state UP qlen 1000
    link/ether 52:54:00:af:0c:c4 brd ff:ff:ff:ff:ff:ff
4: ovs-system: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN 
    link/ether 5e:24:13:91:cb:3d brd ff:ff:ff:ff:ff:ff
5: br-ex: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether 52:54:00:af:0c:c4 brd ff:ff:ff:ff:ff:ff
    inet 198.18.53.32/24 brd 198.18.53.255 scope global br-ex
       valid_lft forever preferred_lft forever
    inet6 fe80::5054:ff:feaf:cc4/64 scope link 
       valid_lft forever preferred_lft forever
6: vlan20: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether 26:c9:46:4f:fd:13 brd ff:ff:ff:ff:ff:ff
    inet 198.18.53.32/24 brd 198.18.53.255 scope global vlan20
       valid_lft forever preferred_lft forever
    inet6 fe80::24c9:46ff:fe4f:fd13/64 scope link 
       valid_lft forever preferred_lft forever
7: vlan30: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether 72:60:fe:3b:9d:be brd ff:ff:ff:ff:ff:ff
    inet 198.18.53.32/24 brd 198.18.53.255 scope global vlan30
       valid_lft forever preferred_lft forever
    inet6 fe80::7060:feff:fe3b:9dbe/64 scope link 
       valid_lft forever preferred_lft forever
8: vlan50: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether ca:e4:32:4c:70:ed brd ff:ff:ff:ff:ff:ff
    inet 198.18.53.32/24 brd 198.18.53.255 scope global vlan50
       valid_lft forever preferred_lft forever
    inet6 fe80::c8e4:32ff:fe4c:70ed/64 scope link 
       valid_lft forever preferred_lft forever
9: br-int: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN 
    link/ether ce:c2:54:74:78:46 brd ff:ff:ff:ff:ff:ff
10: br-tun: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN 
    link/ether 32:73:1c:d5:32:4a brd ff:ff:ff:ff:ff:ff
[heat-admin@overcloud-compute-0 ~]$ ip r
default via 198.18.53.10 dev br-ex 
169.254.169.254 via 198.18.53.10 dev br-ex 
198.18.53.0/24 dev br-ex  proto kernel  scope link  src 198.18.53.32 
198.18.53.0/24 dev vlan20  proto kernel  scope link  src 198.18.53.32 
198.18.53.0/24 dev vlan30  proto kernel  scope link  src 198.18.53.32 
198.18.53.0/24 dev vlan50  proto kernel  scope link  src 198.18.53.32
```

# Variant 4 - External API network for controllers on a dedicated interface
## Command
```
openstack overcloud deploy --templates -e /home/stack/environment-basic-network-scenario/network-environment.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml  --control-flavor control --compute-flavor compute --ntp-server pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 1 --compute-scale 1
```

## /environment-netapp/network-environment.yaml

```
[stack@poc-undercloud ~]$ cat /home/stack/environment-basic-network-scenario/network-environment.yaml
resource_registry:
  OS::TripleO::BlockStorage::Net::SoftwareConfig: /home/stack/templates-basic-network-scenario/single-nic-vlans/cinder-storage.yaml
  OS::TripleO::Compute::Net::SoftwareConfig: /home/stack/templates-basic-network-scenario/single-nic-vlans/compute.yaml
  OS::TripleO::Controller::Net::SoftwareConfig: /home/stack/templates-basic-network-scenario/single-nic-vlans/controller.yaml
  OS::TripleO::ObjectStorage::Net::SoftwareConfig: /home/stack/templates-basic-network-scenario/single-nic-vlans/swift-storage.yaml
  OS::TripleO::CephStorage::Net::SoftwareConfig: /home/stack/templates-basic-network-scenario/single-nic-vlans/ceph-storage.yaml

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
```

## templates-basic-network-scenario/single-nic-vlans/controller.yaml
```
heat_template_version: 2015-04-30

description: >
  Software Config to drive os-net-config to configure VLANs for the
  controller role.

parameters:
  ControlPlaneIp:
    default: ''
    description: IP address/subnet on the ctlplane network
    type: string
  ExternalIpSubnet:
    default: ''
    description: IP address/subnet on the external network
    type: string
  InternalApiIpSubnet:
    default: ''
    description: IP address/subnet on the internal API network
    type: string
  StorageIpSubnet:
    default: ''
    description: IP address/subnet on the storage network
    type: string
  StorageMgmtIpSubnet:
    default: ''
    description: IP address/subnet on the storage mgmt network
    type: string
  TenantIpSubnet:
    default: ''
    description: IP address/subnet on the tenant network
    type: string
  ExternalNetworkVlanID:
    default: 10
    description: Vlan ID for the external network traffic.
    type: number
  InternalApiNetworkVlanID:
    default: 20
    description: Vlan ID for the internal_api network traffic.
    type: number
  StorageNetworkVlanID:
    default: 30
    description: Vlan ID for the storage network traffic.
    type: number
  StorageMgmtNetworkVlanID:
    default: 40
    description: Vlan ID for the storage mgmt network traffic.
    type: number
  TenantNetworkVlanID:
    default: 50
    description: Vlan ID for the tenant network traffic.
    type: number
  ExternalInterfaceDefaultRoute:
    default: '10.0.0.1'
    description: default route for the external network
    type: string
  ControlPlaneSubnetCidr: # Override this via parameter_defaults
    default: '24'
    description: The subnet CIDR of the control plane network.
    type: string
  DnsServers: # Override this via parameter_defaults
    default: []
    description: A list of DNS servers (2 max for some implementations) that will be added to resolv.conf.
    type: json
  EC2MetadataIp: # Override this via parameter_defaults
    description: The IP address of the EC2 metadata server.
    type: string

resources:
  OsNetConfigImpl:
    type: OS::Heat::StructuredConfig
    properties:
      group: os-apply-config
      config:
        os_net_config:
          network_config:
            -
              type: ovs_bridge
              name: {get_input: bridge_name}
              use_dhcp: false
              dns_servers: {get_param: DnsServers}
              addresses:
                -
                  ip_netmask:
                    list_join:
                      - '/'
                      - - {get_param: ControlPlaneIp}
                        - {get_param: ControlPlaneSubnetCidr}
              routes:
                -
                  ip_netmask: 169.254.169.254/32
                  next_hop: {get_param: EC2MetadataIp}
              members:
                -
                  type: interface
                  name: nic1
                  # force the MAC address of the bridge to this interface
                  primary: true
                -
                  type: vlan
                  vlan_id: {get_param: InternalApiNetworkVlanID}
                  addresses:
                  -
                    ip_netmask: {get_param: InternalApiIpSubnet}
                -
                  type: vlan
                  vlan_id: {get_param: StorageNetworkVlanID}
                  addresses:
                  -
                    ip_netmask: {get_param: StorageIpSubnet}
                -
                  type: vlan
                  vlan_id: {get_param: StorageMgmtNetworkVlanID}
                  addresses:
                  -
                    ip_netmask: {get_param: StorageMgmtIpSubnet}
                -
                  type: vlan
                  vlan_id: {get_param: TenantNetworkVlanID}
                  addresses:
                  -
                    ip_netmask: {get_param: TenantIpSubnet}
                - type: interface
                  name: nic2
                  addresses:
                  - ip_netmask: {get_param: ExternalIpSubnet}
                  routes:
                  - ip_netmask: 0.0.0.0/0
                    next_hop: {get_param: ExternalInterfaceDefaultRoute}
outputs:
  OS::stack_id:
    description: The OsNetConfigImpl resource.
    value: {get_resource: OsNetConfigImpl}
```

## Neutron
```
[stack@poc-undercloud ~]$ neutron net-list
+--------------------------------------+--------------+-----------------------------------------------------+
| id                                   | name         | subnets                                             |
+--------------------------------------+--------------+-----------------------------------------------------+
| 2c4871ce-ca83-4bc8-9b54-a1b48bb58f51 | external     | b74841d7-3972-41d8-b9b0-b50fef5d9fe9 10.1.1.0/24    |
| 2edc6eb7-2aac-45ea-aa65-85017dc4a2a3 | tenant       | 1c14e90c-d091-4e37-94c4-fca19b6c0feb 172.16.0.0/24  |
| 6c124bbc-bb66-4a8b-91bb-d9bfaff31eeb | internal_api | 038b3c23-b586-4179-b8af-5263eb998ebe 172.16.2.0/24  |
| 741b62c2-ee90-4ad1-b443-03af3521e8f7 | storage      | 9db67503-9624-4eb4-b627-3318abdcfda8 172.16.1.0/24  |
| ba433781-d3f5-4e78-b3f9-17affb5cc92b | ctlplane     | 5694ef8e-10a2-413f-80e6-45dcf0f0a1b8 198.18.53.0/26 |
| f9501c1c-813b-46a4-a5e3-87a5e73719cf | storage_mgmt | 8431bfd0-2d23-47d5-a4d9-c170eda6222d 172.16.3.0/24  |
+--------------------------------------+--------------+-----------------------------------------------------+
```

## Controller
```
[heat-admin@overcloud-controller-0 ~]$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN 
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: ens3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master ovs-system state UP qlen 1000
    link/ether 52:54:00:45:fe:c4 brd ff:ff:ff:ff:ff:ff
    inet 10.1.1.3/24 brd 10.1.1.255 scope global ens3
       valid_lft forever preferred_lft forever
    inet6 fe80::5054:ff:fe45:fec4/64 scope link 
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master ovs-system state UP qlen 1000
    link/ether 52:54:00:9c:06:83 brd ff:ff:ff:ff:ff:ff
4: ovs-system: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN 
    link/ether c6:23:fc:a8:92:05 brd ff:ff:ff:ff:ff:ff
5: br-ex: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether 52:54:00:9c:06:83 brd ff:ff:ff:ff:ff:ff
    inet 198.18.53.35/24 brd 198.18.53.255 scope global br-ex
       valid_lft forever preferred_lft forever
    inet6 fe80::5054:ff:fe9c:683/64 scope link 
       valid_lft forever preferred_lft forever
6: vlan20: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether 56:6b:cd:17:51:c7 brd ff:ff:ff:ff:ff:ff
    inet 172.16.2.7/24 brd 172.16.2.255 scope global vlan20
       valid_lft forever preferred_lft forever
    inet6 fe80::546b:cdff:fe17:51c7/64 scope link 
       valid_lft forever preferred_lft forever
7: vlan30: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether 12:1b:68:03:bc:c5 brd ff:ff:ff:ff:ff:ff
    inet 172.16.1.6/24 brd 172.16.1.255 scope global vlan30
       valid_lft forever preferred_lft forever
    inet6 fe80::101b:68ff:fe03:bcc5/64 scope link 
       valid_lft forever preferred_lft forever
8: vlan40: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether 06:16:44:26:8c:d4 brd ff:ff:ff:ff:ff:ff
    inet 172.16.3.5/24 brd 172.16.3.255 scope global vlan40
       valid_lft forever preferred_lft forever
    inet6 fe80::416:44ff:fe26:8cd4/64 scope link 
       valid_lft forever preferred_lft forever
9: vlan50: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether e6:41:2e:e6:fc:9d brd ff:ff:ff:ff:ff:ff
    inet 172.16.0.5/24 brd 172.16.0.255 scope global vlan50
       valid_lft forever preferred_lft forever
    inet6 fe80::e441:2eff:fee6:fc9d/64 scope link 
       valid_lft forever preferred_lft forever
```

## Compute
(irrelevant, the same as in the normal network isolation example)

# Variant 5 - collapsing certain networks into the provisioning network, e.g. internal API into provisioning

## Deployment command
```
openstack overcloud deploy --templates -e /home/stack/environment-basic-network-scenario/network-environment.yaml -e /home/stack/environment-basic-network-scenario/network-isolation-without-api-network.yaml  --control-flavor control --compute-flavor compute --ntp-server pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 1 --compute-scale 1
```

## Configuration

### Nic configuration
```
[stack@poc-undercloud environment-basic-network-scenario]$ cat /home/stack/environment-basic-network-scenario/network-environment.yaml
resource_registry:
  OS::TripleO::BlockStorage::Net::SoftwareConfig: /home/stack/templates-basic-network-scenario/single-nic-vlans/cinder-storage.yaml
  OS::TripleO::Compute::Net::SoftwareConfig: /home/stack/templates-basic-network-scenario/single-nic-vlans/compute.yaml
  OS::TripleO::Controller::Net::SoftwareConfig: /home/stack/templates-basic-network-scenario/single-nic-vlans/controller.yaml
  OS::TripleO::ObjectStorage::Net::SoftwareConfig: /home/stack/templates-basic-network-scenario/single-nic-vlans/swift-storage.yaml
  OS::TripleO::CephStorage::Net::SoftwareConfig: /home/stack/templates-basic-network-scenario/single-nic-vlans/ceph-storage.yaml
  (...)
```

```
[stack@poc-undercloud environment-basic-network-scenario]$ cat /home/stack/templates-basic-network-scenario/single-nic-vlans/controller.yaml
heat_template_version: 2015-04-30

description: >
  Software Config to drive os-net-config to configure VLANs for the
  controller role.

parameters:
  ControlPlaneIp:
    default: ''
    description: IP address/subnet on the ctlplane network
    type: string
  ExternalIpSubnet:
    default: ''
    description: IP address/subnet on the external network
    type: string
  InternalApiIpSubnet:
    default: ''
    description: IP address/subnet on the internal API network
    type: string
  StorageIpSubnet:
    default: ''
    description: IP address/subnet on the storage network
    type: string
  StorageMgmtIpSubnet:
    default: ''
    description: IP address/subnet on the storage mgmt network
    type: string
  TenantIpSubnet:
    default: ''
    description: IP address/subnet on the tenant network
    type: string
  ExternalNetworkVlanID:
    default: 10
    description: Vlan ID for the external network traffic.
    type: number
  InternalApiNetworkVlanID:
    default: 20
    description: Vlan ID for the internal_api network traffic.
    type: number
  StorageNetworkVlanID:
    default: 30
    description: Vlan ID for the storage network traffic.
    type: number
  StorageMgmtNetworkVlanID:
    default: 40
    description: Vlan ID for the storage mgmt network traffic.
    type: number
  TenantNetworkVlanID:
    default: 50
    description: Vlan ID for the tenant network traffic.
    type: number
  ExternalInterfaceDefaultRoute:
    default: '10.0.0.1'
    description: default route for the external network
    type: string
  ControlPlaneSubnetCidr: # Override this via parameter_defaults
    default: '24'
    description: The subnet CIDR of the control plane network.
    type: string
  DnsServers: # Override this via parameter_defaults
    default: []
    description: A list of DNS servers (2 max for some implementations) that will be added to resolv.conf.
    type: json
  EC2MetadataIp: # Override this via parameter_defaults
    description: The IP address of the EC2 metadata server.
    type: string

resources:
  OsNetConfigImpl:
    type: OS::Heat::StructuredConfig
    properties:
      group: os-apply-config
      config:
        os_net_config:
          network_config:
            -
              type: ovs_bridge
              name: {get_input: bridge_name}
              use_dhcp: false
              dns_servers: {get_param: DnsServers}
              addresses:
                -
                  ip_netmask:
                    list_join:
                      - '/'
                      - - {get_param: ControlPlaneIp}
                        - {get_param: ControlPlaneSubnetCidr}
              routes:
                -
                  ip_netmask: 169.254.169.254/32
                  next_hop: {get_param: EC2MetadataIp}
              members:
                -
                  type: interface
                  name: nic1
                  # force the MAC address of the bridge to this interface
                  primary: true
                -
                  type: vlan
                  vlan_id: {get_param: ExternalNetworkVlanID}
                  addresses:
                  -
                    ip_netmask: {get_param: ExternalIpSubnet}
                  routes:
                    -
                      default: true
                      next_hop: {get_param: ExternalInterfaceDefaultRoute}
#                -
#                  type: vlan
#                  vlan_id: {get_param: InternalApiNetworkVlanID}
#                  addresses:
#                  -
#                    ip_netmask: {get_param: InternalApiIpSubnet}
                -
                  type: vlan
                  vlan_id: {get_param: StorageNetworkVlanID}
                  addresses:
                  -
                    ip_netmask: {get_param: StorageIpSubnet}
                -
                  type: vlan
                  vlan_id: {get_param: StorageMgmtNetworkVlanID}
                  addresses:
                  -
                    ip_netmask: {get_param: StorageMgmtIpSubnet}
                -
                  type: vlan
                  vlan_id: {get_param: TenantNetworkVlanID}
                  addresses:
                  -
                    ip_netmask: {get_param: TenantIpSubnet}

outputs:
  OS::stack_id:
    description: The OsNetConfigImpl resource.
    value: {get_resource: OsNetConfigImpl}
```

```
[stack@poc-undercloud environment-basic-network-scenario]$ cat /home/stack/templates-basic-network-scenario/single-nic-vlans/compute.yaml
heat_template_version: 2015-04-30

description: >
  Software Config to drive os-net-config to configure VLANs for the
  compute role.

parameters:
  ControlPlaneIp:
    default: ''
    description: IP address/subnet on the ctlplane network
    type: string
  ExternalIpSubnet:
    default: ''
    description: IP address/subnet on the external network
    type: string
  InternalApiIpSubnet:
    default: ''
    description: IP address/subnet on the internal API network
    type: string
  StorageIpSubnet:
    default: ''
    description: IP address/subnet on the storage network
    type: string
  StorageMgmtIpSubnet:
    default: ''
    description: IP address/subnet on the storage mgmt network
    type: string
  TenantIpSubnet:
    default: ''
    description: IP address/subnet on the tenant network
    type: string
  InternalApiNetworkVlanID:
    default: 20
    description: Vlan ID for the internal_api network traffic.
    type: number
  StorageNetworkVlanID:
    default: 30
    description: Vlan ID for the storage network traffic.
    type: number
  TenantNetworkVlanID:
    default: 50
    description: Vlan ID for the tenant network traffic.
    type: number
  ControlPlaneSubnetCidr: # Override this via parameter_defaults
    default: '24'
    description: The subnet CIDR of the control plane network.
    type: string
  ControlPlaneDefaultRoute: # Override this via parameter_defaults
    description: The subnet CIDR of the control plane network.
    type: string
  DnsServers: # Override this via parameter_defaults
    default: []
    description: A list of DNS servers (2 max for some implementations) that will be added to resolv.conf.
    type: json
  EC2MetadataIp: # Override this via parameter_defaults
    description: The IP address of the EC2 metadata server.
    type: string

resources:
  OsNetConfigImpl:
    type: OS::Heat::StructuredConfig
    properties:
      group: os-apply-config
      config:
        os_net_config:
          network_config:
            -
              type: ovs_bridge
              name: {get_input: bridge_name}
              use_dhcp: false
              dns_servers: {get_param: DnsServers}
              addresses:
                -
                  ip_netmask:
                    list_join:
                      - '/'
                      - - {get_param: ControlPlaneIp}
                        - {get_param: ControlPlaneSubnetCidr}
              routes:
                -
                  ip_netmask: 169.254.169.254/32
                  next_hop: {get_param: EC2MetadataIp}
                -
                  default: true
                  next_hop: {get_param: ControlPlaneDefaultRoute}
              members:
                -
                  type: interface
                  name: nic1
                  # force the MAC address of the bridge to this interface
                  primary: true
#                -
#                  type: vlan
#                  vlan_id: {get_param: InternalApiNetworkVlanID}
#                  addresses:
#                  -
#                    ip_netmask: {get_param: InternalApiIpSubnet}
                -
                  type: vlan
                  vlan_id: {get_param: StorageNetworkVlanID}
                  addresses:
                  -
                    ip_netmask: {get_param: StorageIpSubnet}
                -
                  type: vlan
                  vlan_id: {get_param: TenantNetworkVlanID}
                  addresses:
                  -
                    ip_netmask: {get_param: TenantIpSubnet}

outputs:
  OS::stack_id:
    description: The OsNetConfigImpl resource.
    value: {get_resource: OsNetConfigImpl}
```

### Neutron configuration
```
[stack@poc-undercloud environment-basic-network-scenario]$ cat network-isolation-without-api-network.yaml
# Enable the creation of Neutron networks for isolated Overcloud
# traffic and configure each role to assign ports (related
# to that role) on these networks.
resource_registry:
  OS::TripleO::Network::External: /usr/share/openstack-tripleo-heat-templates/network/external.yaml
#  OS::TripleO::Network::InternalApi: /usr/share/openstack-tripleo-heat-templates/network/internal_api.yaml
  OS::TripleO::Network::StorageMgmt: /usr/share/openstack-tripleo-heat-templates/network/storage_mgmt.yaml
  OS::TripleO::Network::Storage: /usr/share/openstack-tripleo-heat-templates/network/storage.yaml
  OS::TripleO::Network::Tenant: /usr/share/openstack-tripleo-heat-templates/network/tenant.yaml

  # Port assignments for the VIPs
  OS::TripleO::Network::Ports::ExternalVipPort: /usr/share/openstack-tripleo-heat-templates/network/ports/external.yaml
#  OS::TripleO::Network::Ports::InternalApiVipPort: /usr/share/openstack-tripleo-heat-templates/network/ports/internal_api.yaml
  OS::TripleO::Network::Ports::StorageVipPort: /usr/share/openstack-tripleo-heat-templates/network/ports/storage.yaml
  OS::TripleO::Network::Ports::StorageMgmtVipPort: /usr/share/openstack-tripleo-heat-templates/network/ports/storage_mgmt.yaml
  OS::TripleO::Network::Ports::TenantVipPort: /usr/share/openstack-tripleo-heat-templates/network/ports/tenant.yaml
  OS::TripleO::Network::Ports::RedisVipPort: /usr/share/openstack-tripleo-heat-templates/network/ports/vip.yaml

  # Port assignments for the controller role
  OS::TripleO::Controller::Ports::ExternalPort: /usr/share/openstack-tripleo-heat-templates/network/ports/external.yaml
#  OS::TripleO::Controller::Ports::InternalApiPort: /usr/share/openstack-tripleo-heat-templates/network/ports/internal_api.yaml
  OS::TripleO::Controller::Ports::StoragePort: /usr/share/openstack-tripleo-heat-templates/network/ports/storage.yaml
  OS::TripleO::Controller::Ports::StorageMgmtPort: /usr/share/openstack-tripleo-heat-templates/network/ports/storage_mgmt.yaml
  OS::TripleO::Controller::Ports::TenantPort: /usr/share/openstack-tripleo-heat-templates/network/ports/tenant.yaml

  # Port assignments for the compute role
#  OS::TripleO::Compute::Ports::InternalApiPort: /usr/share/openstack-tripleo-heat-templates/network/ports/internal_api.yaml
  OS::TripleO::Compute::Ports::StoragePort: /usr/share/openstack-tripleo-heat-templates/network/ports/storage.yaml
  OS::TripleO::Compute::Ports::TenantPort: /usr/share/openstack-tripleo-heat-templates/network/ports/tenant.yaml

  # Port assignments for the ceph storage role
  OS::TripleO::CephStorage::Ports::StoragePort: /usr/share/openstack-tripleo-heat-templates/network/ports/storage.yaml
  OS::TripleO::CephStorage::Ports::StorageMgmtPort: /usr/share/openstack-tripleo-heat-templates/network/ports/storage_mgmt.yaml

  # Port assignments for the swift storage role
#  OS::TripleO::SwiftStorage::Ports::InternalApiPort: /usr/share/openstack-tripleo-heat-templates/network/ports/internal_api.yaml
  OS::TripleO::SwiftStorage::Ports::StoragePort: /usr/share/openstack-tripleo-heat-templates/network/ports/storage.yaml
  OS::TripleO::SwiftStorage::Ports::StorageMgmtPort: /usr/share/openstack-tripleo-heat-templates/network/ports/storage_mgmt.yaml

  # Port assignments for the block storage role
#  OS::TripleO::BlockStorage::Ports::InternalApiPort: /usr/share/openstack-tripleo-heat-templates/network/ports/internal_api.yaml
  OS::TripleO::BlockStorage::Ports::StoragePort: /usr/share/openstack-tripleo-heat-templates/network/ports/storage.yaml
  OS::TripleO::BlockStorage::Ports::StorageMgmtPort: /usr/share/openstack-tripleo-heat-templates/network/ports/storage_mgmt.yaml
```

### Service mapping configuration
```
[stack@poc-undercloud environment-basic-network-scenario]$ cat /home/stack/environment-basic-network-scenario/network-environment.yaml
r(...)

  ServiceNetMap:
    NeutronTenantNetwork: tenant
    CeilometerApiNetwork: ctlplane
    MongoDbNetwork: ctlplane
    CinderApiNetwork: ctlplane
    CinderIscsiNetwork: storage
    GlanceApiNetwork: storage
    GlanceRegistryNetwork: ctlplane
    KeystoneAdminApiNetwork: ctlplane
    KeystonePublicApiNetwork: ctlplane
    NeutronApiNetwork: ctlplane
    HeatApiNetwork: ctlplane
    NovaApiNetwork: ctlplane
    NovaMetadataNetwork: ctlplane
    NovaVncProxyNetwork: ctlplane
    SwiftMgmtNetwork: storage_mgmt
    SwiftProxyNetwork: storage
    HorizonNetwork: ctlplane
    MemcachedNetwork: ctlplane
    RabbitMqNetwork: ctlplane
    RedisNetwork: ctlplane
    MysqlNetwork: ctlplane
    CephClusterNetwork: storage_mgmt
    CephPublicNetwork: storage
    # Define which network will be used for hostname resolution
    ControllerHostnameResolveNetwork: ctlplane
    ComputeHostnameResolveNetwork: ctlplane
    BlockStorageHostnameResolveNetwork: ctlplane
    ObjectStorageHostnameResolveNetwork: ctlplane
    CephStorageHostnameResolveNetwork: storage
```

## Neutron
```
[stack@poc-undercloud ~]$ neutron net-list
+--------------------------------------+--------------+-----------------------------------------------------+
| id                                   | name         | subnets                                             |
+--------------------------------------+--------------+-----------------------------------------------------+
| 1d259d43-81e0-4069-89c1-492b9fa7cbb8 | storage_mgmt | 6a3efca2-be92-461e-baac-88b4fe6f6b61 172.16.3.0/24  |
| ba433781-d3f5-4e78-b3f9-17affb5cc92b | ctlplane     | 5694ef8e-10a2-413f-80e6-45dcf0f0a1b8 198.18.53.0/26 |
| af1d7331-f56b-4e4a-b6db-af522c62f2d5 | storage      | c5feeefe-781a-4a7b-9454-84792bf4f820 172.16.1.0/24  |
| c20ca307-5374-4791-827a-44e2f2c993f0 | external     | 55762844-d6de-460c-8f16-115585cb9f23 10.1.1.0/24    |
| 1b9feada-2f5a-4ea4-ad19-6cd47093ae4f | tenant       | 0033ad0b-388c-4c0a-bb94-05d82e07fda1 172.16.0.0/24  |
+--------------------------------------+--------------+-----------------------------------------------------+
```
## Controller
```
[heat-admin@overcloud-controller-0 ~]$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN 
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: ens8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master ovs-system state UP qlen 1000
    link/ether 52:54:00:9d:d4:c9 brd ff:ff:ff:ff:ff:ff
3: ovs-system: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN 
    link/ether ee:ea:2b:67:2b:79 brd ff:ff:ff:ff:ff:ff
4: br-ex: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether 52:54:00:9d:d4:c9 brd ff:ff:ff:ff:ff:ff
    inet 198.18.53.27/24 brd 198.18.53.255 scope global br-ex
       valid_lft forever preferred_lft forever
    inet 198.18.53.25/32 brd 198.18.53.255 scope global br-ex
       valid_lft forever preferred_lft forever
    inet 198.18.53.24/32 brd 198.18.53.255 scope global br-ex
       valid_lft forever preferred_lft forever
    inet6 fe80::5054:ff:fe9d:d4c9/64 scope link 
       valid_lft forever preferred_lft forever
5: vlan30: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether 6a:ac:fe:91:8a:80 brd ff:ff:ff:ff:ff:ff
    inet 172.16.1.6/24 brd 172.16.1.255 scope global vlan30
       valid_lft forever preferred_lft forever
    inet 172.16.1.4/32 brd 172.16.1.255 scope global vlan30
       valid_lft forever preferred_lft forever
    inet6 fe80::68ac:feff:fe91:8a80/64 scope link 
       valid_lft forever preferred_lft forever
6: vlan100: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether f6:84:ec:8b:45:7b brd ff:ff:ff:ff:ff:ff
    inet 10.1.1.3/24 brd 10.1.1.255 scope global vlan100
       valid_lft forever preferred_lft forever
    inet 10.1.1.2/32 brd 10.1.1.255 scope global vlan100
       valid_lft forever preferred_lft forever
    inet6 fe80::f484:ecff:fe8b:457b/64 scope link 
       valid_lft forever preferred_lft forever
7: vlan40: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether 1a:bd:22:51:d3:c6 brd ff:ff:ff:ff:ff:ff
    inet 172.16.3.5/24 brd 172.16.3.255 scope global vlan40
       valid_lft forever preferred_lft forever
    inet 172.16.3.4/32 brd 172.16.3.255 scope global vlan40
       valid_lft forever preferred_lft forever
    inet6 fe80::18bd:22ff:fe51:d3c6/64 scope link 
       valid_lft forever preferred_lft forever
8: vlan50: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether 26:f0:1d:38:50:5f brd ff:ff:ff:ff:ff:ff
    inet 172.16.0.5/24 brd 172.16.0.255 scope global vlan50
       valid_lft forever preferred_lft forever
    inet6 fe80::24f0:1dff:fe38:505f/64 scope link 
       valid_lft forever preferred_lft forever
9: br-int: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN 
    link/ether 7e:31:58:7d:9f:48 brd ff:ff:ff:ff:ff:ff
10: br-tun: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN 
    link/ether 46:d9:10:b4:79:4a brd ff:ff:ff:ff:ff:ff
```

```
[root@overcloud-controller-0 ~]# grep 198.18.53 /etc/ -R
/etc/puppet/hieradata/controller.yaml:apache::ip: 198.18.53.27
/etc/puppet/hieradata/controller.yaml:ceilometer::agent::auth::auth_url: http://198.18.53.24:5000/v2.0
/etc/puppet/hieradata/controller.yaml:ceilometer::agent::central::coordination_url: redis://198.18.53.25:6379
/etc/puppet/hieradata/controller.yaml:ceilometer::api::host: 198.18.53.27
/etc/puppet/hieradata/controller.yaml:ceilometer::api::keystone_auth_uri: http://198.18.53.24:5000/v2.0
/etc/puppet/hieradata/controller.yaml:ceilometer::api::keystone_identity_uri: http://198.18.53.24:35357
/etc/puppet/hieradata/controller.yaml:ceilometer_mysql_conn_string: mysql://ceilometer:unset@198.18.53.24/ceilometer
/etc/puppet/hieradata/controller.yaml:cinder::api::auth_uri: http://198.18.53.24:5000/v2.0
/etc/puppet/hieradata/controller.yaml:cinder::api::bind_host: 198.18.53.27
/etc/puppet/hieradata/controller.yaml:cinder::api::identity_uri: http://198.18.53.24:35357
/etc/puppet/hieradata/controller.yaml:cinder::database_connection: mysql://cinder:wjAJWacqxNEezVExxfsy4bz28@198.18.53.24/cinder
/etc/puppet/hieradata/controller.yaml:glance::api::auth_uri: http://198.18.53.24:5000/v2.0
/etc/puppet/hieradata/controller.yaml:glance::api::database_connection: mysql://glance:UjWmTafgPfJbGsZWRXWXwsKfP@198.18.53.24/glance
/etc/puppet/hieradata/controller.yaml:glance::api::identity_uri: http://198.18.53.24:35357
/etc/puppet/hieradata/controller.yaml:glance::backend::swift::swift_store_auth_address: http://198.18.53.24:5000/v2.0
/etc/puppet/hieradata/controller.yaml:glance::registry::auth_uri: http://198.18.53.24:5000/v2.0
/etc/puppet/hieradata/controller.yaml:glance::registry::bind_host: 198.18.53.27
/etc/puppet/hieradata/controller.yaml:glance::registry::database_connection: mysql://glance:UjWmTafgPfJbGsZWRXWXwsKfP@198.18.53.24/glance
/etc/puppet/hieradata/controller.yaml:glance::registry::identity_uri: http://198.18.53.24:35357
/etc/puppet/hieradata/controller.yaml:glance_registry_network: 198.18.53.27
/etc/puppet/hieradata/controller.yaml:heat::api::bind_host: 198.18.53.27
/etc/puppet/hieradata/controller.yaml:heat::api_cfn::bind_host: 198.18.53.27
/etc/puppet/hieradata/controller.yaml:heat::api_cloudwatch::bind_host: 198.18.53.27
/etc/puppet/hieradata/controller.yaml:heat::auth_uri: http://198.18.53.24:5000/v2.0
/etc/puppet/hieradata/controller.yaml:heat::database_connection: mysql://heat:TM69XyDrTQZKkcqkPcWC3dPVU@198.18.53.24/heat
/etc/puppet/hieradata/controller.yaml:heat::engine::heat_metadata_server_url: http://198.18.53.24:8000
/etc/puppet/hieradata/controller.yaml:heat::engine::heat_waitcondition_server_url: http://198.18.53.24:8000/v1/waitcondition
/etc/puppet/hieradata/controller.yaml:heat::engine::heat_watch_server_url: http://198.18.53.24:8003
/etc/puppet/hieradata/controller.yaml:heat::identity_uri: http://198.18.53.24:35357
/etc/puppet/hieradata/controller.yaml:heat::keystone::domain::auth_url: http://198.18.53.24:35357/v2.0
/etc/puppet/hieradata/controller.yaml:heat::keystone_ec2_uri: http://198.18.53.24:5000/v2.0/ec2tokens
/etc/puppet/hieradata/controller.yaml:horizon::bind_address: 198.18.53.27
/etc/puppet/hieradata/controller.yaml:horizon::keystone_url: http://198.18.53.24:5000/v2.0
/etc/puppet/hieradata/controller.yaml:keystone::admin_bind_host: 198.18.53.27
/etc/puppet/hieradata/controller.yaml:keystone::database_connection: mysql://keystone:ptJHpY7hemfwve8uW2DuE43zg@198.18.53.24/keystone
/etc/puppet/hieradata/controller.yaml:keystone::public_bind_host: 198.18.53.27
/etc/puppet/hieradata/controller.yaml:memcached::listen_ip: 198.18.53.27
/etc/puppet/hieradata/controller.yaml:mongodb::server::bind_ip: 198.18.53.27
/etc/puppet/hieradata/controller.yaml:mysql_bind_host: 198.18.53.27
/etc/puppet/hieradata/controller.yaml:mysql_virtual_ip: 198.18.53.24
/etc/puppet/hieradata/controller.yaml:neutron::agents::metadata::auth_url: http://198.18.53.24:35357
/etc/puppet/hieradata/controller.yaml:neutron::agents::metadata::metadata_ip: 198.18.53.27
/etc/puppet/hieradata/controller.yaml:neutron::bind_host: 198.18.53.27
/etc/puppet/hieradata/controller.yaml:neutron::server::auth_uri: http://198.18.53.24:5000/v2.0
/etc/puppet/hieradata/controller.yaml:neutron::server::database_connection: mysql://neutron:xjrJnCHpdbYpfr2yGaRkHM7yh@198.18.53.24/ovs_neutron?charset=utf8
/etc/puppet/hieradata/controller.yaml:neutron::server::identity_uri: http://198.18.53.24:35357
/etc/puppet/hieradata/controller.yaml:neutron::server::notifications::auth_url: http://198.18.53.24:35357
/etc/puppet/hieradata/controller.yaml:neutron::server::notifications::nova_url: http://198.18.53.24:8774/v2/%(tenant_id)s
/etc/puppet/hieradata/controller.yaml:neutron_dsn: mysql://neutron:xjrJnCHpdbYpfr2yGaRkHM7yh@198.18.53.24/ovs_neutron?charset=utf8
/etc/puppet/hieradata/controller.yaml:nova::api::api_bind_address: 198.18.53.27
/etc/puppet/hieradata/controller.yaml:nova::api::auth_uri: http://198.18.53.24:5000/v2.0
/etc/puppet/hieradata/controller.yaml:nova::api::identity_uri: http://198.18.53.24:35357
/etc/puppet/hieradata/controller.yaml:nova::api::metadata_listen: 198.18.53.27
/etc/puppet/hieradata/controller.yaml:nova::database_connection: mysql://nova:8mdnxuQDPaGUna9rcAkmbRZPj@198.18.53.24/nova
/etc/puppet/hieradata/controller.yaml:nova::network::neutron::neutron_admin_auth_url: http://198.18.53.24:35357/v2.0
/etc/puppet/hieradata/controller.yaml:nova::network::neutron::neutron_url: http://198.18.53.24:9696
/etc/puppet/hieradata/controller.yaml:nova::vncproxy::host: 198.18.53.27
/etc/puppet/hieradata/controller.yaml:rabbitmq::node_ip_address: 198.18.53.27
/etc/puppet/hieradata/controller.yaml:redis::bind: 198.18.53.27
/etc/puppet/hieradata/controller.yaml:redis_vip: 198.18.53.25
/etc/puppet/hieradata/controller.yaml:swift::proxy::authtoken::auth_uri: http://198.18.53.24:5000/v2.0
/etc/puppet/hieradata/controller.yaml:swift::proxy::authtoken::identity_uri: http://198.18.53.24:35357
/etc/puppet/hieradata/vip_data.yaml:ceilometer_api_vip: 198.18.53.24
/etc/puppet/hieradata/vip_data.yaml:cinder_api_vip: 198.18.53.24
/etc/puppet/hieradata/vip_data.yaml:glance_registry_vip: 198.18.53.24
/etc/puppet/hieradata/vip_data.yaml:heat_api_vip: 198.18.53.24
/etc/puppet/hieradata/vip_data.yaml:horizon_vip: 198.18.53.24
/etc/puppet/hieradata/vip_data.yaml:keystone_admin_api_vip: 198.18.53.24
/etc/puppet/hieradata/vip_data.yaml:keystone_public_api_vip: 198.18.53.24
/etc/puppet/hieradata/vip_data.yaml:mysql_vip: 198.18.53.24
/etc/puppet/hieradata/vip_data.yaml:neutron_api_vip: 198.18.53.24
/etc/puppet/hieradata/vip_data.yaml:nova_api_vip: 198.18.53.24
/etc/puppet/hieradata/vip_data.yaml:nova_metadata_vip: 198.18.53.24
/etc/puppet/hieradata/vip_data.yaml:redis_vip: 198.18.53.25
/etc/puppet/hieradata/vip_data.yaml:tripleo::loadbalancer::controller_virtual_ip: 198.18.53.24
/etc/puppet/hieradata/vip_data.yaml:tripleo::loadbalancer::internal_api_virtual_ip: 198.18.53.24
/etc/puppet/hieradata/vip_data.yaml:tripleo::redis_notification::haproxy_monitor_ip: 198.18.53.24
/etc/puppet/hieradata/all_nodes.yaml:ceilometer::rabbit_hosts: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:ceilometer_api_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:cinder::rabbit_hosts: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:cinder_api_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:controller_node_ips: 198.18.53.27
/etc/puppet/hieradata/all_nodes.yaml:glance_registry_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:heat::rabbit_hosts: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:heat_api_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:horizon_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:keystone::rabbit_hosts: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:keystone_admin_api_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:keystone_public_api_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:memcache_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:memcache_node_ips_v6: ['inet6:[198.18.53.27]']
/etc/puppet/hieradata/all_nodes.yaml:mongo_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:mysql_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:neutron::rabbit_hosts: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:neutron_api_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:nova::rabbit_hosts: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:nova_api_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:nova_metadata_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:rabbit_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:redis_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/bootstrap_node.yaml:bootstrap_nodeid_ip: 198.18.53.27
/etc/puppet/hieradata/swift_devices_and_proxy.yaml:swift::proxy::cache::memcache_servers: ['198.18.53.27:11211']
/etc/puppet/hieradata/heat_config_overcloud-ControllerNodesPostDeployment-k7sdut4rp3lr-ControllerPuppetConfig-335rdtygnpsn-ControllerPuppetConfigImpl-wzutgas2liur.json:{"update_identifier": "{u'deployment_identifier': 1456371124, u'controller_config': {u'0': u'os-apply-config deployment e026a3f8-0197-4f1c-a511-885ddcac0ef8 completed,Root CA cert injection not enabled.,TLS not enabled.,None,'}, u'allnodes_extra': u'none'}", "deploy_resource_name": "0", "deploy_signal_id": "http://198.18.53.10:8000/v1/signal/arn%3Aopenstack%3Aheat%3A%3A9df63e1a1a1e4611950f36c99fb2da8b%3Astacks%2Fovercloud-ControllerNodesPostDeployment-k7sdut4rp3lr-ControllerOvercloudServicesDeployment_Step7-dwjk2wt4psra%2F53088005-404a-49ed-95a2-92db39aceae1%2Fresources%2F0?Timestamp=2016-02-25T04%3A04%3A07Z&SignatureMethod=HmacSHA256&AWSAccessKeyId=bd83cd1647114a75b4085956f9ee2d19&SignatureVersion=2&Signature=mo3LpTpnGxBej%2Fh6pjQiExTe7Dg0acKQg0PDVKlEeZ8%3D", "deploy_signal_transport": "CFN_SIGNAL", "deploy_signal_verb": "POST", "step": "6", "deploy_server_id": "82677bbd-c5a9-4676-9a2e-7b5c765dba1d", "deploy_stack_id": "overcloud-ControllerNodesPostDeployment-k7sdut4rp3lr-ControllerOvercloudServicesDeployment_Step7-dwjk2wt4psra/53088005-404a-49ed-95a2-92db39aceae1", "deploy_action": "CREATE"}
/etc/puppet/hieradata/heat_config_overcloud-ControllerNodesPostDeployment-k7sdut4rp3lr-ControllerRingbuilderPuppetConfig-cdcl2rpxuyun.json:{"update_identifier": "{u'deployment_identifier': 1456371124, u'controller_config': {u'0': u'os-apply-config deployment e026a3f8-0197-4f1c-a511-885ddcac0ef8 completed,Root CA cert injection not enabled.,TLS not enabled.,None,'}, u'allnodes_extra': u'none'}", "deploy_resource_name": "0", "deploy_signal_id": "http://198.18.53.10:8000/v1/signal/arn%3Aopenstack%3Aheat%3A%3A9df63e1a1a1e4611950f36c99fb2da8b%3Astacks%2Fovercloud-ControllerNodesPostDeployment-k7sdut4rp3lr-ControllerRingbuilderDeployment_Step3-og6cqrkxdomg%2Ff018636d-3192-4cc6-a74c-f921a4f9fc39%2Fresources%2F0?Timestamp=2016-02-25T03%3A52%3A58Z&SignatureMethod=HmacSHA256&AWSAccessKeyId=3b94eaac6d9e4465a399c75b715c4f34&SignatureVersion=2&Signature=GrI%2Bgrv4KOgQHbpmzFRmfhw8DHUDkxSdVF4haHHeuLU%3D", "deploy_signal_transport": "CFN_SIGNAL", "deploy_signal_verb": "POST", "deploy_server_id": "82677bbd-c5a9-4676-9a2e-7b5c765dba1d", "deploy_stack_id": "overcloud-ControllerNodesPostDeployment-k7sdut4rp3lr-ControllerRingbuilderDeployment_Step3-og6cqrkxdomg/f018636d-3192-4cc6-a74c-f921a4f9fc39", "deploy_action": "CREATE"}
/etc/cinder/cinder.conf:osapi_volume_listen=198.18.53.27
/etc/cinder/cinder.conf:connection=mysql://cinder:wjAJWacqxNEezVExxfsy4bz28@198.18.53.24/cinder
/etc/cinder/cinder.conf:rabbit_hosts=198.18.53.27
/etc/cinder/api-paste.ini:auth_uri=http://198.18.53.24:5000/v2.0
/etc/cinder/api-paste.ini:identity_uri=http://198.18.53.24:35357
/etc/hosts:198.18.53.26 overcloud-compute-0.localdomain overcloud-compute-0
/etc/hosts:198.18.53.27 overcloud-controller-0.localdomain overcloud-controller-0
/etc/glance/glance-cache.conf:registry_host=198.18.53.27
/etc/glance/glance-cache.conf:swift_store_auth_address=http://198.18.53.24:5000/v2.0
/etc/glance/glance-registry.conf:bind_host=198.18.53.27
/etc/glance/glance-registry.conf:connection=mysql://glance:UjWmTafgPfJbGsZWRXWXwsKfP@198.18.53.24/glance
/etc/glance/glance-registry.conf:identity_uri=http://198.18.53.24:35357
/etc/glance/glance-registry.conf:auth_uri=http://198.18.53.24:5000/v2.0
/etc/glance/glance-api.conf:registry_host=198.18.53.27
/etc/glance/glance-api.conf:connection=mysql://glance:UjWmTafgPfJbGsZWRXWXwsKfP@198.18.53.24/glance
/etc/glance/glance-api.conf:identity_uri=http://198.18.53.24:35357
/etc/glance/glance-api.conf:auth_uri=http://198.18.53.24:5000/v2.0
/etc/glance/glance-api.conf:swift_store_auth_address=http://198.18.53.24:5000/v2.0
/etc/openstack-dashboard/local_settings:        'LOCATION': [ '198.18.53.27:11211', ],
/etc/openstack-dashboard/local_settings:OPENSTACK_KEYSTONE_URL = "http://198.18.53.24:5000/v2.0"
/etc/os-collect-config.conf:metadata_url = http://198.18.53.10:8000/v1/
/etc/ceilometer/ceilometer.conf:host=198.18.53.27
/etc/ceilometer/ceilometer.conf:backend_url=redis://198.18.53.25:6379
/etc/ceilometer/ceilometer.conf:connection=mongodb://198.18.53.27:27017/ceilometer?replicaSet=tripleo
/etc/ceilometer/ceilometer.conf:auth_uri=http://198.18.53.24:5000/v2.0
/etc/ceilometer/ceilometer.conf:identity_uri=http://198.18.53.24:35357
/etc/ceilometer/ceilometer.conf:os_auth_url=http://198.18.53.24:5000/v2.0
/etc/ceilometer/ceilometer.conf:rabbit_hosts=198.18.53.27
/etc/keystone/keystone.conf:admin_bind_host=198.18.53.27
/etc/keystone/keystone.conf:public_bind_host=198.18.53.27
/etc/keystone/keystone.conf:connection = mysql://keystone:ptJHpY7hemfwve8uW2DuE43zg@198.18.53.24/keystone
/etc/keystone/keystone.conf:rabbit_hosts = 198.18.53.27
/etc/mongod.conf:bind_ip = 198.18.53.27
/etc/os-net-config/config.json:{"network_config": [{"dns_servers": ["8.8.8.8", "8.8.4.4"], "name": "br-ex", "members": [{"type": "interface", "name": "nic1", "primary": true}, {"routes": [{"default": true, "next_hop": "10.1.1.1"}], "type": "vlan", "addresses": [{"ip_netmask": "10.1.1.3/24"}], "vlan_id": 100}, {"type": "vlan", "addresses": [{"ip_netmask": "172.16.1.6/24"}], "vlan_id": 30}, {"type": "vlan", "addresses": [{"ip_netmask": "172.16.3.5/24"}], "vlan_id": 40}, {"type": "vlan", "addresses": [{"ip_netmask": "172.16.0.5/24"}], "vlan_id": 50}], "routes": [{"ip_netmask": "169.254.169.254/32", "next_hop": "198.18.53.10"}], "use_dhcp": false, "type": "ovs_bridge", "addresses": [{"ip_netmask": "198.18.53.27/24"}]}]}
/etc/haproxy/haproxy.cfg:  bind 198.18.53.24:8777 transparent
/etc/haproxy/haproxy.cfg:  server overcloud-controller-0 198.18.53.27:8777 check fall 5 inter 2000 rise 2
/etc/haproxy/haproxy.cfg:  bind 198.18.53.24:8776 transparent
/etc/haproxy/haproxy.cfg:  server overcloud-controller-0 198.18.53.27:8776 check fall 5 inter 2000 rise 2
/etc/haproxy/haproxy.cfg:  server overcloud-controller-0 198.18.53.27:9191 check fall 5 inter 2000 rise 2
/etc/haproxy/haproxy.cfg:  bind 198.18.53.24:1993 
/etc/haproxy/haproxy.cfg:  bind 198.18.53.24:8004 transparent
/etc/haproxy/haproxy.cfg:  server overcloud-controller-0 198.18.53.27:8004 check fall 5 inter 2000 rise 2
/etc/haproxy/haproxy.cfg:  bind 198.18.53.24:8000 transparent
/etc/haproxy/haproxy.cfg:  server overcloud-controller-0 198.18.53.27:8000 check fall 5 inter 2000 rise 2
/etc/haproxy/haproxy.cfg:  bind 198.18.53.24:8003 transparent
/etc/haproxy/haproxy.cfg:  server overcloud-controller-0 198.18.53.27:8003 check fall 5 inter 2000 rise 2
/etc/haproxy/haproxy.cfg:  bind 198.18.53.24:80 transparent
/etc/haproxy/haproxy.cfg:  server overcloud-controller-0 198.18.53.27:80 check fall 5 inter 2000 rise 2
/etc/haproxy/haproxy.cfg:  bind 198.18.53.24:35357 transparent
/etc/haproxy/haproxy.cfg:  server overcloud-controller-0 198.18.53.27:35357 check fall 5 inter 2000 rise 2
/etc/haproxy/haproxy.cfg:  bind 198.18.53.24:5000 transparent
/etc/haproxy/haproxy.cfg:  server overcloud-controller-0 198.18.53.27:5000 check fall 5 inter 2000 rise 2
/etc/haproxy/haproxy.cfg:  bind 198.18.53.24:3306 transparent
/etc/haproxy/haproxy.cfg:  server overcloud-controller-0 198.18.53.27:3306 backup check fall 5 inter 2000 on-marked-down shutdown-sessions port 9200 rise 2
/etc/haproxy/haproxy.cfg:  bind 198.18.53.24:9696 transparent
/etc/haproxy/haproxy.cfg:  server overcloud-controller-0 198.18.53.27:9696 check fall 5 inter 2000 rise 2
/etc/haproxy/haproxy.cfg:  bind 198.18.53.24:8773 transparent
/etc/haproxy/haproxy.cfg:  server overcloud-controller-0 198.18.53.27:8773 check fall 5 inter 2000 rise 2
/etc/haproxy/haproxy.cfg:  bind 198.18.53.24:8775 transparent
/etc/haproxy/haproxy.cfg:  server overcloud-controller-0 198.18.53.27:8775 check fall 5 inter 2000 rise 2
/etc/haproxy/haproxy.cfg:  bind 198.18.53.24:6080 transparent
/etc/haproxy/haproxy.cfg:  server overcloud-controller-0 198.18.53.27:6080 check fall 5 inter 2000 rise 2
/etc/haproxy/haproxy.cfg:  bind 198.18.53.24:8774 transparent
/etc/haproxy/haproxy.cfg:  server overcloud-controller-0 198.18.53.27:8774 check fall 5 inter 2000 rise 2
/etc/haproxy/haproxy.cfg:  bind 198.18.53.25:6379 transparent
/etc/haproxy/haproxy.cfg:  server overcloud-controller-0 198.18.53.27:6379 check fall 5 inter 2000 rise 2
/etc/swift/proxy-server.conf:auth_uri = http://198.18.53.24:5000/v2.0
/etc/swift/proxy-server.conf:identity_uri = http://198.18.53.24:35357
/etc/swift/proxy-server.conf:memcache_servers = 198.18.53.27:11211
/etc/my.cnf.d/galera.cnf:wsrep_provider_options = gmcast.listen_addr=tcp://[198.18.53.27]:4567;
/etc/rabbitmq/rabbitmq-env.conf:NODE_IP_ADDRESS=198.18.53.27
/etc/nova/nova.conf:ec2_listen=198.18.53.27
/etc/nova/nova.conf:osapi_compute_listen=198.18.53.27
/etc/nova/nova.conf:metadata_listen=198.18.53.27
/etc/nova/nova.conf:novncproxy_host=198.18.53.27
/etc/nova/nova.conf:novncproxy_base_url=http://198.18.53.27:6080/vnc_auto.html
/etc/nova/nova.conf:memcached_servers=198.18.53.27:11211
/etc/nova/nova.conf:osapi_volume_listen=198.18.53.27
/etc/nova/nova.conf:connection=mysql://nova:8mdnxuQDPaGUna9rcAkmbRZPj@198.18.53.24/nova
/etc/nova/nova.conf:auth_uri=http://198.18.53.24:5000/v2.0
/etc/nova/nova.conf:identity_uri=http://198.18.53.24:35357
/etc/nova/nova.conf:url=http://198.18.53.24:9696
/etc/nova/nova.conf:admin_auth_url=http://198.18.53.24:35357/v2.0
/etc/nova/nova.conf:rabbit_hosts=198.18.53.27
/etc/heat/heat.conf:heat_metadata_server_url =http://198.18.53.24:8000
/etc/heat/heat.conf:heat_waitcondition_server_url =http://198.18.53.24:8000/v1/waitcondition
/etc/heat/heat.conf:heat_watch_server_url =http://198.18.53.24:8003
/etc/heat/heat.conf:connection = mysql://heat:TM69XyDrTQZKkcqkPcWC3dPVU@198.18.53.24/heat
/etc/heat/heat.conf:auth_uri = http://198.18.53.24:5000/v2.0/ec2tokens
/etc/heat/heat.conf:bind_host = 198.18.53.27
/etc/heat/heat.conf:bind_host = 198.18.53.27
/etc/heat/heat.conf:bind_host = 198.18.53.27
/etc/heat/heat.conf:auth_uri = http://198.18.53.24:5000/v2.0
/etc/heat/heat.conf:identity_uri = http://198.18.53.24:35357
/etc/heat/heat.conf:rabbit_hosts = 198.18.53.27
/etc/httpd/conf.d/15-default.conf:<VirtualHost 198.18.53.27:80>
/etc/httpd/conf.d/10-horizon_vhost.conf:<VirtualHost 198.18.53.27:80>
/etc/httpd/conf/ports.conf:Listen 198.18.53.27:80
/etc/httpd/logs/horizon_access.log:198.18.53.27 - - [25/Feb/2016:04:08:20 +0000] "OPTIONS * HTTP/1.0" 200 - "-" "Apache/2.4.6 (Red Hat Enterprise Linux) mod_wsgi/3.4 Python/2.7.5 (internal dummy connection)"
/etc/httpd/logs/horizon_access.log:198.18.53.27 - - [25/Feb/2016:04:08:20 +0000] "OPTIONS * HTTP/1.0" 200 - "-" "Apache/2.4.6 (Red Hat Enterprise Linux) mod_wsgi/3.4 Python/2.7.5 (internal dummy connection)"
/etc/httpd/logs/horizon_access.log:198.18.53.27 - - [25/Feb/2016:04:08:20 +0000] "OPTIONS * HTTP/1.0" 200 - "-" "Apache/2.4.6 (Red Hat Enterprise Linux) mod_wsgi/3.4 Python/2.7.5 (internal dummy connection)"
/etc/httpd/logs/horizon_access.log:198.18.53.27 - - [25/Feb/2016:04:08:20 +0000] "OPTIONS * HTTP/1.0" 200 - "-" "Apache/2.4.6 (Red Hat Enterprise Linux) mod_wsgi/3.4 Python/2.7.5 (internal dummy connection)"
/etc/httpd/logs/horizon_access.log:198.18.53.27 - - [25/Feb/2016:04:08:20 +0000] "OPTIONS * HTTP/1.0" 200 - "-" "Apache/2.4.6 (Red Hat Enterprise Linux) mod_wsgi/3.4 Python/2.7.5 (internal dummy connection)"
/etc/httpd/logs/horizon_access.log:198.18.53.27 - - [25/Feb/2016:04:08:20 +0000] "OPTIONS * HTTP/1.0" 200 - "-" "Apache/2.4.6 (Red Hat Enterprise Linux) mod_wsgi/3.4 Python/2.7.5 (internal dummy connection)"
/etc/httpd/logs/horizon_access.log:198.18.53.27 - - [25/Feb/2016:04:08:20 +0000] "OPTIONS * HTTP/1.0" 200 - "-" "Apache/2.4.6 (Red Hat Enterprise Linux) mod_wsgi/3.4 Python/2.7.5 (internal dummy connection)"
/etc/httpd/logs/horizon_access.log:198.18.53.27 - - [25/Feb/2016:04:08:20 +0000] "OPTIONS * HTTP/1.0" 200 - "-" "Apache/2.4.6 (Red Hat Enterprise Linux) mod_wsgi/3.4 Python/2.7.5 (internal dummy connection)"
/etc/sysconfig/memcached:OPTIONS="-l 198.18.53.27 -U 11211 -t 2 >> /var/log/memcached.log 2>&1"
/etc/sysconfig/network-scripts/route-br-ex:169.254.169.254/32 via 198.18.53.10 dev br-ex
/etc/sysconfig/network-scripts/ifcfg-br-ex:IPADDR=198.18.53.27
/etc/redis.conf:bind 198.18.53.27
/etc/neutron/neutron.conf:bind_host = 198.18.53.27
/etc/neutron/neutron.conf:nova_url = http://198.18.53.24:8774/v2/%(tenant_id)s
/etc/neutron/neutron.conf:auth_uri = http://198.18.53.24:5000/v2.0
/etc/neutron/neutron.conf:identity_uri = http://198.18.53.24:35357
/etc/neutron/neutron.conf:connection = mysql://neutron:xjrJnCHpdbYpfr2yGaRkHM7yh@198.18.53.24/ovs_neutron?charset=utf8
/etc/neutron/neutron.conf:auth_url=http://198.18.53.24:35357
/etc/neutron/neutron.conf:rabbit_hosts = 198.18.53.27
/etc/neutron/metadata_agent.ini:auth_url = http://198.18.53.24:35357
/etc/neutron/metadata_agent.ini:nova_metadata_ip = 198.18.53.27
/etc/neutron/api-paste.ini:identity_uri=http://198.18.53.24:35357
/etc/neutron/api-paste.ini:auth_uri=http://198.18.53.24:5000/v2.0
grep: /etc/extlinux.conf: No such file or directory
/etc/cloud/templates/hosts.redhat.tmpl:198.18.53.26 overcloud-compute-0.localdomain overcloud-compute-0
/etc/cloud/templates/hosts.redhat.tmpl:198.18.53.27 overcloud-controller-0.localdomain overcloud-controller-0
```

## Compute
```
[heat-admin@overcloud-compute-0 ~]$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN 
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: ens4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master ovs-system state UP qlen 1000
    link/ether 52:54:00:af:0c:c4 brd ff:ff:ff:ff:ff:ff
3: ovs-system: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN 
    link/ether 72:87:78:fb:b1:b9 brd ff:ff:ff:ff:ff:ff
4: br-ex: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether 52:54:00:af:0c:c4 brd ff:ff:ff:ff:ff:ff
    inet 198.18.53.26/24 brd 198.18.53.255 scope global br-ex
       valid_lft forever preferred_lft forever
    inet6 fe80::5054:ff:feaf:cc4/64 scope link 
       valid_lft forever preferred_lft forever
5: vlan30: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether f2:71:7a:91:a1:26 brd ff:ff:ff:ff:ff:ff
    inet 172.16.1.5/24 brd 172.16.1.255 scope global vlan30
       valid_lft forever preferred_lft forever
    inet6 fe80::f071:7aff:fe91:a126/64 scope link 
       valid_lft forever preferred_lft forever
6: vlan50: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether 4a:60:64:ff:5c:48 brd ff:ff:ff:ff:ff:ff
    inet 172.16.0.4/24 brd 172.16.0.255 scope global vlan50
       valid_lft forever preferred_lft forever
    inet6 fe80::4860:64ff:feff:5c48/64 scope link 
       valid_lft forever preferred_lft forever
7: br-int: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN 
    link/ether 02:6b:b4:1e:9c:43 brd ff:ff:ff:ff:ff:ff
8: br-tun: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN 
    link/ether 26:50:55:16:0b:49 brd ff:ff:ff:ff:ff:ff
```

```
[root@overcloud-compute-0 ~]# grep 198.18.53 /etc/* -R
/etc/ceilometer/ceilometer.conf:os_auth_url=http://198.18.53.24:5000/v2.0
/etc/ceilometer/ceilometer.conf:rabbit_hosts=198.18.53.27
/etc/cloud/templates/hosts.redhat.tmpl:198.18.53.26 overcloud-compute-0.localdomain overcloud-compute-0
/etc/cloud/templates/hosts.redhat.tmpl:198.18.53.27 overcloud-controller-0.localdomain overcloud-controller-0
grep: /etc/extlinux.conf: No such file or directory
/etc/hosts:198.18.53.26 overcloud-compute-0.localdomain overcloud-compute-0
/etc/hosts:198.18.53.27 overcloud-controller-0.localdomain overcloud-controller-0
/etc/neutron/neutron.conf:rabbit_hosts = 198.18.53.27
/etc/nova/nova.conf:my_ip=198.18.53.26
/etc/nova/nova.conf:vncserver_proxyclient_address=198.18.53.26
/etc/nova/nova.conf:url=http://198.18.53.24:9696
/etc/nova/nova.conf:admin_auth_url=http://198.18.53.24:35357/v2.0
/etc/nova/nova.conf:rabbit_hosts=198.18.53.27
/etc/os-collect-config.conf:metadata_url = http://198.18.53.10:8000/v1/
/etc/os-net-config/config.json:{"network_config": [{"dns_servers": ["8.8.8.8", "8.8.4.4"], "name": "br-ex", "members": [{"type": "interface", "name": "nic1", "primary": true}, {"type": "vlan", "addresses": [{"ip_netmask": "172.16.1.5/24"}], "vlan_id": 30}, {"type": "vlan", "addresses": [{"ip_netmask": "172.16.0.4/24"}], "vlan_id": 50}], "routes": [{"ip_netmask": "169.254.169.254/32", "next_hop": "198.18.53.10"}, {"default": true, "next_hop": "198.18.53.10"}], "use_dhcp": false, "type": "ovs_bridge", "addresses": [{"ip_netmask": "198.18.53.26/24"}]}]}
/etc/puppet/hieradata/compute.yaml:ceilometer::agent::auth::auth_url: http://198.18.53.24:5000/v2.0
/etc/puppet/hieradata/compute.yaml:keystone_public_api_virtual_ip: 198.18.53.24
/etc/puppet/hieradata/compute.yaml:neutron_host: 198.18.53.24
/etc/puppet/hieradata/compute.yaml:nova::compute::vncserver_proxyclient_address: 198.18.53.26
/etc/puppet/hieradata/compute.yaml:nova::network::neutron::neutron_admin_auth_url: http://198.18.53.24:35357/v2.0
/etc/puppet/hieradata/compute.yaml:nova::network::neutron::neutron_url: http://198.18.53.24:9696
/etc/puppet/hieradata/compute.yaml:nova_api_host: 198.18.53.24
/etc/puppet/hieradata/all_nodes.yaml:ceilometer::rabbit_hosts: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:ceilometer_api_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:cinder::rabbit_hosts: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:cinder_api_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:controller_node_ips: 198.18.53.27
/etc/puppet/hieradata/all_nodes.yaml:glance_registry_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:heat::rabbit_hosts: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:heat_api_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:horizon_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:keystone::rabbit_hosts: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:keystone_admin_api_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:keystone_public_api_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:memcache_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:memcache_node_ips_v6: ['inet6:[198.18.53.27]']
/etc/puppet/hieradata/all_nodes.yaml:mongo_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:mysql_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:neutron::rabbit_hosts: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:neutron_api_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:nova::rabbit_hosts: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:nova_api_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:nova_metadata_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:rabbit_node_ips: ['198.18.53.27']
/etc/puppet/hieradata/all_nodes.yaml:redis_node_ips: ['198.18.53.27']
/etc/sysconfig/network-scripts/route-br-ex:default via 198.18.53.10 dev br-ex
/etc/sysconfig/network-scripts/route-br-ex:169.254.169.254/32 via 198.18.53.10 dev br-ex
/etc/sysconfig/network-scripts/ifcfg-br-ex:IPADDR=198.18.53.26
```
