#!/bin/bash

SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )

function cdroot()
{
  while [[ $PWD != '/' && ${PWD##*/} != 'ceph-ansible' ]]; do
      cd ..;
  done
}

cd "$SCRIPTPATH"

# create a hosts file for this run
cat <<EOF > $SCRIPTPATH/hosts

[mons]
mon0

EOF

# run vagrant for this environment
vagrant up --no-provision --provider=virtualbox

# generate the ssh config
vagrant ssh-config > vagrant_ssh_config
ssh_config="$SCRIPTPATH/vagrant_ssh_config"
tmp_ansible_cfg="/tmp/vagrant_ansible.cfg"

# Go to ansible root
cdroot

# copy the ansible cfg
cp ansible.cfg $tmp_ansible_cfg
cat <<EOF >> ${tmp_ansible_cfg}

[ssh_connection]
ssh_args = -F $ssh_config

EOF

# now call ansible with the custom ansible cfg
ANSIBLE_CONFIG="$tmp_ansible_cfg" ansible-playbook -i $SCRIPTPATH/hosts --extra-vars "ceph_stable=True public_network=192.168.42.0/24 cluster_network=192.168.43.0/24 journal_size=100 monitor_interface=eth1" site.yml.sample

# now go back to the scenarios dir
cd $SCRIPTPATH

# run py.test
py.test -v
