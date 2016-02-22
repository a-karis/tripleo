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
```
openstack overcloud deploy --templates -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml -e /home/stack/environment-netapp/network-environment.yaml -e /home/stack/environment-netapp/cinder-netapp-config.yaml  --control-flavor control --compute-flavor compute --ntp-server pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 1 --compute-scale 1
```
Wait for the completion of the overcloud deployment process.

### Resulting cinder.conf
(...)

## Configuration of NetApp cinder backend (alongside Cinder NFS configuration)
### Instructions
Repeat the above instructions for the NetApp backend driver
Repeat all instructions for nova, glance and cinder storage
Run openstack overcloud deploy:
```
openstack overcloud deploy --templates -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml -e /home/stack/environment-netapp/network-environment.yaml  -e /home/stack/environment-netapp/compute-pre-deploy.yaml -e /home/stack/environment-netapp/storage-environment.yaml -e /home/stack/environment-netapp/cinder-netapp-config.yaml  --control-flavor control --compute-flavor compute --ntp-server pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 1 --compute-scale 1
```

## How it works
### environments/cinder-netapp-config.yaml
This file registers /usr/share/openstack-tripleo-heat-templates/puppet/extraconfig/pre_deploy/controller/cinder-netapp.yaml tp OS::TripleO::ControllerExtraConfigPre - this means that is makes use of the Controller pre-deployment hook. It then condifures several parameter_defaults with global scope so that the ControllerExtraConfigPre resource can use them. 
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

