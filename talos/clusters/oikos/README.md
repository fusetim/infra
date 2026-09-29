# Oikos

## Installation procedure

*Decrypt the secrets :*
```bash
$ sops -d talos/clusters/oikos/secrets/oikos.sops.yaml > talos/clusters/oikos/secrets/oikos.yaml
```

*Generate the configuration :*
```bash
$ talos/clusters/oikos/gen_config.sh clean
$ talos/clusters/oikos/gen_config.sh
```

*Apply the configuration to the new node:*
```bash
$ talosctl apply-config \
    --insecure \
    --nodes <IP> \
    --file talos/clusters/oikos/generated/controlplane-patched.yaml
```

*Generate the talosctl config and kubectl config:*
```bash
$ export TALOSCONFIG="$PWD/talos/clusters/oikos/generated/talosconfig"
$ talosctl config endpoint <IP>
$ talosctl config node <IP>
$ talosctl kubeconfig ~/.kube/config
```

*If it is the first node, bootstrap it:*
```bash
$ talosctl bootstrap
```

*Once the node is up / the cluster is running, bootstrap fluxcd:*
```bash
$ flux bootstrap git \
  --url=ssh://git@github.com/fusetim/infra \
  --branch=main \
  --private-key-file=<path/to/ssh/private.key> \
  --password=<key-passphrase> \
  --path=k8s/clusters/oikos
```