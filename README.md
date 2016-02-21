# Guide to OpenStack TripleO and Heat

## Useful resources

### Heat resources
First of all, ideally cover your bases with the following documentation. If you want to understant TripleO deployment, it is crucial to have an understanding of Heat and HOT templates.
#### Heat orchestration (HOT) guide
http://docs.openstack.org/developer/heat/template_guide/hot_guide.html
#### Heat resource registry
http://docs.openstack.org/developer/heat/template_guide/environment.html
#### Heat Software deployment and software config resources:
http://docs.openstack.org/developer/heat/template_guide/software_deployment.html
https://github.com/openstack/heat-templates/tree/master/hot/software-config/elements/heat-config-script
http://hardysteven.blogspot.ca/2015/05/heat-softwareconfig-resources.html

### TripleO Heat resources 
Once you understand Heat, you can read on about TribleO
####TripleO Heat templates explained:
http://hardysteven.blogspot.ca/2015/05/tripleo-heat-templates-part-1-roles-and.html
http://hardysteven.blogspot.ca/2015/05/tripleo-heat-templates-part-2-node.html
http://hardysteven.blogspot.ca/2015/05/tripleo-heat-templates-part-3-cluster.html
#### TripleO Heat debugging explained:
http://hardysteven.blogspot.ca/2015/04/debugging-tripleo-heat-templates.html
#### TripleO Heat parameters vs default_parameters explained
http://lists.openstack.org/pipermail/openstack-dev/2015-November/079575.html


# Testing your templates
#### Getting started - fast:
Become the stack user:
su - stack
Create the following directories as the stack user:
mkdir templates-nfs
mkdir enfironment-nfs
Copy file templates-nfs/compute-extra-config-pre-deploy.yaml from this repository
Copy file templates-nfs/instances-nfs-mount.sh from this repository
Copy file environment-nfs/compute-pre-deploy.yaml from this repository
Copy any other enfironment file that you might need.
Run openstack overcloud deploy with your modified environment and extra parameters.
===
openstack overcloud deploy --templates -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml -e /home/stack/environment-nfs/network-environment.yaml  -e /home/stack/environment-nfs/compute-pre-deploy.yaml -e /home/stack/environment-nfs/storage-environment.yaml  --control-flavor control --compute-flavor compute --ntp-server pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 1 --compute-scale 1
===
How to verify
#### TripleO resource_registry hooks explained
Our goal is to mount NFS share on /var/lib/nova/instances. We obviously need to do this after the baremetal machines' operating systems are installed. However, we can either do this _before_ we customize the OS (i.e. install and configure OpenStack) or _after_. In terms of TripleO, this is pre-deployment or post-deployment, and TripleO provides convenient hoops for Controllers and Compute nodes which we can use. We can mount our NFS share before or after OpenStack installation and configuration, we don't really care. So we will use the hooks which are most convenient for us.

##### Discover available hooks
We are interested in the main resource registry of TripleO for Puppet:
/usr/share/openstack-tripleo-heat-templates/overcloud-resource-registry-puppet.yaml
This file contains some predefined hooks that we can use. This way, we do not need to modify any of the existing Heat scripts:

[stack@poc-undercloud ~]$ grep -A10 'Hooks for operator' /usr/share/openstack-tripleo-heat-templates/overcloud-resource-registry-puppet.yaml
  # Hooks for operator extra config
  # NodeUserData == Cloud-init additional user-data, e.g cloud-config
  # ControllerExtraConfigPre == Controller configuration pre service deployment
  # NodeExtraConfig == All nodes configuration pre service deployment
  # NodeExtraConfigPost == All nodes configuration post service deployment
  OS::TripleO::NodeUserData: firstboot/userdata_default.yaml
  OS::TripleO::ControllerExtraConfigPre: puppet/extraconfig/pre_deploy/default.yaml
  OS::TripleO::ComputeExtraConfigPre: puppet/extraconfig/pre_deploy/default.yaml
  OS::TripleO::NodeExtraConfig: puppet/extraconfig/pre_deploy/default.yaml
  OS::TripleO::NodeExtraConfigPost: extraconfig/post_deploy/default.yaml

So there already is a hook for compute nodes in the pre deployment stage. Also, there are some example scripts in puppet/extraconfig/pre_deploy/
Now, by default, OS::TripleO::ControllerExtraConfigPre is registered to default.yaml, a script which does absolutely nothing. 

##### Overwrite Compute pre-deployment hook
By default, OS::TripleO::ControllerExtraConfigPre is registered to default.yaml. This Heat resource does nothing and is simply a placeholder for our hooks. If we register a resource which actually does something to this hook, we can execute actions at the pre-deployment stage on all compute hosts. 

