set -xEeuo pipefail
cp keys.d/ceph.client.admin.keyring /etc/ceph
while !  rbd map blk -m 192.168.111.10
do
	sleep 1
done
mkfs.ext4 /dev/rbd/rbd/blk
mount /dev/rbd/rbd/blk /mnt
(echo -e '\n\n\n\n###DONE####'; df -h /mnt) |tee /dev/tty1
