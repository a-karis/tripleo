#!/bin/bash
######################################################################
#
# This script (re)mounts an NFS share to /var/lib/nova/instances
#
######################################################################

nova_instance_directory="/var/lib/nova/instances"

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
