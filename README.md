## VM Container

The idea of this project is to provide an easy way to start Kubernetes clusters or other applications that require systemd or cloud-init in a container. 

## Example starting VM Container in Docker

## Example starting VM Container in Kubernetes

Create the following manifests:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: vm-container-cloud-init
stringData:
  meta-data: "{}"
  user-data: |-
    ## template: jinja
    #cloud-config
    runcmd:
    - curl -sfL https://github.com/loft-sh/vcluster/releases/latest/download/install-standalone.sh | sh -
---
apiVersion: v1
kind: Pod
metadata:
  name: vm-container
spec:
  terminationGracePeriodSeconds: 1
  containers:
    - name: vm-container
      image: ghcr.io/loft-sh/vm-container
      securityContext:
        privileged: true
      volumeMounts:
        - name: run
          mountPath: /run
        - name: var-containerd
          mountPath: /var/lib/containerd
        - name: var-kubelet
          mountPath: /var/lib/kubelet
        - name: var-vcluster
          mountPath: /var/lib/vcluster
        - name: vm-container-cloud-init
          mountPath: /var/lib/cloud/seed/nocloud
  volumes:
    - name: var-kubelet
      emptyDir: {}
    - name: var-containerd
      emptyDir: {}
    - name: var-vcluster
      emptyDir: {}
    - name: run
      emptyDir: {}
    - name: vm-container-cloud-init
      secret:
        secretName: vm-container-cloud-init
```

On startup the container will run a Kubernetes cluster.
