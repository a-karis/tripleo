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
openstack overcloud deploy --templates -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml -e /home/stack/environment-netapp/network-environment.yaml -e /home/stack/environment-netapp/cinder-netapp-config.yaml  --control-flavor control --compute-flavor compute --ntp-server pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 1 --compute-scale 1
```
Wait for the completion of the overcloud deployment process.

### Resulting cinder.conf
(...)

## Configuration of NetApp cinder backend (standalone)
### Instructions
Repeat the above instructions for the NetApp backend driver
Repeat all instructions for nova, glance and cinder storage
Run openstack overcloud deploy:
```
openstack overcloud deploy --templates -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml -e /home/stack/environment-netapp/network-environment.yaml  -e /home/stack/environment-netapp/compute-pre-deploy.yaml -e /home/stack/environment-netapp/storage-environment.yaml -e /home/stack/environment-netapp/cinder-netapp-config.yaml  --control-flavor control --compute-flavor compute --ntp-server pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 1 --compute-scale 1
```
