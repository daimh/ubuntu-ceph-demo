set -xEeuo pipefail
#Mon
apt -y install ceph-mon
UUID=$(uuidgen)
cat > /etc/ceph/ceph.conf << __EOF
[global]
	fsid = $UUID
	mon initial members = ceph-node-mon
	mon host = 192.168.111.1
	public network = 192.168.111.0/24
	auth cluster required = cephx
	auth service required = cephx
	auth client required = cephx
	osd journal size = 1024
	osd pool default size = 1
	osd pool default min size = 1
	osd pool default pg num = 333
	osd pool default pgp num = 333
	osd crush chooseleaf type = 1
#	debug ms = 1/5
__EOF
ceph-authtool --create-keyring /tmp/ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *'
ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow *' --cap mgr 'allow *'
ceph-authtool --create-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring --gen-key -n client.bootstrap-osd --cap mon 'profile bootstrap-osd' --cap mgr 'allow r'
ceph-authtool /tmp/ceph.mon.keyring --import-keyring /etc/ceph/ceph.client.admin.keyring
ceph-authtool /tmp/ceph.mon.keyring --import-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring
chown ceph:ceph /tmp/ceph.mon.keyring
monmaptool --create --add ceph-node-mon 192.168.111.1 --fsid $UUID /tmp/monmap
sudo -u ceph mkdir -p /var/lib/ceph/mon/ceph-ceph-node-mon
sudo -u ceph ceph-mon --mkfs -i ceph-node-mon --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring
systemctl enable ceph-mon@ceph-node-mon
systemctl start ceph-mon@ceph-node-mon
#mgr
apt -y install ceph-mgr
mkdir -p /var/lib/ceph/mgr/ceph-ceph-node-mon
ceph auth get-or-create mgr.ceph-node-mon mon 'allow profile mgr' osd 'allow *' mds 'allow *' > /var/lib/ceph/mgr/ceph-ceph-node-mon/keyring
systemctl enable ceph-mgr@ceph-node-mon
systemctl start ceph-mgr@ceph-node-mon
sleep 2
for ((i=1; ; i++)); do ! ceph -s || break; sleep 2; echo "MSG-002: ceph -s, retry $i"; done
