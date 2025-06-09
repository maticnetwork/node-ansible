# Polygon Node Sanity Check Tool

This Ansible project conducts a full sanity check on a Polygon node (Bor + Heimdall) — supporting both **sentry** and **validator** nodes.

---

## Prerequisites

Before running the playbook, ensure the following are in place:

- Ansible installed on your local machine.
- SSH access to the remote node with key-based authentication.
- Bor and Heimdall installed on the target machine.
- The SSH user has `sudo` access (used for `chown`, `journalctl`, etc.)
- Python 3 installed on the target node.

---

## Usage

1. **Edit your inventory file** (`inventory.yml`) with your target host:

   ```yml
   [all]
   1.2.3.4 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa
   ```

2. **Run the playbook**:

   - For a **sentry** node (default):
     ```bash
     ANSIBLE_LOG_PATH=sanitycheck.log ansible-playbook -i inventory.yml playbooks/sanitycheck/scheck.yml
     ```

   - For a **validator** node:
     ```bash
     ANSIBLE_LOG_PATH=sanitycheck.log ansible-playbook -i inventory.yml playbooks/sanitycheck/scheck.yml -e node_type=validator
     ```

3. **Logs**:

   Output is shown in the console and logged to `sanitycheck.log` (log path can be configured in `ansible.cfg`).

---

## Overriding Default Values

All roles use default values which can be overridden at runtime using the `-e` flag, example below:

```bash
ANSIBLE_LOG_PATH=sanitycheck.log ansible-playbook playbooks/sanitycheck/scheck.yml -e \
  "bor_path=/usr/local/bin/bor heimdall_path=/opt/heimdalld \
   bor_user=polygon heimdall_user=polygon \
   bor_data_dir=/data/bor heimdall_data_dir=/data/heimdall \
   bor_config_path=/data/bor/config.toml heimdall_config_path=/data/heimdall/config.toml"
```
---

## What It Checks

The playbook performs:

- OS version check
- Bor + Heimdall version checks
- config.toml values extraction (Bor + Heimdall)
- Data directory existence and ownership
- `net-tools` package presence
- Bor + Heimdall P2P port status check (26656, 30303)
- Heimdall + Bor RPC queries
- Validator account info (only if node_type=validator)
- Tail logs from Bor and Heimdall
