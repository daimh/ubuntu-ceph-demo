set -xEeuo pipefail
#rbd
ceph osd pool create rbd 1
rbd pool init
rbd create --size 10 blk
rbd ls
