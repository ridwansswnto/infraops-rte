# INFRASTRUCTURE and OPERATIONS ROAD-TO-EXPERT


## Notes
### GKE

Terdapat notif `Can’t scale up a node pool because of a failing scheduling predicate `

Di log terdapat error terkait pvc nfs-jenkins, statusnya adalah storageclass for nfs using `standard`
```
  "parameters": [
    "",
    "persistentvolumeclaim \"jenkins-pvc\" not found"
  ],
  "messageId": "no.scale.up.mig.failing.predicate"
--
  "parameters": [
    "VolumeBinding",
    "node(s) had volume node affinity conflict"
  ],
  "messageId": "no.scale.up.mig.failing.predicate"
```



Kondisi Existing GKE dengan disable NAP (Node Auto Provision) di jadikan enable maka behaviournya
- Di terraform hanya terdetect 1 changes 
```
  # module.rds-cluster.google_container_cluster.primary will be updated in-place
  ~ resource "google_container_cluster" "primary" {
        id                          = "projects/rds-rnd-project/locations/asia-southeast1/clusters/rnd-cluster"
        name                        = "rnd-cluster"
        # (29 unchanged attributes hidden)

      ~ cluster_autoscaling {
          ~ enabled             = false -> true
            # (1 unchanged attribute hidden)

          + resource_limits {
              + maximum       = 100
              + resource_type = "cpu"
            }
          + resource_limits {
              + maximum       = 200
              + resource_type = "memory"
            }
        }

        # (20 unchanged blocks hidden)
    }
```

- jika di lihat dari console, maka cluster akan update on the fly
```
Updating the cluster.
The values shown below will be updated once the operation finishes.
```

- Update memakan waktu 25 Menit
```
module.rds-cluster.google_container_cluster.primary: Still modifying... [id=projects/rds-rnd-project/locations/asia-southeast1/clusters/rnd-cluster, 25m11s elapsed]
module.rds-cluster.google_container_cluster.primary: Modifications complete after 25m14s [id=projects/rds-rnd-project/locations/asia-southeast1/clusters/rnd-cluster]
```
- Selama update workload seperti deployment, ingress tetap bisa di akses


```
{
  "insertId": "6e6522d4-2e97-44f3-8352-6d05d4563281@a1",
  "jsonPayload": {
    "noDecisionStatus": {
      "measureTime": "1672877996",
      "noScaleUp": {
        "unhandledPodGroupsTotalCount": 1,
        "unhandledPodGroups": [
          {
            "podGroup": {
              "samplePod": {
                "name": "jenkins-69f6cd7656-lpxmw",
                "controller": {
                  "name": "jenkins-69f6cd7656",
                  "apiVersion": "apps/v1",
                  "kind": "ReplicaSet"
                },
                "namespace": "jenkins"
              },
              "totalPodCount": 1
            },
            "rejectedMigs": [
              {
                "mig": {
                  "nodepool": "app-pool",
                  "zone": "asia-southeast1-c",
                  "name": "gke-rnd-cluster-app-pool-765541da-grp"
                },
                "reason": {
                  "parameters": [
                    "",
                    "persistentvolumeclaim \"jenkins-pvc\" not found"
                  ],
                  "messageId": "no.scale.up.mig.failing.predicate"
                }
              },
              {
                "reason": {
                  "parameters": [
                    "",
                    "persistentvolumeclaim \"jenkins-pvc\" not found"
                  ],
                  "messageId": "no.scale.up.mig.failing.predicate"
                },
                "mig": {
                  "zone": "asia-southeast1-a",
                  "nodepool": "app-pool",
                  "name": "gke-rnd-cluster-app-pool-cbb01866-grp"
                }
              },
              {
                "mig": {
                  "name": "gke-rnd-cluster-app-pool-c4f332f2-grp",
                  "nodepool": "app-pool",
                  "zone": "asia-southeast1-b"
                },
                "reason": {
                  "parameters": [
                    "",
                    "persistentvolumeclaim \"jenkins-pvc\" not found"
                  ],
                  "messageId": "no.scale.up.mig.failing.predicate"
                }
              }
            ]
          }
        ]
      }
    }
  },
  "resource": {
    "type": "k8s_cluster",
    "labels": {
      "location": "asia-southeast1",
      "project_id": "rds-rnd-project",
      "cluster_name": "rnd-cluster"
    }
  },
  "timestamp": "2023-01-05T00:19:56.829358535Z",
  "logName": "projects/rds-rnd-project/logs/container.googleapis.com%2Fcluster-autoscaler-visibility",
  "receiveTimestamp": "2023-01-05T00:19:57.503879484Z"
}
```


SCALING UP and DOWN

Scaling DOWN takes time `+- 13 Menit` ketika nodes sudah tenang
https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md#how-does-scale-down-work