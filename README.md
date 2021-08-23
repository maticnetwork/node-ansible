# Node Ansible

Ansible playbooks to setup Matic validator node.

### Requirements

Make sure you are using python3.x with Ansible. To check: `ansible --version` 

### Setup

Note: If your ssh public key (`~/.ssh/id_rsa.pub`) is already on the remote machines, skip this step.

**Copy `pem` private key file as `.workspace/private.pem`** to enable ssh through ansible. If you don't have pem file, just make sure you can reach remote machines from your own machine using ssh (`ssh <username>@ip`). 

### Inventory

Ansible manages hosts using `inventory.yml` file. Current setup has two group names:

* `sentry`
* `validator`

Each group may have multiple IPs (hosts). Each Ansible command needs group name to be mentioned. Ansible runs the playbook on mentioned group's machines. Note that if you don't mention group name, Ansible will run playbook on all machines.

**Setup inventory**

Add sentry nodes IPs/hosts under the `sentry` group and add validator node's IP/host under `validator` group. 

Example:

```yml
all:
  hosts:
  children:
    sentry:
      hosts:
        xxx.xxx.xx.xx: # <----- Add IP for sentry node
        xxx.xxx.xx.xx: # <----- Add IP for sentry node
    validator:
      hosts:
        xxx.xxx.xx.xx: # <----- Add IP for validator node
```

Note: By default the user to login is setup as ubuntu in `group_vars/all` file. If you have a specific user to be logged in with please change the username in this file.

To check if nodes are reachable, run following commands:

```bash
# to check if sentry nodes are reachable
ansible sentry -m ping

# to check if validator nodes are reachable
ansible validator -m ping
```

### Networks

There are two networks available:

* `mainnet-v1` (Mainnet v1)
* `testnet-v4` (Mumbai testnet)

While running Ansible playbook, `network_version` needs to be set.

Similarly for `heimdall_network` following options can be used

* `mainnet` (Mainnet v1)
* `mumbai`  (Mumbai testnet)

### Sentry node setup

To show list of hosts where the playbook will run (notice `--list-hosts` at the end):

```bash
ansible-playbook -l sentry playbooks/network.yml --extra-var="bor_branch=v0.2.6 heimdall_branch=v0.2.2 network_version=mainnet-v1 node_type=sentry/sentry heimdall_network=mainnet" --list-hosts
```

To run actual playbook on sentry nodes:

```bash
ansible-playbook -l sentry playbooks/network.yml --extra-var="bor_branch=v0.2.6 heimdall_branch=v0.2.2 network_version=mainnet-v1 node_type=sentry/sentry heimdall_network=mainnet"
```

### Validator node setup (with sentry)

To show list of hosts where the playbook will run (notice `--list-hosts` at the end):

```bash
ansible-playbook -l validator playbooks/network.yml --extra-var="bor_branch=v0.2.6 heimdall_branch=v0.2.2 network_version=mainnet-v1 node_type=sentry/validator heimdall_network=mainnet" --list-hosts
```

To run actual playbook on validator node:

```bash
ansible-playbook -l validator playbooks/network.yml --extra-var="bor_branch=v0.2.6 heimdall_branch=v0.2.2 network_version=mainnet-v1 node_type=sentry/validator heimdall_network=mainnet"
```

### Validator node setup (with-out sentry)

To show list of hosts where the playbook will run (notice `--list-hosts` at the end):

```bash
ansible-playbook -l validator playbooks/network.yml --extra-var="bor_branch=v0.2.6 heimdall_branch=v0.2.2 network_version=mainnet-v1 node_type=without-sentry heimdall_network=mainnet" --list-hosts
```

To run actual playbook on validator node:

```bash
ansible-playbook -l validator playbooks/network.yml --extra-var="bor_branch=v0.2.6 heimdall_branch=v0.2.2 network_version=mainnet-v1 node_type=without-sentry heimdall_network=mainnet"
```

### Check sync status

To check the sync status you can run the follwing command on your node

```js
$ curl http://localhost:26657/status
```

The key called `catching_up` will show your sync status, if it's not catching up it means that you are fully synced!

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

This will install node and process exporter on machines for prometheus monitoring. Both exporters will be available at default ports.

**To reboot machine**

```bash
ansible-playbook -l <group-name> playbooks/reboot.yml
```

### Stand-alone build

**To setup Heimdall**

```bash
ansible-playbook -l <group-name> --extra-var="heimdall_branch=v0.2.2 heimdall_network=mainnet" playbooks/heimdall.yml
```

To show list of hosts where the playbook will run:

```bash
ansible-playbook -l <group-name> --extra-var="heimdall_branch=v0.2.2 heimdall_network=mainnet" playbooks/heimdall.yml --list-hosts
```

**To setup Bor**

```bash
ansible-playbook -l <group-name> --extra-var="bor_branch=v0.2.6" playbooks/bor.yml
```

To show list of hosts where the playbook will run:

```bash
ansible-playbook -l <group-name> --extra-var="bor_branch=v0.2.6" playbooks/bor.yml --list-hosts
```

### Adhoc queries

**Ping**

Just to see if machines are reachable:

For sentry nodes:

```bash
ansible sentry -m ping
```

For validator nodes:

```
ansible validator -m ping
```

`ping` is a module name. You can any module and arguments here.

**Run shell command**

Following command will fetch and print all disk space stats from all `sentry` hosts.

For sentry nodes:

```bash
ansible sentry -m shell -a "df -h"
```

For validator nodes:

```bash
ansible validator -m shell -a "df -h"
```
