# Guide to OpenStack TripleO and Heat

## Useful resources

### Heat resources
First of all, ideally cover all the bases by going through the following documentation. If you want to understand TripleO deployment, it is crucial to have an understanding of Heat and HOT templates.
#### Heat orchestration (HOT) guide
[1] http://docs.openstack.org/developer/heat/template_guide/hot_guide.html
#### Heat resource registry
[2] http://docs.openstack.org/developer/heat/template_guide/environment.html
#### Heat Software deployment and software config resources:
[3] http://docs.openstack.org/developer/heat/template_guide/software_deployment.html

[4] http://hardysteven.blogspot.ca/2015/05/heat-softwareconfig-resources.html

[5] https://github.com/openstack/heat-templates/tree/master/hot/software-config/elements

### TripleO Heat resources 
Once you understand Heat, you can read on about TribleO
####TripleO Heat templates explained:
[6] http://hardysteven.blogspot.ca/2015/05/tripleo-heat-templates-part-1-roles-and.html

[7] http://hardysteven.blogspot.ca/2015/05/tripleo-heat-templates-part-2-node.html

[8] http://hardysteven.blogspot.ca/2015/05/tripleo-heat-templates-part-3-cluster.html

#### TripleO Heat debugging explained:
[9] http://hardysteven.blogspot.ca/2015/04/debugging-tripleo-heat-templates.html
#### TripleO Heat parameters vs default_parameters explained
[10] http://lists.openstack.org/pipermail/openstack-dev/2015-November/079575.html


## Quick start with this repository (to mount instance ephemeral disks onto NFS)
Become the stack user:
```
su - stack
```

Create the following directories as the stack user:
```
mkdir templates-nfs
mkdir enfironment-nfs
```
Copy file templates-nfs/compute-extra-config-pre-deploy.yaml from this repository
Copy file templates-nfs/instances-nfs-mount.sh from this repository
Copy file environment-nfs/compute-pre-deploy.yaml from this repository
```
cp git-repo/templates-nfs/compute-extra-config-pre-deploy.yaml  ~/templates-nfs/compute-extra-config-pre-deploy.yaml 
cp git-repo/templates-nfs/instances-nfs-mount.sh ~/templates-nfs/instances-nfs-mount.sh
cp git-repo/environment-nfs/compute-pre-deploy.yaml ~/environment-nfs/compute-pre-deploy.yaml
```

Copy any other environment file that you might need.

Run openstack overcloud deploy with your modified environment and extra parameters.
```
openstack overcloud deploy --templates -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml -e /home/stack/environment-nfs/network-environment.yaml  -e /home/stack/environment-nfs/compute-pre-deploy.yaml -e /home/stack/environment-nfs/storage-environment.yaml  --control-flavor control --compute-flavor compute --ntp-server pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 1 --compute-scale 1
```

## Modifying TripleO Heat templates to mount instance ephemeral disks onto NFS
Our goal is to mount an NFS share on /var/lib/nova/instances of each compute node. We obviously need to do this after the baremetal machines' operating systems are installed. However, we can either do this _before_ we customize the OS (i.e. install and configure OpenStack) or _after_. Also, we need to tell Heat what to do. This is done by registering resources to the Heat stack. We can mount our NFS share before or after OpenStack installation and configuration, we don't really care. So we will use whatever we find is most convenient for us.

### TripleO resource_registry hooks explained
In terms of TripleO, anything that happens after OS installation but before Openstack configuration is called pre-deployment. Anything that happens after Openstack was configured is called post-deployment. TripleO provides convenient hooks for Controllers and Compute nodes which we can use: by default, TripleO executes several Heat resources which do nothing. Their sole purpose is for us to replace them with something useful. These hooks are in the form of "blank" default templates which TripleO includes. In order to override these hooks, we simply need to override the resource_registry for the given resource. We can then point the resource to a useful template. We do this in an environment file.

#### Discover available hooks
First, we need to discover available hooks which we might use. In order to discover these hooks, we are interested in the main resource registry of TripleO for Puppet:
```
/usr/share/openstack-tripleo-heat-templates/overcloud-resource-registry-puppet.yaml
```
This file contains some predefined hooks that we can use. This way, we do not need to modify any of the existing Heat scripts:

