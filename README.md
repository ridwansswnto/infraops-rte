# INFRASTRUCTURE and OPERATIONS ROAD-TO-EXPERT


## Notes
### GKE

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
