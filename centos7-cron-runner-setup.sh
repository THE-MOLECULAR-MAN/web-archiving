#!/bin/bash
# Tim H 2022
#
# This script is designed to set up a new CentOS 7 virtual machine for
#   archiving online resources such as YouTube videos, websites, podcasts
#   and other resources.
# There are separate scripts for setting up each separate media type like
#   podcasts, etc. This script is only the prep for that and includes creating
#   a new user, setting up an NFS mount point, and installing some 
#   dependencies. 
#
# This script is designed to be copy and pasted, not executed directly at
#   this time.
#
# NFS_MOUNT_NAME assumes it is a Synology based mount, so yours may differ

# new username that will be created
NEW_LOCAL_USERNAME="cron-user"

# create the new local user account
sudo useradd "$NEW_LOCAL_USERNAME"

# temporarily add as a sudoer during install, then remove it at the end
echo "$NEW_LOCAL_USERNAME ALL=(ALL) NOPASSWD:ALL" | sudo tee --append /etc/sudoers

##############################################################################
# SWITCH TO THE NEW USER FROM NOW ON, DON'T USE ROOT USER ANYMORE
# USING ROOT USER JUST CAUSES A TON OF PERMISSIONS PROBLEMS
##############################################################################

# be sure to copy and paste this, don't run this script directly
sudo su - "$NEW_LOCAL_USERNAME"

NFS_MOUNT_NAME="nfs_archive_mirror_downloads"
NFS_SERVER_IP="10.0.1.35"
NFS_MOUNT_PATH="/home/$NEW_LOCAL_USERNAME/$NFS_MOUNT_NAME"

# install EPEL since some dependences come from there.
sudo yum install epel-release
sudo yum localinstall --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm

# must pull down the index of EPEL before you can install anything from it - required.
sudo yum update

# create the directory mount point, should be empty
mkdir "$NFS_MOUNT_PATH"
cd "$NFS_MOUNT_PATH" || exit 1

# required, set directory as readable with +x; might have to re-do after mount?
sudo chmod +x "$NFS_MOUNT_PATH"

# auto mount this point on reboot
# do not inlcude "noexec" here since some code will be executing from there
# Your mount point may be different (not include volume1) if you're not using Synology
echo "$NFS_SERVER_IP:/volume1/$NFS_MOUNT_NAME $NFS_MOUNT_PATH      nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0" | sudo tee --append /etc/fstab

# mount it now
sudo mount "$NFS_MOUNT_PATH"

# set permissions so new user can write to it
sudo chown -R "$NEW_LOCAL_USERNAME" "$NFS_MOUNT_PATH"

# must mark new directory as executable so it can be listed
sudo chmod 700 "$NFS_MOUNT_PATH"

# test writing to that directory
date > "$NFS_MOUNT_PATH/network_mounted.txt"

# set up easy remote access for new user
# create SSH directory with proper permissions, drop an SSH key
# replace my SSH key with yours.
mkdir ~/.ssh
chmod 755 ~/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJNZ5jq+7jE/Fy13gBqcipqtNjTLhkFEDoEq7/SzICyH $NEW_LOCAL_USERNAME" >> ~/.ssh/authorized_keys
chmod 644 ~/.ssh/authorized_keys
