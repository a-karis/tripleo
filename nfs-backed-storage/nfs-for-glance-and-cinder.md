# Using NFS storage for Glance images and for Cinder volumes
By default, TripleO only covers backing Glance and Cinder with NFS. 
In order to configura NFS backed Nova ephemeral storage, we will need to use pre-deployment hooks.
This document therefore only covers Glance and Cinder.

## Resources
The following resource contains generic instructions for the configuration of an environment file.

[1] https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux_OpenStack_Platform/7/html/Director_Installation_and_Usage/sect-Scenario_2_Using_the_CLI_to_Create_a_Basic_Overcloud.html#sect-Configuring_NFS_Storage

## Find useful default parameters (which we might overwrite in an environment file)
/usr/share/openstack-tripleo-heat-templates/overcloud-without-mergepy.yaml is the entry point into the TripleO Heat stack.

We can overwrite any parameter in the parameters section ofthis file in an environment file. For NFS, here is how we can find 
any useful parameters:

```
[stack@poc-undercloud ~]$ egrep -i 'nova|cinder|glance' /usr/share/openstack-tripleo-heat-templates/overcloud-without-mergepy.yaml | egrep '^  [A-Za-z].*:$' | egrep -i 'nfs|file'
  CinderEnableNfsBackend:
  CinderNfsMountOptions:
  CinderNfsServers:
  GlanceLogFile:
  GlanceFilePcmkDevice:
  GlanceFilePcmkFstype:
  GlanceFilePcmkManage:
  GlanceFilePcmkOptions:
```

## Heat environment file for Cinder and Glance backed by NFS
The following is a working configuration for a specific lab setup. Results of this lab setup can be found in the next section.
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
  CinderEnableNfsBackend: true
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
## openstack overcloud deploy
```
openstack overcloud deploy --templates -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml -e /home/stack/environment-nfs/network-environment.yaml  -e /home/stack/environment-nfs/compute-pre-deploy.yaml -e /home/stack/environment-nfs/storage-environment.yaml  --control-flavor control --compute-flavor compute --ntp-server pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 1 --compute-scale 1
```

## Resulting controller configuration
### Glance
Controller nodes will mount the NFS share on /var/lib/glance/images
```
[root@overcloud-controller-0 ~]# mount | grep glance
198.18.53.10:/export/glance on /var/lib/glance/images type nfs4 (rw,relatime,sync,context=system_u:object_r:glance_var_lib_t:s0,vers=4.0,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,port=0,timeo=600,retrans=2,sec=sys,clientaddr=198.18.53.34,local_lock=none,addr=198.18.53.10)
```
### Cinder
```
[root@overcloud-controller-0 ~]# mount | grep cinder
198.18.53.10:/export/cinder on /var/lib/cinder/mnt/88057c09b2069b5354c25aa2a529a3c6 type nfs4 (rw,relatime,sync,vers=4.1,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,port=0,timeo=600,retrans=2,sec=sys,clientaddr=198.18.53.30,local_lock=none,addr=198.18.53.10)
```
```
[stack@poc-undercloud ~]$ cinder service-list
+------------------+------------------------------------------------+------+---------+-------+----------------------------+-----------------+
|      Binary      |                      Host                      | Zone |  Status | State |         Updated_at         | Disabled Reason |
+------------------+------------------------------------------------+------+---------+-------+----------------------------+-----------------+
(...)
|  cinder-volume   | overcloud-controller-0.localdomain@tripleo_nfs | nova | enabled |   up  | 2016-02-22T06:12:25.000000 |        -        |
+------------------+------------------------------------------------+------+---------+-------+----------------------------+-----------------+

```
