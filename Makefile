#include ../include/include.mk
#$(eval $(CommonSgeImage))

SshOpts = -i var/id_ed25519 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=1 -o BatchMode=yes 
SshIt = ssh -Tp 222$2 $(SshOpts) root@localhost
Wait = function wt { touch $@.w && while ! $(SHELL) -c "$$*"; do echo -e "Waiting for '$@'. $$(( $$(date +%s) - $$(stat -c %Y $@.w) )) seconds." && sleep 4; done && rm -f $@.w; } && wt
define TmplCeph
var/ceph-node-$1 : var/ceph-node-$1-prepare-mon var/ubuntu-image
	-fuser -k $$@.qcow2 222$2/tcp
	rm -f $$@.qcow2
	var/daiker run -e random -T 22-222$2 -b var/ubuntu-image.qcow2 $$@.qcow2 &
	$$(Wait) $(SshIt) hostname
	[ "$1" = "mon" ] || scp -P 222$2 $(SshOpts) -r var/keys.d root@localhost:
	( m4 -D m4Hostname=$1 -D m4Id=$2 lib/ceph-node.m4 && cat lib/ceph-node-$1.sh )  | $(SshIt)
	touch $$@
var/ceph-node-$1-prepare-mon : $(addprefix var/,$3)
	[ "$1" = "mon" -o ! -f lib/$${@F}.sh ] || ssh -Tp 2220 $(SshOpts) root@localhost < lib/$${@F}.sh
	touch $$@
endef

all : $(addprefix var/ceph-node-,rbd filesystem)
$(eval $(call TmplCeph,rbd,4,ceph-node-osd1 ceph-node-osd2))
$(eval $(call TmplCeph,filesystem,3,ceph-node-osd1 ceph-node-osd2))
$(eval $(call TmplCeph,osd2,2,keys))
$(eval $(call TmplCeph,osd1,1,keys))
$(eval $(call TmplCeph,mon,0,))
var/keys : var/ceph-node-mon 
	mkdir -p $@.d
	scp -P 2220 $(SshOpts) root@localhost:/var/lib/ceph/bootstrap-osd/ceph.keyring $@.d
	scp -P 2220 $(SshOpts) root@localhost:/etc/ceph/ceph.client.admin.keyring $@.d
	scp -P 2220 $(SshOpts) root@localhost:/etc/ceph/ceph.conf $@.d
	touch $@

var/ubuntu-image : var/ubuntu-auto.iso var/daiker
	-fuser -k $@.qcow2
	rm -f $@.qcow2
	var/daiker build -i $< $@.qcow2 
	touch $@
var/ubuntu-auto.iso : lfs/ubuntu-22.04-live-server-amd64.iso var/id_ed25519 lib/user-data
	[ ! -d $@.d ] || chmod -R u+wX $@.d && rm -rf $@.d
	mkdir -p $@.d
	bsdtar xfp $< -C$@.d
	chmod -R u+wX $@.d
	sed -ie "s/timeout=30/timeout=0/; s# ---#autoinstall ds='nocloud-net;s=/cdrom/autoinstall/'#" $@.d/boot/grub/grub.cfg
	rm $@.d/boot/grub/grub.cfge
	mkdir $@.d/autoinstall
	sed -e "s#<ED25519PUB>#$$(cat var/id_ed25519.pub )#; s#<RootPassword>#$$(echo daiker | openssl passwd -6 -stdin)#" lib/user-data > $@.d/autoinstall/user-data
	touch $@.d/autoinstall/vendor-data $@.d/autoinstall/meta-data
	genisoimage -quiet -l -r -J -V "$$(isoinfo -d -i $< | grep 'Volume id: ' |cut -c 12-)" -no-emul-boot -boot-load-size 4 -boot-info-table -b boot/grub/i386-pc/eltorito.img -c boot.catalog -o $@.tmp -joliet-long $@.d
	mv $@.tmp $@
var/id_ed25519 :
	mkdir -p $(@D)
	ssh-keygen -t ed25519 -C "" -f $@ -N ""
lfs/ubuntu-22.04-live-server-amd64.iso :
	mkdir -p $(@D)
	wget -qcO $@.tmp -c https://mirror.umd.edu/ubuntu-iso/22.04/ubuntu-22.04.2-live-server-amd64.iso
	mv $@.tmp $@
var/daiker :
	mkdir -p $(@D)
	wget -cO $@.tmp https://raw.githubusercontent.com/daimh/daiker/master/daiker
	chmod +x $@.tmp
	mv $@.tmp $@

clean :
	-fuser -k var/ceph*.qcow2
	rm -rf var/ceph* var/keys*