```
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
```

So there already is a hook for compute nodes in the pre deployment stage. Also, there are some example scripts in puppet/extraconfig/pre_deploy/
Now, by default, OS::TripleO::ControllerExtraConfigPre is registered to default.yaml, a script which does absolutely nothing. 
But when does TripleO use this resource? 
```
[stack@poc-undercloud openstack-tripleo-heat-templates]$ grep OS::TripleO::ComputeExtraConfigPre /usr/share/openstack-tripleo-heat-templates -R
/usr/share/openstack-tripleo-heat-templates/environments/cisco-n1kv-config.yaml:  OS::TripleO::ComputeExtraConfigPre: ../puppet/extraconfig/pre_deploy/controller/cisco-n1kv.yaml
/usr/share/openstack-tripleo-heat-templates/overcloud-resource-registry-puppet.yaml:  OS::TripleO::ComputeExtraConfigPre: puppet/extraconfig/pre_deploy/default.yaml
/usr/share/openstack-tripleo-heat-templates/puppet/compute-puppet.yaml:    type: OS::TripleO::ComputeExtraConfigPre
```
So TripleO uses this resourc in the compute-puppet.yaml file. This file actually tells puppet how to deploy/configure our Compute nodes ...
```
[stack@poc-undercloud openstack-tripleo-heat-templates]$ grep compute-puppet.yaml /usr/share/openstack-tripleo-heat-templates/overcloud-resource-registry-puppet.yaml 
  OS::TripleO::Compute: puppet/compute-puppet.yaml
```
... and the only mandatory parameter is the "server" property.
```
  # Hook for site-specific additional pre-deployment config, e.g extra hieradata
  ComputeExtraConfigPre:
    depends_on: NovaComputeDeployment
    type: OS::TripleO::ComputeExtraConfigPre
    properties:
        server: {get_resource: NovaCompute}
```

#### Overwrite Compute pre-deployment hook
By default, OS::TripleO::ControllerExtraConfigPre is registered to default.yaml. This Heat resource does nothing and is simply a placeholder for our hooks. If we register a resource which actually does something to this hook, we can execute actions at the pre-deployment stage on all compute hosts. 

In comes our environment file to deploy our modifications!

```
[stack@poc-undercloud ~]$ cat environment-nfs/compute-pre-deploy.yaml 
# Overwrite original ComputeExtraConfigPre with custom resource to allow NFS mounts
resource_registry:
  OS::TripleO::ComputeExtraConfigPre: /home/stack/templates-nfs/compute-extra-config-pre-deploy.yaml
# parameter_defaults have global scope, so we can easily provide them to compute-extra-config-pre-deploy.yaml
parameter_defaults:
  nova_nfs_share: '198.18.53.10:/export/nova'
  nova_nfs_mount_options: 'rw,sync'
```

So, in the resource_registry section, we register OS::TripleO::ComputeExtraConfigPre to our compute-extra-config-pre-deploy.yaml resource. Also, we provide some "parameter_defaults". We are using parameter_defaults because these have global scope. "parameters" on the other side have only scope at the very top-level. They need to be passed down the entire stack. So, if we wanted to pass real parameters to our hook, we would need to modify all scripts along the inclusion tree from the very top overcloud-without-merge-py.yaml all the way down to our PreDeploy hook. This is inconvenient, and so TripleO uses this little parameter_defaults "hack" to make our life easier.

#### Analysis of compute-extra-config-pre-deploy.yaml
So far, we told TripleO that it should execute our new OS::TripleO::ComputeExtraConfigPre resource. However, we need to fill this file with something useful.

The only mandatory interface for this file is the following:
- input: server
- output: deploy_status_code

We can "make up" anything else. Any new parameters should however be covered by the default_parameters in our environment file (see above).

The following lists the contents of compute-extra-config-pre-deploy.yaml:

##### parameters section
Define mandatory server name. Specify new parameters for our nfs share.
```
parameters:
  server:
    type: string
  # Config specific parameters, to be provided via parameter_defaults
  nova_nfs_share:
    type: string
  nova_nfs_mount_options:
    type: string
```
    
