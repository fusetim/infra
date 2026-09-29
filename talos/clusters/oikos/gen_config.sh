#!/bin/bash

# if argv[1] is "clean", then clean the generated config files
if [ "$1" == "clean" ]; then
    echo "Cleaning generated Talos config files..."
    rm -rf talos/clusters/oikos/generated/*
    echo "Cleaned generated Talos config files."
    exit 0
fi

TALOS_VERSION=1.14.1
KUBERNETES_VERSION=1.37.0
CLUSTER_PATH=talos/clusters/oikos
SECRETS_FILE=$CLUSTER_PATH/secrets/oikos.yaml
OUTPUT_DIR=$CLUSTER_PATH/generated

echo "Generating Talos config for cluster 'oikos'..."
echo "Talos version: $TALOS_VERSION"
echo "Kubernetes version: $KUBERNETES_VERSION"
echo "Secrets file: $SECRETS_FILE"
echo "Output directory: $OUTPUT_DIR"

talosctl gen config \
    oikos \
    https://oikos.cloud.fusetim.fr:6443 \
    --talos-version "v${TALOS_VERSION}" \
    --kubernetes-version $KUBERNETES_VERSION \
    --additional-sans athena.hosts.fusetim.fr \
    --additional-sans 192.168.1.26 \
    --with-secrets $SECRETS_FILE \
    --output $OUTPUT_DIR

if [ $? -ne 0 ]; then
    echo "Error: Failed to generate Talos config."
    exit 1
fi

chmod 664 "$OUTPUT_DIR/controlplane.yaml" "$OUTPUT_DIR/worker.yaml" "$OUTPUT_DIR/controlplane.yaml"

echo "Patching Talos config for cluster 'oikos'..."

talosctl machineconfig patch \
    "$OUTPUT_DIR/controlplane.yaml" \
    --patch "@$CLUSTER_PATH/patches/01-install.yaml" \
    --patch "@$CLUSTER_PATH/patches/02-schedule-on-controlplanes.yaml" \
    --patch "@$CLUSTER_PATH/patches/03-dualstack.yaml" \
    --patch "@$CLUSTER_PATH/patches/04-hostname-athena.yaml" \
    --patch "@$CLUSTER_PATH/patches/05-gateway-api-crd.yaml" \
    --patch "@$CLUSTER_PATH/patches/06-cilium.yaml" \
    --patch "@$CLUSTER_PATH/patches/07-flux.yaml" \
    --output "$OUTPUT_DIR/controlplane-patched.yaml"

if [ $? -ne 0 ]; then
    echo "Error: Failed to patch Talos config."
    exit 1
fi

echo "Talos config generation and patching completed. Patched config is available at '$OUTPUT_DIR/controlplane-patched.yaml'."