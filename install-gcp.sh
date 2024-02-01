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
  apt-get update -y
  apt-get install -y zstd pv aria2
}

function install_ansible() {
  apt_upd
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
  # https://docs.polygon.technology/docs/validate/validate/run-validator-ansible#configure-the-heimdall-service

  option="${1}"
  BOR_CONFIG="/var/lib/bor/config.toml"

  if [ "${option}" == "ws" ]; then
    # comment out [jsonrpc.http] section
    sed -i '/\[jsonrpc\.http\]/,/corsdomain = \["\*"\]/ s/^/#/' "$BOR_CONFIG"
    
    # uncomment [jsonrpc.ws] section
    sed -i '/\[jsonrpc\.ws\]/,/origins = \["\*"\]/ s/^\(\s*\)#\s\{0,1\}/\1/' "$BOR_CONFIG"
  fi

  if [ "${option}" == "rpc-ws" ]; then
    # uncomment [jsonrpc.ws] section
    sed -i '/\[jsonrpc\.ws\]/,/origins = \["\*"\]/ s/^\(\s*\)#\s\{0,1\}/\1/' "$BOR_CONFIG"
  fi
}

function sentry_node_setup() {
  extra_var=${1}
  cd ${INSTALL_DIR}

  ansible-playbook --connection=local -l sentry playbooks/network.yml --extra-var="${extra_var}"
}

function get_snapshot_url() {
  network="${1}"
  client="${2}"
  echo "https://snapshot-download.polygon.technology/$client-$network-parts.txt"
}

function extract_files() {
  compiled_files=$1
  while read -r line; do
      if [[ "$line" == checksum* ]]; then
          continue
      fi
      filename=`echo $line | awk -F/ '{print $NF}'`
      if echo "$filename" | grep -q "bulk"; then
          pv $filename | tar -I zstd -xf - -C . && rm $filename
      else
          pv $filename | tar -I zstd -xf - -C . --strip-components=3 && rm $filename
      fi
  done < $compiled_files
}

function load_snapshots() {
  network="${1}"
  heimdall_snapshot_url=`get_snapshot_url $network heimdall`
  bor_snapshot_url=`get_snapshot_url $network bor`

  echo "$heimdall_snapshot_url"
  echo "$bor_snapshot_url"

  cd /var/lib/heimdall/data/
  aria2c -x6 -s6 "${heimdall_snapshot_url}"
  aria2c -x6 -s6 -i heimdall-$network-parts.txt
  
  # execute final data extraction step
  extract_files heimdall-$network-parts.txt

  cd /var/lib/bor/data/bor/chaindata
  aria2c -x6 -s6 "${bor_snapshot_url}"
  aria2c -x6 -s6 -i bor-$network-parts.txt

  # execute final data extraction step
  extract_files bor-$network-parts.txt
  
  chown -R bor:nogroup  /var/lib/bor
  chown -R heimdall:nogroup  /var/lib/heimdall
}

function polygonctl() {
  service heimdalld $1
  service heimdalld-rest-server $1
  service heimdalld-bridge $1
  service bor $1
}

function usage() {
  echo "Usage: $0 {-n <mainnet|mumbai> -m <archive|fullnode> -s <snapshot|from_scratch> -t <ws|rpc> -p <port-number>}" 1>&2
  exit 1
}

while getopts ":s:m:n:p:e:t:" o; do
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
        e)
            e=${OPTARG}
            ;;
        t)
            t=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))


if [ -z "${s}" ] || [ -z "${m}" ] || [ -z "${n}" ]|| [ -z "${t}" ]|| [ -z "${p}" ]; then
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
if [ -z "${e}" ];then
  e="bor_version=v1.0.0 heimdall_version=v1.0.3 network=mainnet node_type=sentry"
fi

echo "EXTRA_VAR=${e}" > /var/log/extra-var.txt
# p is not a natural decimal number
if [[ ! $p =~ ^[1-9][0-9]*$ ]];then
  usage
fi
# p is not in port range ( 2'nd check isn't needed for natural number)
if ((p > 65535 || p < 1));then
  usage
fi

check_root
check_os
install_dependencies
install_ansible

clone_repo

configure_inventory

sentry_node_setup "${e}"
configure_node "${t}"

mount_disk /dev/sdb /var/lib/bor/data/bor/chaindata bor
mount_disk /dev/sdc /var/lib/heimdall/data heimdalld

chown -R bor:nogroup  /var/lib/bor
chown -R heimdall:nogroup  /var/lib/heimdall

if [ "${s}" == "snapshot" ]; then
  load_snapshots ${n} ${m}
fi

polygonctl start