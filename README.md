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
ansible -m ping
```

### Networks

There are two networks available:

* `mainnet` (Mainnet v1)
* `mumbai` (Mumbai testnet)

While running Ansible playbook, `network` `node_type` `heimdall_version` `bor_version` needs to be set.

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

### Archive node setup 

To show list of hosts where the playbook will run (notice `--list-hosts` at the end):

```bash
ansible-playbook playbooks/network.yml --extra-var="bor_version=v0.3.0 heimdall_version=v0.3.0 network=mainnet node_type=archive" --list-hosts
```

To run actual playbook on achive node:

```bash
ansible-playbook playbooks/network.yml --extra-var="bor_version=v0.3.0 heimdall_version=v0.3.0 network=mainnet node_type=archive"
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
ansible -m ping
```

`ping` is a module name. You can any module and arguments here.

**Run shell command**

Following command will fetch and print all disk space stats from all hosts.


```bash
ansible -m shell -a "df -h"
```
