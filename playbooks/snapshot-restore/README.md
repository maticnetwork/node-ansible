# Polygon Node Snapshot Restore via Ansible

This project provides an Ansible-based automation for restoring a Polygon node (bor or heimdall) using a pre-synced snapshot. It simplifies node setup, particularly for recovery or new deployments in cloud environments.

## Prerequisites

Before running the script, ensure you have the following:

1. SSH Key Access

- A valid SSH private key linked to the target cloud instance (e.g., EC2, GCE).

- The instance should be accessible via SSH using this key.

2. Local Code Editor

- Use a local development environment like VS Code, Sublime, or JetBrains IDEs for editing and managing playbooks.

3. Ansible Installed

- Install Ansible locally:

     `` pip install ansible``

## How to Use

1. Run the Ansible Playbook
Execute the following command, providing required variables:

  `` ansible-playbook -i inventory.yml playbooks/snapshot-restore/snapshot-restore.yml -e "service_name={service_name} provider={provider} network={network}" ``


## Variables:

- service_name – either bor or heimdall

- provider – cloud provider identifier (stakepool, vaultstaking, girnaartech)

- network – network name (mainnet, amoy)

2. Monitor tmux Session on the Instance

Once the Ansible playbook completes, log into the instance.

The playbook uses tmux to perform snapshot restoration tasks asynchronously.

To view the session:

   `` ssh -i <ssh_key><user>@<instance-ip> ``\
   `` tmux ls ``

3. Start the Services Manually

After the snapshot is successfully restored, set the correct permissions and start the respective services:

### For bor:

   `` sudo chown -R bor:nogroup /var/lib/bor ``\
   `` sudo service bor start ``


### For heimdall:

   `` sudo chown -R heimdall:nogroup /var/lib/heimdall ``\
   `` sudo service heimdalld start ``

4. Validate Node Startup

Check logs to confirm your node is running as expected:

   `` journalctl -u bor -f ``

### or

   ``journalctl -u heimdalld -f``

You can also check syncing status using RPC endpoints.

5. Cleanup (Best Practice)
After confirmation, kill the tmux session to clean up the instance:

  ``tmux kill-session -t bor_sync  ``  For bor \
  ``tmux kill-session -t heimdall_sync ``  # For heimdall



