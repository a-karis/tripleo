# Configuring TripleO Cinder with the NetApp backend driver

## Resources
[1] http://docs.openstack.org/developer/tripleo-docs/advanced_deployment/cinder_netapp.html

[2] outdated, for OSP6: http://netapp.github.io/openstack-deploy-ops-guide/kilo/content/cinder.configuration.html#d6e1206

## Configuration of NetApp cinder backend (standalone)
### Instructions
Configuration is explained in [1]:

Copy the NetApp configuration file to your home directory:
```
sudo cp /usr/share/openstack-tripleo-heat-templates/environments/cinder-netapp-config.yaml ~
```
Edit the permissions (user is typically stack):
```
sudo chown $USER ~/cinder-netapp-config.yaml
sudo chmod 755 ~/cinder-netapp-config.yaml
```
Edit the parameters in this file to fit your requirements. Ensure that the following line is changed:
```
OS::TripleO::ControllerExtraConfigPre: /usr/share/openstack-tripleo-heat-templates/puppet/extraconfig/pre_deploy/controller/cinder-netapp.yaml
```
Continue following the TripleO instructions for deploying an overcloud. Before entering the command to deploy the overcloud, add the environment file that you just configured as an argument:
```
openstack overcloud deploy --templates -e ~/cinder-netapp-config.yaml
```
### Full deploy command
```
openstack overcloud deploy --templates -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml -e /home/stack/environment-netapp/network-environment.yaml -e /home/stack/environment-netapp/cinder-netapp-config.yaml  --control-flavor control --compute-flavor compute --ntp-server pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 1 --compute-scale 1
```
Wait for the completion of the overcloud deployment process.

### Resulting state of Cinder
If we use only cinder-netapp-config.yaml as an environment file for TripleO, Cinder will end up with 2 enabled backends: iscsi and netapp.

### Resulting cinder.conf
```
enabled_backends=tripleo_iscsi,tripleo_netapp
(...)
[tripleo_netapp]
netapp_login=
netapp_vfiler=
netapp_password=
nfs_shares_config=/etc/cinder/shares.conf
netapp_storage_pools=
host=hostgroup
netapp_sa_password=
netapp_server_hostname=
netapp_size_multiplier=1.2
thres_avl_size_perc_stop=60
netapp_storage_protocol=nfs
netapp_webservice_path=/devmgr/v2
volume_driver=cinder.volume.drivers.netapp.common.NetAppDriver
netapp_controller_ips=
netapp_volume_list=
netapp_storage_family=ontap_cluster
expiry_thres_minutes=720
netapp_server_port=80
netapp_partner_backend_name=
netapp_eseries_host_type=linux_dm_mp
thres_avl_size_perc_start=20
volume_backend_name=tripleo_netapp
netapp_copyoffload_tool_path=
netapp_transport_type=http
netapp_vserver=

[tripleo_iscsi]
volume_driver=cinder.volume.drivers.lvm.LVMVolumeDriver
volumes_dir=/var/lib/cinder/volumes
iscsi_protocol=iscsi
iscsi_ip_address=172.16.1.6
volume_backend_name=tripleo_iscsi
volume_group=cinder-volumes
iscsi_helper=lioadm
```
### cinder service-list
```
[stack@poc-undercloud ~]$ cinder service-list
+------------------+--------------------------------------------------+------+---------+-------+----------------------------+-----------------+
|      Binary      |                       Host                       | Zone |  Status | State |         Updated_at         | Disabled Reason |
+------------------+--------------------------------------------------+------+---------+-------+----------------------------+-----------------+
| cinder-scheduler |        overcloud-controller-0.localdomain        | nova | enabled |   up  | 2016-02-22T03:36:38.000000 |        -        |
|  cinder-volume   |             hostgroup@tripleo_netapp             | nova | enabled |   up  | 2016-02-22T03:36:44.000000 |        -        |
|  cinder-volume   | overcloud-controller-0.localdomain@tripleo_iscsi | nova | enabled |   up  | 2016-02-22T03:36:43.000000 |        -        |
+------------------+--------------------------------------------------+------+---------+-------+----------------------------+-----------------+

```

