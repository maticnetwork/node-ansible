#!/usr/bin/env bash
INSTALL_DIR="/opt/polygon"
POLYGON_ANSIBLE_REPO="https://github.com/maticnetwork/node-ansible.git"
INVENTORY_PATH="${INSTALL_DIR}/inventory.yml"

function check_root() {
  if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or sudo"
    exit 1
  fi
}

function check_os() {
  if ! lsb_release -si | egrep -q "Ubuntu|Debian"; then
    echo "Please run in Ubuntu or Debian"
    exit 1
  fi
}
function mount_disk() {
  EXT_DISK="${1}"
  MOUNT_POINT="${2}"
  FS_LABEL="${3}"
  MOUNT_OPTS="discard,defaults"
  # https://cloud.google.com/compute/docs/disks/add-persistent-disk#format_and_mount_linux
  MKFS_OPTS="-m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard -L ${FS_LABEL}"
  # backup existing dir if any
  mv "${MOUNT_POINT}" "${MOUNT_POINT}.old"
  mkdir -p "${MOUNT_POINT}"
  # mount disk or create a file system on it and then mount it again using label
  mount -o "${MOUNT_OPTS}" "${EXT_DISK}" "${MOUNT_POINT}" || mkfs.ext4 ${MKFS_OPTS} "${EXT_DISK}" && mount -o "${MOUNT_OPTS}" LABEL="${FS_LABEL}" "${MOUNT_POINT}"
  # generate fstab entry
  echo -e "LABEL=${FS_LABEL}\t${MOUNT_POINT}\text4\t${MOUNT_OPTS}\t 0 1" >> /etc/fstab
  umount "${MOUNT_POINT}"
  # label the disk
  tune2fs -L "${FS_LABEL}" "${EXT_DISK}"
  # ensure fstab entry is working fine
  mount "${MOUNT_POINT}"
  # restore content if any
  cp -a "${MOUNT_POINT}.old/." "${MOUNT_POINT}/"
}
function apt_upd() {
  apt update
}

function install_dependencies() {
  apt_upd
  apt install -f git
}

function install_ansible() {
  apt_upd
#  apt install -y software-properties-common
#  add-apt-repository --yes --update ppa:ansible/ansible
  apt install -y ansible
}

function clone_repo() {
  git clone ${POLYGON_ANSIBLE_REPO} ${INSTALL_DIR}
}

function configure_inventory() {
  echo "all:
    hosts:
    children:
      sentry:
        hosts:
          localhost:
      validator:
        hosts:
          localhost:" >${INVENTORY_PATH}
}

function configure_node() {
  # https://docs.polygon.technology/docs/validate/mainnet/validator-guide/#configuring-your-sentry-node
  http_port="${1}"
  HEIMDALLD_CONFIG="/root/.heimdalld/config/config.toml"
  BOR_START_SH="/root/node/bor/start.sh"
  sed -i 's/^seeds =.*/seeds ="f4f605d60b8ffaaf15240564e58a81103510631c@159.203.9.164:26656,4fb1bc820088764a564d4f66bba1963d47d82329@44.232.55.71:26656,2eadba4be3ce47ac8db0a3538cb923b57b41c927@35.199.4.13:26656,3b23b20017a6f348d329c102ddc0088f0a10a444@35.221.13.28:26656,25f5f65a09c56e9f1d2d90618aa70cd358aa68da@35.230.116.151:26656"/g' "${HEIMDALLD_CONFIG}"
  sed -i 's/^prometheus =.*/prometheus = true/g' "${HEIMDALLD_CONFIG}"
  sed -i 's/^max_open_connections =.*/max_open_connections = 100/g' "${HEIMDALLD_CONFIG}"
  if ! grep -q bootnodes "${BOR_START_SH}"; then
    echo '  --bootnodes "enode://0cb82b395094ee4a2915e9714894627de9ed8498fb881cec6db7c65e8b9a5bd7f2f25cc84e71e89d0947e51c76e85d0847de848c7782b13c0255247a6758178c@44.232.55.71:30303,enode://88116f4295f5a31538ae409e4d44ad40d22e44ee9342869e7d68bdec55b0f83c1530355ce8b41fbec0928a7d75a5745d528450d30aec92066ab6ba1ee351d710@159.203.9.164:30303,enode://3178257cd1e1ab8f95eeb7cc45e28b6047a0432b2f9412cff1db9bb31426eac30edeb81fedc30b7cd3059f0902b5350f75d1b376d2c632e1b375af0553813e6f@35.221.13.28:30303,enode://16d9a28eadbd247a09ff53b7b1f22231f6deaf10b86d4b23924023aea49bfdd51465b36d79d29be46a5497a96151a1a1ea448f8a8666266284e004306b2afb6e@35.199.4.13:30303,enode://ef271e1c28382daa6ac2d1006dd1924356cfd843dbe88a7397d53396e0741ca1a8da0a113913dee52d9071f0ad8d39e3ce87aa81ebc190776432ee7ddc9d9470@35.230.116.151:30303"' >> "${BOR_START_SH}"
  fi
  sed -i 's/--http.port.*/--http.port '${http_port}' \\/g' "${BOR_START_SH}"
}