##### resources section
OS::Heat::SoftwareConfig instructs heat what to do. It includes a bash script "instances-nfs-mount.sh" and provides 2 arguments to this script's envirionment: _NOVA_NFS_SHARE and _NOVA_NFS_MOUNT_OPTIONS
OS::Heat::SoftwareDeployment exectutes the SoftwareConfiguration on a specific server. actions tell Heat when to deploy (in this case, on stack CREATE and stack UPDATE). It also pulls input values from our environment file (our default_parameters) and passes them to OS::Heat::SoftwareConfig which then passes them on the our script.

The group: parameter defines the type of our config: parameter. This can be script, puppet, or any other software configuration hook as listed in [5] (see link [5] above). For simplicity, we are using a bash script here.
```
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
```

##### outputs section
Here, we can add some verbosity for debugging purposes. The only output which Heat absolutely needs is deploy_status_code. If the status code returns an error, overcloud deployment will wail at this stage.
```
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
```

##### instances-nfs-mount.sh bash script
This is a very basic script which persistently mounts an NFS share to /var/lib/nova/instances. If the same share is mounted by all Compute hosts, this will allow live migration and other advanced features.
```
#!/bin/bash
######################################################################
#
# This script (re)mounts an NFS share to /var/lib/nova/instances
#
######################################################################

nova_instance_directory="/var/lib/nova/instances"

echo "INPUT parameters to this script are: $_NOVA_NFS_SHARE $_NOVA_NFS_MOUNT_OPTIONS" > /tmp/test.txt

delete_existing_nova_mount_fstab() {
  /bin/sed -i "\#${nova_instance_directory}#d" /etc/fstab
}

create_nova_mount_fstab() {
  /bin/echo "$_NOVA_NFS_SHARE $nova_instance_directory nfs $_NOVA_NFS_MOUNT_OPTIONS 0 0" >> /etc/fstab
}

# we are in predeployment, so this directory might not yet exist
if [ ! -d $nova_instance_directory ];then
  /bin/mkdir -p $nova_instance_directory
fi
# delete any existing mounts from fstab (e.g., in case of a stack update)
delete_existing_nova_mount_fstab
# create a new mount lin in fstab
create_nova_mount_fstab
# (re)mount /var/lib/nova/instances
if `/bin/mount | /bin/grep -q "$nova_instance_directory"`;then
  /bin/mount $nova_instance_directory -o remount
else
  /bin/mount $nova_instance_directory
fi
```

#### Redeploying your modifications
Now, depending on your lab environment, it might take a very long time to boot an environment and get to the pre or post deployment stages. However, Heat is smart - simply run your "openstack overcloud deploy" command once again and Heat will figure out the rest for you without reinstalling all nodes. It will simply try to update them (i.e. it will go through the pre- and post-deployment phases again).

```
openstack overcloud deploy --templates -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml -e /home/stack/environment-nfs/network-environment.yaml  -e /home/stack/environment-nfs/compute-pre-deploy.yaml -e /home/stack/environment-nfs/storage-environment.yaml  --control-flavor control --compute-flavor compute --ntp-server pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 1 --compute-scale 1
```

How to verify: run the same commands as above. Check the time stamp - once heat gets back to your resource, the time stamp should update and reflect the current time.

```
[stack@poc-undercloud ~]$ cat header.txt;heat resource-list overcloud -n5 | grep ComputeExt
+-------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+
| resource_name                             | physical_resource_id                          | resource_type                                     | resource_status    | updated_time         |
+-------------------------------------------+-----------------------------------------------+---------------------------------------------------+--------------------+----------------------+
| ComputeExtraConfigPre                         | 4cb24dc9-e658-421c-a702-e50a53672a31          | OS::TripleO::ComputeExtraConfigPre                | UPDATE_COMPLETE    | 2016-02-21T18:32:10Z | 0                                             |
| NodeSpecificConfig                            | f9dee8bd-1be0-48e9-944d-439c4c1f999e          | OS::Heat::SoftwareConfig                          | CREATE_COMPLETE    | 2016-02-21T18:32:56Z | ComputeExtraConfigPre                         |
| NodeSpecificDeployment                        | bfbf1868-faeb-4d18-9a70-f5185f22f30d          | OS::Heat::SoftwareDeployment                      | UPDATE_COMPLETE    | 2016-02-21T18:33:02Z | ComputeExtraConfigPre
```