## Configuration of NetApp cinder backend (with additional Cinder NFS backend, with Nova NFS backend, with Glance NFS backend)
### Instructions
- Repeat the above instructions for the NetApp backend driver.
- Repeat all instructions for nova, glance and cinder storage.
- Run openstack overcloud deploy with all environment files:
```
openstack overcloud deploy --templates -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml -e /home/stack/environment-netapp/network-environment.yaml  -e /home/stack/environment-netapp/compute-pre-deploy.yaml -e /home/stack/environment-netapp/storage-environment.yaml -e /home/stack/environment-netapp/cinder-netapp-config.yaml  --control-flavor control --compute-flavor compute --ntp-server pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 1 --compute-scale 1
```

### Resulting cinder.conf
```
(...)
enabled_backends=tripleo_netapp,tripleo_nfs
(...)
[tripleo_netapp]
netapp_login=
netapp_vfiler=
netapp_password=
nfs_shares_config=/etc/cinder/shares.conf
netapp_storage_pools=
host=hostgroup
netapp_sa_password=
netapp_server_hostname=
netapp_size_multiplier=1.2
thres_avl_size_perc_stop=60
netapp_storage_protocol=nfs
netapp_webservice_path=/devmgr/v2
volume_driver=cinder.volume.drivers.netapp.common.NetAppDriver
netapp_controller_ips=
netapp_volume_list=
netapp_storage_family=ontap_cluster
expiry_thres_minutes=720
netapp_server_port=80
netapp_partner_backend_name=
netapp_eseries_host_type=linux_dm_mp
thres_avl_size_perc_start=20
volume_backend_name=tripleo_netapp
netapp_copyoffload_tool_path=
netapp_transport_type=http
netapp_vserver=

[tripleo_nfs]
nfs_oversub_ratio=1.0
volume_driver=cinder.volume.drivers.nfs.NfsDriver
nfs_used_ratio=0.95
nfs_shares_config=/etc/cinder/shares-nfs.conf
nfs_mount_options=rw,sync
volume_backend_name=tripleo_nfs
```
### /etc/cinder/shares-nfs.conf
```
198.18.53.10:/export/cinder
```
### cinder service-list
```
[stack@poc-undercloud ~]$ cinder service-list
+------------------+------------------------------------------------+------+---------+-------+----------------------------+-----------------+
|      Binary      |                      Host                      | Zone |  Status | State |         Updated_at         | Disabled Reason |
+------------------+------------------------------------------------+------+---------+-------+----------------------------+-----------------+
| cinder-scheduler |       overcloud-controller-0.localdomain       | nova | enabled |   up  | 2016-02-22T06:12:25.000000 |        -        |
|  cinder-volume   |            hostgroup@tripleo_netapp            | nova | enabled |   up  | 2016-02-22T06:12:25.000000 |        -        |
|  cinder-volume   | overcloud-controller-0.localdomain@tripleo_nfs | nova | enabled |   up  | 2016-02-22T06:12:25.000000 |        -        |
+------------------+------------------------------------------------+------+---------+-------+----------------------------+-----------------+
```

