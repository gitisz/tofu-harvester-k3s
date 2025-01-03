import os
import yaml
import click
from pathlib import Path
from deepdiff import DeepDiff


def fetch_and_merge_kubeconfig(username, start_ip, alb_ip, context_name):
    # Paths
    local_kubeconfig_path = Path.home() / ".kube/config"
    fetched_kubeconfig_path = Path.home() / ".kube/temp_k3s"

    # Fetch kubeconfig
    print("🔄 Fetching kubeconfig from remote server...")
    os.system(f"scp -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "
              f"{username}@{start_ip}:/k3s/local-k3s.yaml {fetched_kubeconfig_path}")

    # Load and update the fetched kubeconfig
    print("🔄 Updating server address and ensuring unique names in fetched kubeconfig...")
    with fetched_kubeconfig_path.open() as f:
        new_config = yaml.safe_load(f) or {}

    # Ensure unique names for clusters, contexts, and users
    for cluster in new_config.get('clusters', []):
        cluster['name'] = context_name
        cluster['cluster']['server'] = f"https://{alb_ip}:6443"

    for user in new_config.get('users', []):
        user['name'] = context_name

    for ctx in new_config.get('contexts', []):
        ctx['name'] = context_name
        ctx['context']['cluster'] = context_name
        ctx['context']['user'] = context_name

    # Load existing kubeconfig or initialize an empty one
    print("🔄 Loading local kubeconfig...")
    if local_kubeconfig_path.exists() and local_kubeconfig_path.stat().st_size > 0:
        with local_kubeconfig_path.open() as f:
            local_config = yaml.safe_load(f) or {}
    else:
        print("⚠️ Local kubeconfig not found or empty. Initializing a new one.")
        local_config = {'apiVersion': 'v1', 'kind': 'Config', 'clusters': [], 'users': [], 'contexts': []}

    # Ensure required keys exist
    local_config.setdefault('clusters', [])
    local_config.setdefault('users', [])
    local_config.setdefault('contexts', [])

    # Merge clusters
    local_clusters = {cluster['name']: cluster for cluster in local_config['clusters']}
    for cluster in new_config.get('clusters', []):
        print(f"🔄 Adding/Updating cluster: {cluster['name']}")
        local_clusters[cluster['name']] = cluster
    local_config['clusters'] = list(local_clusters.values())

    # Merge users
    local_users = {user['name']: user for user in local_config['users']}
    for user in new_config.get('users', []):
        print(f"🔄 Adding/Updating user: {user['name']}")
        local_users[user['name']] = user
    local_config['users'] = list(local_users.values())

    # Merge contexts
    local_contexts = {ctx['name']: ctx for ctx in local_config['contexts']}
    for ctx in new_config.get('contexts', []):
        print(f"🔄 Adding/Updating context: {ctx['name']}")
        local_contexts[ctx['name']] = ctx
    local_config['contexts'] = list(local_contexts.values())

    # Set current-context explicitly
    local_config['current-context'] = context_name

    # Write the updated kubeconfig back to disk
    with local_kubeconfig_path.open('w') as f:
        yaml.safe_dump(local_config, f)

    # Clean up
    fetched_kubeconfig_path.unlink()
    print("✅ Kubeconfig merged successfully.")

@click.command()
@click.argument('username')
@click.argument('start_ip')
@click.argument('alb_ip')
@click.argument('context_name')
def main(username, start_ip, alb_ip, context_name):
    fetch_and_merge_kubeconfig(username, start_ip, alb_ip, context_name)

if __name__ == '__main__':
    main()
