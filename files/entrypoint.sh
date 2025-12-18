#!/bin/bash

# make the root filesystem private
mount --make-rprivate /sys/fs/cgroup

# disable unused systemd components
ln -sf /dev/null /etc/systemd/system/systemd-udevd.service
ln -sf /dev/null /etc/systemd/system/systemd-sysctl.service
ln -sf /dev/null /etc/systemd/system/systemd-networkd.service
ln -sf /dev/null /etc/systemd/system/systemd-networkd.socket
ln -sf /dev/null /etc/systemd/system/systemd-resolved.service
echo 'disable_network_activation: true' > /etc/cloud/cloud.cfg.d/98-disable-network-activation.cfg
echo 'network: {config: disabled}' > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg

# make sure subtree control is set
sed -e 's/ / +/g' -e 's/^/+/' <"/sys/fs/cgroup/cgroup.controllers" >"/sys/fs/cgroup/cgroup.subtree_control" || true

# execute the unshare command
exec unshare --cgroup -- /bin/bash -lc '
  umount /sys/fs/cgroup
  mkdir -p /sys/fs/cgroup
  mount -t cgroup2 none /sys/fs/cgroup
  /escape-cgroup.sh
  /create-kubelet-cgroup.sh
  exec /lib/systemd/systemd
'
