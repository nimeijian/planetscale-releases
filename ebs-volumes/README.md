## Kubernetes (EKS): Establishing external storage for Vitess databases on AWS EBS 


### Overview:
Following is an example of a simple three-vttablet Vitess keyspace using AWS EKS, with storage on EBS volumes.  This allows any of the vttablet resources to fail (e.g, a container restart, or pod or node replacement), and upon re-creation they resume with the database data prior to the failure.

This example is specific to EKS, but does illustrate how it may be done on other host platforms.  General concepts are presented on the [kubernetes]( https://kubernetes.io ) site as [Volume Snapshots]( https://kubernetes.io/docs/concepts/storage/volumes/)
and [Persistent Volumes]( https://kubernetes.io/docs/concepts/storage/volume-snapshots/).

In general baseline storage for EKS is based on EBS, but is ephemeral.   However, if you call for it expicitly as in this example, it survives the restart.
In essence, the essential /vt/vtdataroot contents are preserved and remounted as before.  If not called as defined below, the restart will initiate with new storage, and hence a new /vt/vtdataroot.

You can learn a bit more info on EBS volumes here:
[Amazon EBS and NVMe on Linux Instances]( https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/nvme-ebs-volumes.html )

With a `mount` command, you will notice with this example that vtdataroot storage is mounted on /dev/nvme1n1: 
`/vt/vtdataroot type ext4 (rw,relatime,debug,data=ordered)`
otherwise, it will be mounted on /dev/nvme0n1p1 which appears to be ephemeral: 
`/vt/vtdataroot type xfs (rw,noatime,attr2,inode64,noquota)`

Arranging for this storage involves two separate steps.  First, one must declare the existence of a new StorageClass, independent of the PsCluster.  Then, the PsCluster declaration itself must utilize that StorageClass.  We present these below as two .yaml files:

**StorageClass_declaration.yaml**
```
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
reclaimPolicy: Retain
mountOptions:
  - debug
volumeBindingMode: Immediate
```

**simple_pscluster_EBS.yaml**
```
---
apiVersion: "planetscale.com/v1alpha1"
kind: "PsCluster"
metadata:
  name: "eks-test"
spec:
  monitored: true
  proxy:
    enabled: true
    authenticate: false
    image: "registry.planetscale.com/vitess/proxy:latest"
  cells:
  - name: "cell1"
    backup:
      type: "file"
      root: "/tmp"
    useGlobalLockserver: true
    gateway:
      count: 1
    vtctld:
      count: 1
    keyspaces:
    - name: "messages"
      shards:
      - range: "0"
        replicas:
        - type: "replica"
          volume:
            storageClassName: standard
            resources:
              requests:
                storage: 250Gi
            volumeMode: Filesystem
            accessModes: [ "ReadWriteOnce" ]
        - type: "replica"
          volume:
            storageClassName: standard
            resources:
              requests:
                storage: 250Gi
            volumeMode: Filesystem
            accessModes: [ "ReadWriteOnce" ]
        - type: "replica"
          volume:
            storageClassName: standard
            resources:
              requests:
                storage: 250Gi
            volumeMode: Filesystem
            accessModes: [ "ReadWriteOnce" ]
```


