# Node Ansible

Ansible playbooks to setup Matic validator node.

### Requirements

Make sure you are using python3.x with Ansible. To check: `ansible --version` 

### Inventory

Ansible manages hosts using `inventory.yml` file.

**Setup inventory**

Add nodes ip's in `inventory.yml` as example

Example:

```yml
#add your instance ips here in palce of xx..
xxx.xxx.xx.xx # <----- Add IP for sentry/validator node

```

Note: By default the user to login is setup as ubuntu in `group_vars/all` file. If you have a specific user to be logged in with please change the username in this file.

To check if nodes are reachable, run following commands:

```bash
# to check if nodes are reachable
ansible all -m ping
```

Remove "GO" packet on sentry machine 

### Networks

There are two networks available:

* `mainnet` (Mainnet v1)
* `mumbai` (Mumbai testnet)

While running Ansible playbook, `network` `node_type` `heimdall_version` `bor_version` needs to be set. These Values can be passed in `--extra-var`

### Sentry node setup

To show list of hosts where the playbook will run (notice `--list-hosts` at the end):

```bash
ansible-playbook playbooks/network.yml --extra-var="bor_version=v0.3.0 heimdall_version=v0.3.0 network=mainnet node_type=sentry" --list-hosts
```

To run actual playbook on sentry nodes:

```bash
ansible-playbook playbooks/network.yml --extra-var="bor_version=v0.3.0 heimdall_version=v0.3.0 network=mainnet node_type=sentry"
```

### Setting Up Heimdall Node
Make sure to start/stop/restart service via root

Stop heimdall services :
```bash
systemctl stop heimdalld
```

Make sure to 
```bash
chown -R heimdall:nogroup /var/lib/heimdall/*
```
Download newest heimdall snapshot :
https://snapshot.polygon.technology/

```bash
tar -xzvf heimdall-snapshot-*.gz -C ~/.heimdalld/data/
cd /var/lib/heimdall/
chown -R heimdall:nogroup data/

systemctl enable --now heimdalld
systemctl restart heimdalld
```
### Check sync status

To check the sync status you can run the follwing command on your node

```js
$ curl http://localhost:26657/status
```

The key called `catching_up` will show your sync status, if it's not catching up it means that you are fully synced!
Start The Bor service after the above command shows as false that mean heimdall is in sync

### Bor Node Setup

Download the newest bor snapshot :
https://snapshot.polygon.technology/
```bash
tar -xzvf bor-fullnode-snapshot-*.gz -C ~/.bor/data/bor/chaindata
chown -R bor:nogroup data/
```
Command to Start Bor Service - Make sure to run as Root
```bash
service bor start
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

This will install node and process exporter on machines for prometheus monitoring. Both exporters will be available at default ports.

**To reboot machine**

```bash
ansible-playbook -l <group-name> playbooks/reboot.yml
```

### Stand-alone build

**To setup Heimdall**

```bash
ansible-playbook playbooks/heimdall.yml --extra-var="heimdall_version=v0.3.0 network=mainnet node_type=sentry"
```

To show list of hosts where the playbook will run:

```bash
ansible-playbook playbooks/heimdall.yml --extra-var="heimdall_version=v0.3.0 network=mainnet node_type=sentry" --list-hosts
```

**To setup Bor**

```bash
ansible-playbook playbooks/heimdall.yml --extra-var="bor_version=v0.3.0 network=mainnet node_type=sentry"
```

To show list of hosts where the playbook will run:

```bash
ansible-playbook playbooks/heimdall.yml --extra-var="bor_version=v0.3.0 network=mainnet node_type=sentry" --list-hosts
```

### Adhoc queries

**Ping**

Just to see if machines are reachable:

```bash
ansible all -m ping
```

`ping` is a module name. You can any module and arguments here.

**Run shell command**

Following command will fetch and print all disk space stats from all hosts.


```bash
ansible all -m shell -a "df -h"
```

**FIREWALL Configuration**
Open ports 22, 80, 443, 8545, 26656 and 30303 to world (0.0.0.0/0) on sentry node firewall.

**External Links**

https://wiki.polygon.technology/docs/develop/network-details/full-node-deployment

https://wiki.polygon.technology/docs/develop/network-details/snapshot-instructions-heimdall-bor
