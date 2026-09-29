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

***Important***: You must enable kube-proxy during bootstrap for flannel to work.
Once Cilium is running, you should disable kube-proxy and remove flannel.

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

*If it is the first node, bootstrap it (otherwise just enjoy!):*
```bash
$ talosctl bootstrap
```

*Once the node is up / the cluster is running, generate/add a new sops-age key:*
```bash
$ sops age-keygen --output talos/clusters/oikos/secrets/sops-age.key
```bash
$ age-keygen -o /tmp/age.agekey
$ cat /tmp/age.agekey | kubectl create secret generic sops-age \
    --namespace=flux-system \
    --from-file=age.agekey=/dev/stdin
```

*Note:* for a new node, you might need to update the key for all secrets (using `sops updatekeys`).

*Then bootstrap fluxcd:*
```bash
$ flux bootstrap git \
  --url=ssh://git@github.com/fusetim/infra \
  --branch=main \
  --private-key-file=<path/to/ssh/private.key> \
  --password=<key-passphrase> \
  --path=k8s/clusters/oikos
```

*Now, we need to provide a temporary solution for networking (flannel),
to let Fluxcd reconciliate and install Cilium:*
```bash
kubectl create ns kube-flannel
kubectl label --overwrite ns kube-flannel pod-security.kubernetes.io/enforce=privileged

helm repo add flannel https://flannel-io.github.io/flannel/
helm install flannel --set podCidr="10.244.0.0/16" --namespace kube-flannel flannel/flannel
```

*When cilium is ready, just remove the flannel deployment:*
```bash
helm uninstall flannel --namespace kube-flannel
kubectl delete ns kube-flannel
```

*If you have not already done so, you can now disable kube-proxy.*