## Configuration of NetApp cinder backend (without additional Cinder NFS backend, with Nova NFS backend, with Glance NFS backend)
### Instructions
- Repeat the above instructions for the NetApp backend driver.
- Repeat all instructions for nova, glance and cinder storage.
- Modify storage-environment.yaml
```
## A Heat environment file which can be used to set up storage
## backends. Defaults to Ceph used as a backend for Cinder, Glance and
## Nova ephemeral storage.
parameters:
  #### BACKEND SELECTION ####
  ## Whether to enable iscsi backend for Cinder.
  CinderEnableIscsiBackend: false
  ## Whether to enable rbd (Ceph) backend for Cinder.
  CinderEnableRbdBackend: false
  ## Whether to enable NFS backend for Cinder.
  CinderEnableNfsBackend: false
  ## Whether to enable rbd (Ceph) backend for Nova ephemeral storage.
  NovaEnableRbdBackend: false
  ## Glance backend can be either 'rbd' (Ceph), 'swift' or 'file'.
  GlanceBackend: file

  #### CINDER NFS SETTINGS ####
  ## NFS mount options
  CinderNfsMountOptions: 'rw,sync'
  ## NFS mount point, e.g. '192.168.122.1:/export/cinder'
  CinderNfsServers: '198.18.53.10:/export/cinder'

  #### GLANCE FILE BACKEND PACEMAKER SETTINGS (used for mounting NFS) ####
  ## Whether to make Glance 'file' backend a mount managed by Pacemaker
  GlanceFilePcmkManage: true
  ## File system type of the mount
  GlanceFilePcmkFstype: nfs
  ## Pacemaker mount point, e.g. '192.168.122.1:/export/glance' for NFS
  GlanceFilePcmkDevice: '198.18.53.10:/export/glance'
  ## Options for the mount managed by Pacemaker
  GlanceFilePcmkOptions: 'rw,sync,context=system_u:object_r:glance_var_lib_t:s0'

```
- Run openstack overcloud deploy with all environment files:
```
openstack overcloud deploy --templates -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml -e /home/stack/environment-netapp/network-environment.yaml  -e /home/stack/environment-netapp/compute-pre-deploy.yaml -e /home/stack/environment-netapp/storage-environment.yaml -e /home/stack/environment-netapp/cinder-netapp-config.yaml  --control-flavor control --compute-flavor compute --ntp-server pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 1 --compute-scale 1
```

### Resulting cinder.conf
```
(...) results should be as above without NFS backend configuration (...)
```
### cinder service-list
```
(...) results should be as above without NFS backend (...)
```

## How it works
### environments/cinder-netapp-config.yaml
This file registers /usr/share/openstack-tripleo-heat-templates/puppet/extraconfig/pre_deploy/controller/cinder-netapp.yaml to OS::TripleO::ControllerExtraConfigPre - this means that is makes use of the Controller pre-deployment hook. It then condifures several parameter_defaults with global scope so that the ControllerExtraConfigPre resource can use them. 
```
# A Heat environment file which can be used to enable a
# a Cinder NetApp backend, configured via puppet
resource_registry:
  OS::TripleO::ControllerExtraConfigPre: ../puppet/extraconfig/pre_deploy/controller/cinder-netapp.yaml

parameter_defaults:
  CinderEnableNetappBackend: true
  CinderNetappBackendName: 'tripleo_netapp'
  CinderNetappLogin: ''
  CinderNetappPassword: ''
(...)
```

### .../controller/cinder-netapp.yaml
Once registered as the OS::TripleO::ControllerExtraConfigPre, the Controller will invoke /usr/share/openstack-tripleo-heat-templates/puppet/extraconfig/pre_deploy/controller/cinder-netapp.yaml in the pre-deployment phase.

