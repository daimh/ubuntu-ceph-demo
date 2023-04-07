set -xEeuo pipefail
mount -t ceph 192.168.111.1:6789:/ /mnt -o name=admin,secretfile=keys.d/client.admin
while ! df -t ceph
do
	sleep 1
done
(echo -e '\n\n\n\n###DONE####'; df -t ceph) |tee /dev/tty1
