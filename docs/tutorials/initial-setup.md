# Initial Setup

This tutorial will guide you through the initial setup of the project. It will help you to get started with the project and to adapt it to your own needs.

## Create your own repository based on this template

Follow [GitHub instructions](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template) to create a new repository based on this template, then clone it locally.

You'll need to replace references to the original repository with your own repository name. To do so, run the following commands:

```bash
export REPO_NAME=<your-repo-name>
find "infrastructure/manifests" -type f -name "*.yaml" -print0 | xargs -0 sed -is "s#juan131/k8s-gitops-template#$REPO_NAME#g"
git add infrastructure/manifests
git commit -m "fix: update repo references"
git push
```

## Setup git-crypt

Now, it's time setup `git-crypt`, please refer to the [git-crypt setup tutorial](./git-crypt.md) for detailed instructions.

## Create the staging cluster

> Note: the following steps assume you're using GKE clusters. If you're using a different provider, please adapt the steps accordingly.

- First, we need to create a new GKE cluster for staging. To do so, run the following command:

```bash
export GCP_PROJECT=<your-gcp-project>
gcloud container clusters create staging-cluster \
  --project $GCP_PROJECT \
  --zone us-central1-a \
  --network default \
  --create-subnetwork="" \
  --enable-ip-alias \
  --machine-type n1-standard-2 \
  --num-nodes 1 \
  --enable-autoscaling \
  --min-nodes 1 \
  --max-nodes 3
```

> Note: you can find more information about the GKE cluster creation options [here](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create).

- Once the cluster is created, configure `kubectl` to use it:

```bash
gcloud container clusters get-credentials staging-cluster \
  --project $GCP_PROJECT \
  --zone us-central1-a
```

## Prepare GitHub environment for GitHub workflows

Some GitHub workflows on this project (such as [this one](.github/workflows/update-sealed-secrets.yaml) use a Service Account to obtain the GKE cluster credentials & perform operations on it. To prepare the GitHub environment for this, follow the steps below:

- Create a Service Account and assign it the "Kubernetes Engine Developer" role. To do so, run the following commands:

```bash
gcloud iam service-accounts create github-workflows-sa \
  --project $GCP_PROJECT \
  --description "Service Account for running GKE operations from GitHub workflows"
gcloud projects add-iam-policy-binding $GCP_PROJECT \
  --member serviceAccount:github-workflows-sa@$GCP_PROJECT.iam.gserviceaccount.com \
  --role roles/container.developer
```

- After that, create a Service Account key:

```bash
gcloud iam service-accounts keys create github-workflows-sa-key.json \
  --project $GCP_PROJECT \
  --iam-account github-workflows-sa@$GCP_PROJECT.iam.gserviceaccount.com
```

- Finally, follow the steps described in [this guide](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository) to create a encrypted secrets in your repository named `GCP_PROJECT` & `GKE_SA_KEY` with the values of your GCP project & the Service Account key you just created, respectively.

## Install Sealed Secrets & ArgoCD in the staging cluster

Once the setup is done, ArgoCD will be responsible for deploying the services on the staging cluster. However, for the initial setup, it's required to install them manually.

- First, install Sealed Secrets:

```bash
helm install sealed-secrets oci://registry-1.docker.io/bitnamicharts/sealed-secrets \
  --values infrastructure/charts-values/staging/kube-system/sealed-secrets.yaml \
  --namespace kube-system
```

- Then, edit the [ArgoCD secrets inputs](../../infrastructure/secrets/staging/argo-cd.json) choosing your own password and create a PR with the changes. Once created, the CI will automatically update the associated Sealed Secrets manifest.
- Merge the PR to update the Sealed Secret manifest.
- Finally, install ArgoCD:

```bash
kubectl create ns argo-cd
kubectl apply -f infrastructure/manifests/staging/argo-cd/argo-cd/argocd-sealed-secret.json
helm install argo-cd oci://registry-1.docker.io/bitnamicharts/argo-cd \
  --values infrastructure/charts-values/staging/argo-cd/argo-cd.yaml \
  --namespace argo-cd
```

## Deploy the rest of services via ArgoCD

ArgoCD is now up & running, so it's time to deploy the rest of services. On the staging environment, ArgoCD is configured to track the changes based on the Git tag `staging`. So, to deploy the services, we just need to create this tag:

- Browse to the Actions tab on your repository and select the "Update tag" action, then click on the "Run workflow" button choosing `staging` as the "Stage to deploy" input.
- Once the workflow finishes, browse to your repository tags and you should see the `staging` tag created.
- Create ArgoCD projects & applications by running the following command:

```bash
kubectl apply --recursive \
  -f infrastructure/manifests/staging/argo-cd/argo-cd/projects \
  -f infrastructure/manifests/staging/argo-cd/argo-cd/apps
```

- Now, open a tunnel to the ArgoCD server:

```bash
kubectl port-forward -n argo-cd svc/argo-cd-server 8080:80
```

- Finally, browse to the ArgoCD UI at [127.0.0.1:8080](http://127.0.0.1:8080) and click on "Refresh" to force ArgoCD to sync the changes.