This resource will then configure a new Cinder backend with the NetApp volume driver. Important extract of resource definition below:
```
resources:
  CinderNetappConfig:
    type: OS::Heat::StructuredConfig
    properties:
      group: os-apply-config
      config:
        hiera:
          datafiles:
            cinder_netapp_data:
              mapped_data:
                cinder_enable_netapp_backend: {get_input: EnableNetappBackend}
                cinder::backend::netapp::title: {get_input: NetappBackendName}
                cinder::backend::netapp::netapp_login: {get_input: NetappLogin}
                cinder::backend::netapp::netapp_password: {get_input: NetappPassword}
                cinder::backend::netapp::netapp_server_hostname: {get_input: NetappServerHostname}
                cinder::backend::netapp::netapp_server_port: {get_input: NetappServerPort}
                cinder::backend::netapp::netapp_size_multiplier: {get_input: NetappSizeMultiplier}
                cinder::backend::netapp::netapp_storage_family: {get_input: NetappStorageFamily}
                cinder::backend::netapp::netapp_storage_protocol: {get_input: NetappStorageProtocol}
                cinder::backend::netapp::netapp_transport_type: {get_input: NetappTransportType}
                cinder::backend::netapp::netapp_vfiler: {get_input: NetappVfiler}
                cinder::backend::netapp::netapp_volume_list: {get_input: NetappVolumeList}
                cinder::backend::netapp::netapp_vserver: {get_input: NetappVserver}
                cinder::backend::netapp::netapp_partner_backend_name: {get_input: NetappPartnerBackendName}
                cinder::backend::netapp::nfs_shares: {get_input: NetappNfsShares}
                cinder::backend::netapp::nfs_shares_config: {get_input: NetappNfsSharesConfig}
                cinder::backend::netapp::nfs_mount_options: {get_input: NetappNfsMountOptions}
                cinder::backend::netapp::netapp_copyoffload_tool_path: {get_input: NetappCopyOffloadToolPath}
                cinder::backend::netapp::netapp_controller_ips: {get_input: NetappControllerIps}
                cinder::backend::netapp::netapp_sa_password: {get_input: NetappSaPassword}
                cinder::backend::netapp::netapp_storage_pools: {get_input: NetappStoragePools}
                cinder::backend::netapp::netapp_eseries_host_type: {get_input: NetappEseriesHostType}
                cinder::backend::netapp::netapp_webservice_path: {get_input: NetappWebservicePath}
```

### Comparing .../controller/cinder-netapp.yaml, environments/cinder-netapp-config.yaml and cinder.conf output side by side
It might help to compare the above configuration of cinder-netapp.yaml with our parameter_defaults and the resulting cinder.conf

environments/cinder-netapp-config.yaml :
```
parameter_defaults:
  CinderEnableNetappBackend: true
  CinderNetappBackendName: 'tripleo_netapp'
  CinderNetappLogin: ''
  CinderNetappPassword: ''
  CinderNetappServerHostname: ''
  CinderNetappServerPort: '80'
  CinderNetappSizeMultiplier: '1.2'
  CinderNetappStorageFamily: 'ontap_cluster'
  CinderNetappStorageProtocol: 'nfs'
  CinderNetappTransportType: 'http'
  CinderNetappVfiler: ''
  CinderNetappVolumeList: ''
  CinderNetappVserver: ''
  CinderNetappPartnerBackendName: ''
  CinderNetappNfsShares: ''
  CinderNetappNfsSharesConfig: '/etc/cinder/shares.conf'
  CinderNetappNfsMountOptions: ''
  CinderNetappCopyOffloadToolPath: ''
  CinderNetappControllerIps: ''
  CinderNetappSaPassword: ''
  CinderNetappStoragePools: ''
  CinderNetappEseriesHostType: 'linux_dm_mp'
  CinderNetappWebservicePath: '/devmgr/v2'
```
cinder.conf:
```
[tripleo_netapp]
netapp_login=
netapp_vfiler=
netapp_password=
nfs_shares_config=/etc/cinder/shares.conf
netapp_storage_pools=
host=hostgroup
netapp_sa_password=
netapp_server_hostname=
netapp_size_multiplier=1.2
thres_avl_size_perc_stop=60
netapp_storage_protocol=nfs
netapp_webservice_path=/devmgr/v2
volume_driver=cinder.volume.drivers.netapp.common.NetAppDriver
netapp_controller_ips=
netapp_volume_list=
netapp_storage_family=ontap_cluster
expiry_thres_minutes=720
netapp_server_port=80
netapp_partner_backend_name=
netapp_eseries_host_type=linux_dm_mp
thres_avl_size_perc_start=20
volume_backend_name=tripleo_netapp
netapp_copyoffload_tool_path=
netapp_transport_type=http
netapp_vserver=
```

