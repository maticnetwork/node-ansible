# Node Ansible

Ansible scripts to setup Matic validator node

### Setup

**Copy `pem` private key file as `.workspace/private.pem`** to enable ssh through ansible.

### Inventory

Add hosts into `inventory.yml` under appropriate heads.

Available inventory group names:

* `sentry`
* `validator`

### Sentry node setup

```bash
ansible-playbook -l sentry playbooks/mainnet.yml --extra-var="bor_branch=v0.2.0 heimdall_branch=v0.2.0 mainnet_version=mainnet-v1 node_type=sentry/sentry"
```

To show list of hosts where the playbook will run:

```bash
ansible-playbook -l sentry playbooks/mainnet.yml --extra-var="bor_branch=v0.2.0 heimdall_branch=v0.2.0 mainnet_version=mainnet-v1 node_type=sentry/sentry" --list-hosts
```

### Management commands

**To clean deployed setup (warning: this will delete all blockchain data)**

```bash
ansible-playbook -l <group-name> playbooks/clean.yml
```

**To show Heimdall account**

```bash
ansible-playbook -l <group-name> playbooks/show-heimdall-account.yml
```

**To increase ulimit**

```bash
ansible-playbook -l <group-name> playbooks/ulimit.yml
```

**To setup prometheus exporters**

```bash
ansible-playbook -l <group-name> playbooks/setup-exporters.yml
```

**To reboot machine**

```bash
ansible-playbook -l <group-name> playbooks/reboot.yml
```

### Stand-alone build

**To setup Heimdall**

```bash
ansible-playbook -l <group-name> --extra-var="heimdall_branch=v0.2.0" playbooks/heimdall.yml
```

To show list of hosts where the playbook will run:

```bash
ansible-playbook -l <group-name> --extra-var="heimdall_branch=v0.2.0" playbooks/heimdall.yml --list-hosts
```

**To setup Bor**

```bash
ansible-playbook -l <group-name> --extra-var="bor_branch=v0.2.0" playbooks/bor.yml
```

To show list of hosts where the playbook will run:

```bash
ansible-playbook -l <group-name> --extra-var="bor_branch=v0.2.0" playbooks/bor.yml --list-hosts
```

### Adhoc queries

**Ping**

Just to see if machines are reachable:

```bash
$ ansible sentry -m ping
$ ansible validator -m ping
```

`ping` is a module name. You can any module and arguments here.

**Run shell command**

Following command will fetch and print all disk space stats from all `sentry` hosts.

```bash
$ ansible sentry -m shell -a "df -h"
$ ansible validator -m shell -a "df -h"
```