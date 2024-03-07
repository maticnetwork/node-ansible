# Node Ansible

Ansible playbooks to setup Matic validator node.

### Requirements

Make sure you are using python3.x with Ansible. To check: `ansible --version` 

### Setup

Note: If your ssh public key (`~/.ssh/id_rsa.pub`) is already on the remote machines, skip this step.

**Copy `pem` private key file as `.workspace/private.pem`** to enable ssh through ansible. If you don't have pem file, just make sure you can reach remote machines from your own machine using ssh (`ssh <username>@ip`). 

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

### Validator node setup (with sentry)

To show list of hosts where the playbook will run (notice `--list-hosts` at the end):

```bash
ansible-playbook playbooks/network.yml --extra-var="bor_version=v0.3.0 heimdall_version=v0.3.0 network=mainnet node_type=validator" --list-hosts
```

To run actual playbook on validator node:

```bash
ansible-playbook playbooks/network.yml --extra-var="bor_version=v0.3.0 heimdall_version=v0.3.0 network=mainnet node_type=validator"
```

To setup a validator wallet/keys
```bash
ansible-playboook -i $inventory playbooks/validator-setup.yml
```


### Archive node setup 

To show list of hosts where the playbook will run (notice `--list-hosts` at the end):

```bash
ansible-playbook playbooks/network.yml --extra-var="bor_version=v0.3.0 heimdall_version=v0.3.0 network=mainnet node_type=archive" --list-hosts
```

To run actual playbook on archive node:

```bash
ansible-playbook playbooks/network.yml --extra-var="bor_version=v0.3.0 heimdall_version=v0.3.0 network=mainnet node_type=archive"
```

### Check sync status

To check the sync status you can run the follwing command on your node

```js
$ curl http://localhost:26657/status
```
You can also use the following playbook
```bash
ansible-playbook -i $inventory playbooks/heimdall/get-sync-status.yml
```

The key called `catching_up` will show your sync status, if it's not catching up it means that you are fully synced!

Start The Bor service after the above command shows as false that mean heimdall is in sync

Command to Start Bor Service
```bash
sudo service bor start
```
### Management commands

**To clean deployed setup (warning: this will delete all blockchain data)**

```bash
ansible-playbook -l <group-name> playbooks/clean.yml
```

**To show Heimdall account**

```bash
ansible-playbook -l <group-name> playbooks/heimdall/heimdall-show-account.yml
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
ansible-playbook playbooks/heimdall/heimdall.yml --extra-var="heimdall_version=v0.3.0 network=mainnet node_type=sentry"
```

To show list of hosts where the playbook will run:

```bash
ansible-playbook playbooks/heimdall/heimdall.yml --extra-var="heimdall_version=v0.3.0 network=mainnet node_type=sentry" --list-hosts
```

**To setup Bor**

```bash
ansible-playbook playbooks/bor/bor.yml --extra-var="bor_version=v0.3.0 network=mainnet node_type=sentry"
```

To show list of hosts where the playbook will run:

```bash
ansible-playbook playbooks/bor/bor.yml --extra-var="bor_version=v0.3.0 network=mainnet node_type=sentry" --list-hosts
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

**Snapshots and Backups**

You can run the following playbook to start a snapshot on your host for bor
```bash
ansible-playbook -i $inventory playbooks/bor/snapshot-create -e "chaindata=$path target=$target_save_dir"
ansible-playbook -i $inventory playbooks/heimdall/snapshot-create -e "data=$path target=$target_save_dir"
```

You can run the following command on to take a backup of your validator. This playbook assumes you know path of bor and heimdall config directories
```bash
ansible-playbook -i $inventory playbooks/validator-backup.yml -e "destination=$WHERE_YOU_WANT_TO_SAVE_LOCALLY bor_path=PATH_TO_YOUR_BOR_INSTALL heimdall_path=PATH_TO_YOUR_HEIMDALL_PATH"
```
