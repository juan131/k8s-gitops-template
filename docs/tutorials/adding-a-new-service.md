# Adding a new service

This tutorial will guide you through the process of adding a new service to your cluster using the CI/CD. It's assumed that you have already completed the [Initial setup](./initial-setup.md) tutorial.

## Prepare your changes in a feature branch

- First, create a new feature branch to prepare your changes. To do so, run the following commands:

```bash
git checkout -b feat/new-service
```

### Manifests-based service

If you want to deploy a new service providing your K8s manifests, follow these steps:

- Create a new directory for your service under `infrastructure/manifests/staging/XXX` where `XXX` is the name of the namespace where you want to deploy your service. For instance, let's create a new service called `my-service` under the `default` namespace:

```bash
mkdir -p infrastructure/manifests/staging/default/my-service
```

- Add the required K8s manifests to deploy your service (deployment, service, ingress, etc) under the directory you created in the previous step.
- (optional) If your service requires any secrets, create a new JSON file with your secrets inputs under `infrastructure/secrets/staging` and configure Sealed Secrets Updater to generate the corresponding sealed secrets by adding a new block at `.sealed-secrets-updater/staging.json`

```diff
{
  "secrets": [
    (...)
-   }
+   },
+   {
+      "name": "my-service",
+      "namespace": "default",
+      "input": {
+        "type": "file",
+        "config": {
+          "path": "infrastructure/secrets/staging/my-service.json"
+        }
+      },
+      "output": {
+        "type": "file",
+        "config": {
+          "path": "infrastructure/manifests/staging/default/my-service/my-service-sealed-secret.yaml"
+        }
+      }
+    }
  ]
}
```

- Now, it's time to configure ArgoCD to manage your new service. To do so, add a new ArgoCD Application definition under `infrastructure/manifests/staging/argo-cd/argo-cd/apps` such as the one below:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-service
  namespace: argo-cd
spec:
  project: default
  sources:
    - repoURL: https://github.com/<your-repo-name>.git
      targetRevision: staging
      path: infrastructure/manifests/staging/default/my-service
      directory:
        recurse: true
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      # Delete resources when Argo CD detects the resource is no longer defined in Git
      prune: true
    syncOptions:
      # Ensures that namespace specified as the application destination exists in the destination cluster
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
```

> Note: remember to replace `<your-repo-name>` with the name of your repository.

### Chart-based service

If you want to deploy a new service using Helm charts, follow these steps:

- Create a new YAML file with the chart values to use to install your your service under `infrastructure/charts-values/staging/XXX` where `XXX` is the name of the namespace where you want to deploy it. For instance, let's use the Bitnami NGINX Helm chart to install a new `nginx` service under the `default` namespace using the following values:

```yaml
replicaCount: 2
```

> Note: find more information about the available installation parameters in the [Bitnami NGINX Helm chart documentation](https://github.com/bitnami/charts/tree/main/bitnami/nginx#parameters).

- (optional) If your service requires any secrets, create a new JSON file with your secrets inputs under `infrastructure/secrets/staging` and configure Sealed Secrets Updater to generate the corresponding sealed secrets by adding a new block at `.sealed-secrets-updater/staging.json`

```diff
{
  "secrets": [
    (...)
-   }
+   },
+   {
+      "name": "nginx",
+      "namespace": "default",
+      "input": {
+        "type": "file",
+        "config": {
+          "path": "infrastructure/secrets/staging/nginx.json"
+        }
+      },
+      "output": {
+        "type": "file",
+        "config": {
+          "path": "infrastructure/manifests/staging/default/nginx/nginx-sealed-secret.yaml"
+        }
+      }
+    }
  ]
}
```

- Now, it's time to configure ArgoCD to manage your new service. To do so, add a new ArgoCD Application definition under `infrastructure/manifests/staging/argo-cd/argo-cd/apps` such as the one below:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nginx
  namespace: argo-cd
spec:
  project: default
  sources:
    - repoURL: registry-1.docker.io/bitnamicharts
      chart: nginx
      targetRevision: 15.3.3
      helm:
        valueFiles:
          - $values/infrastructure/charts-values/staging/default/nginx.yaml
    - repoURL: https://github.com/<your-repo-name>.git
      targetRevision: staging
      ref: values
    - repoURL: https://github.com/<your-repo-name>.git
      targetRevision: staging
      path: infrastructure/manifests/staging/default/nginx
      directory:
        recurse: true
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      # Delete resources when Argo CD detects the resource is no longer defined in Git
      prune: true
    syncOptions:
      # Ensures that namespace specified as the application destination exists in the destination cluster
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
```

> Note: remember to replace `<your-repo-name>` with the name of your repository.

## Create a Pull Request

- Commit & push your changes:

```bash
git add infrastructure .sealed-secrets-updater
git commit -m "feat: new service my-service"
git push -u origin feat/new-service
```

- Once your changes are pushed to the remote repository, create a Pull Request to merge them into the `main` branch. Once the Pull Request is created, some GitHub workflows will be triggered to validate your changes & update the sealed secrets manifests. If everything is ok, you'll be able to merge your changes into the `main` branch.

## Deploy your changes

As you know, ArgoCD is configured to track the changes based on the Git tag `staging`. So, to deploy the services, we just need to update this tag:

- Browse to the Actions tab on your repository and select the "Update tag" action, then click on the "Run workflow" button choosing `staging` as the "Stage to deploy" input.
- Once the workflow finishes, browse to your repository tags and you should see the `staging` tag updated.
- Now, open a tunnel to the ArgoCD server:

```bash
kubectl port-forward -n argo-cd svc/argo-cd-server 9090:80 &
```

- Finally, browse to the ArgoCD UI at [127.0.0.1:9090](http://127.0.0.1:9090) and click on "Refresh" to force ArgoCD to sync the changes.
