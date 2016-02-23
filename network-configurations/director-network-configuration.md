# Custom templates

## /environment-netapp/network-environment.yaml

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

# 1) Variation 1
## Command
```
openstack overcloud deploy --templates -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml  -e /home/stack/environment-netapp/network-environment.yaml   --control-flavor control --compute-flavor compute --ntp-server pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 1 --compute-scale 1
Deploying templates in the directory /usr/share/openstack-tripleo-heat-templates
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

# 2) Variation 2
## Command 
```
openstack overcloud deploy --templates --control-flavor control --compute-flavor compute --ntp-server pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 1 --compute-scale 1
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
