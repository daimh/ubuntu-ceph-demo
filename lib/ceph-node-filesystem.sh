set -xEeuo pipefail
cp keys.d/ceph.client.admin.keyring /etc/ceph
while ! df -t ceph
do
	mount -t ceph 192.168.111.10:6789:/ /mnt -o name=admin
	sleep 1
done
(echo -e '\n\n\n\n###DONE####'; df -t ceph) |tee /dev/tty1