In comes our environment file to deploy our modifications!

[stack@poc-undercloud ~]$ cat environment-nfs/compute-pre-deploy.yaml 
# Overwrite original ComputeExtraConfigPre with custom resource to allow NFS mounts
resource_registry:
  OS::TripleO::ComputeExtraConfigPre: /home/stack/templates-nfs/compute-extra-config-pre-deploy.yaml
# parameter_defaults have global scope, so we can easily provide them to compute-extra-config-pre-deploy.yaml
parameter_defaults:
  nova_nfs_share: '198.18.53.10:/export/nova'
  nova_nfs_mount_options: 'rw,sync'

So, in the resource_registry section, we register OS::TripleO::ComputeExtraConfigPre to our compute-extra-config-pre-deploy.yaml resource. Also, we provide some "parameter_defaults". We are using parameter_defaults because these have global scope. "parameters" on the other side have only scope at the very top-level. They need to be passed down the entire stack. So, if we wanted to pass real parameters to our hook, we would need to modify all scripts along the inclusion tree from the very top overcloud-without-merge-py.yaml all the way down to our PreDeploy hook. This is inconvenient, and so TripleO uses this little parameter_defaults "hack" to make our life easier.

##### Analysis of compute-extra-config-pre-deploy.yaml
###### parameters section
parameters:
  server:
    type: string
  # Config specific parameters, to be provided via parameter_defaults
  nova_nfs_share:
    type: string
  nova_nfs_mount_options:
    type: string
    
###### resources section
resources:
  NodeSpecificConfig:
    type: OS::Heat::SoftwareConfig
    properties:
      group: script
      inputs:
      - name: _NOVA_NFS_SHARE
      - name: _NOVA_NFS_MOUNT_OPTIONS
      config: 
        get_file: instances-nfs-mount.sh
  NodeSpecificDeployment:
    type: OS::Heat::SoftwareDeployment
    properties:
      config: {get_resource: NodeSpecificConfig}
      actions: ['CREATE','UPDATE'] # Only do this on CREATE
      server: {get_param: server}
      input_values:
        _NOVA_NFS_SHARE: {get_param: nova_nfs_share}
        _NOVA_NFS_MOUNT_OPTIONS: {get_param: nova_nfs_mount_options}

###### outputs section
outputs:
  deploy_status_code:
    description: Returned status code from the configuration execution
    value: {get_attr: [NodeSpecificDeployment, deploy_status_code]}
  deploy_stderr:
    description: Captured stderr from the configuration execution
    value: {get_attr: [NodeSpecificDeployment, deploy_stderr]}
  deploy_stdout:
    description: Captured stdout from the configuration execution
    value: {get_attr: [NodeSpecificDeployment, deploy_stdout]}



#### Redeploying your modifications
Now, depending on your lab environment, it might take a very long time to boot an environment and get to the pre or post deployment stages. However, Heat is smart - simply run your "openstack overcloud deploy" command once again and Heat fill figure out the rest for you without reinstalling all nodes. It will simply try to update them!

openstack overcloud deploy --templates -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml -e /home/stack/environment-nfs/network-environment.yaml  -e /home/stack/environment-nfs/compute-pre-deploy.yaml -e /home/stack/environment-nfs/storage-environment.yaml  --control-flavor control --compute-flavor compute --ntp-server pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 1 --compute-scale 1

How to verify: run the same commands as above. Check the time stamp - once heat gets back to your resource, the time stamp should update and reflect the current time.

[stack@poc-undercloud ~]$ cat header.txt;heat resource-list overcloud -n5 | grep ComputeExt
+-------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+
| resource_name                             | physical_resource_id                          | resource_type                                     | resource_status    | updated_time         |
+-------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+
| ComputeExtraConfigPre                         | 4cb24dc9-e658-421c-a702-e50a53672a31          | OS::TripleO::ComputeExtraConfigPre                | UPDATE_COMPLETE    | 2016-02-21T18:32:10Z | 0                                             |
| NodeSpecificConfig                            | f9dee8bd-1be0-48e9-944d-439c4c1f999e          | OS::Heat::SoftwareConfig                          | CREATE_COMPLETE    | 2016-02-21T18:32:56Z | ComputeExtraConfigPre                         |
| NodeSpecificDeployment                        | bfbf1868-faeb-4d18-9a70-f5185f22f30d          | OS::Heat::SoftwareDeployment                      | UPDATE_COMPLETE    | 2016-02-21T18:33:02Z | ComputeExtraConfigPre