function sentry_node_setup() {
  cd ${INSTALL_DIR}
  ansible-playbook --connection=local -l sentry playbooks/network.yml --extra-var="bor_branch=v0.2.7 heimdall_branch=v0.2.2 network_version=mainnet-v1 node_type=sentry/sentry heimdall_network=mainnet"
}

function get_snapshot_url() {
  network="${1}"
  mode="${2}"
  # always use pruned snapshot instead of fullnode snapshot
  if [ "$mode" == "fullnode" ];then
    mode="pruned"
  fi
  node_type="${3}"
  curl -s https://snapshots.matic.today/ | grep "${network}/${node_type}-${mode}" | cut -f 3 -d '>' | cut -f 1 -d '<'
}

function load_snapshots() {
  network="${1}"
  mode="${2}"

  heimdall_snapshot_url=`get_snapshot_url ${network} "" heimdall`
  bor_snapshot_url=`get_snapshot_url ${network} ${mode} bor`

  echo "$heimdall_snapshot_url"
  echo "$bor_snapshot_url"

  wget "${heimdall_snapshot_url}" -O - | tar -xz -C ~/.heimdalld/data/
  wget "${bor_snapshot_url}" -O - | tar -xz -C ~/.bor/data/bor/chaindata
  chown -R root:root ~/.heimdalld/data/ ~/.bor/data/bor/chaindata
}

function polygonctl() {
  service heimdalld $1
  service bor $1
}

function usage() {
  echo "Usage: $0 {-n <mainnet|mumbai> -m <archive|fullnode> -s <snapshot|from_scratch> -p <rpc-port-number>}" 1>&2
  exit 1
}

# Getopts
while getopts ":s:m:n:p:" o; do
    case "${o}" in
        s)
            s=${OPTARG}
            ;;
        m)
            m=${OPTARG}
            ;;
        n)
            n=${OPTARG}
            ;;
        p)
            p=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

# Validation
if [ -z "${s}" ] || [ -z "${m}" ] || [ -z "${n}" ]|| [ -z "${p}" ]; then
  usage
fi
if [ "${s}" != "snapshot" ] && [ "${s}" != "from_scratch" ]; then
  usage
fi
if [ "${m}" != "archive" ] && [ "${m}" != "fullnode" ]; then
  usage
fi
if [ "${n}" != "mainnet" ] && [ "${n}" != "mumbai" ]; then
  usage
fi
# p is not a natural decimal number
if [[ ! $p =~ ^[1-9][0-9]*$ ]];then
  usage
fi
# p is not in port range ( 2'nd check isn't needed for natural number)
if ((p > 65535 || p < 1));then
  usage
fi
# Main
check_root
check_os
install_dependencies
install_ansible

clone_repo
configure_inventory

sentry_node_setup
configure_node "${p}"
# we need to mount disks on late phase to prevent "existing datadir" complains from ansible
mount_disk /dev/sdb /root/.bor/data/bor/chaindata bor
mount_disk /dev/sdc /root/.heimdalld/data heimdalld

if [ "${s}" == "snapshot" ]; then
  load_snapshots ${n} ${m}
fi

polygonctl start
