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

## Compute
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

Variant 4
## Command

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

## templates-basic-network-scenario/single-nic-vlans/compute.yaml
```
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
#                -
#                  default: true
#                  next_hop: {get_param: ControlPlaneDefaultRoute}
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

## Controller

## Compute
