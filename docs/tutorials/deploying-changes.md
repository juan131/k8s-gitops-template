# Deploying changes

This tutorial will guide you through the process of deploying changes to the staging environment using the CI/CD pipeline. It's assumed that you have already completed the [Initial setup](./initial-setup.md) tutorial.

## Prepare your changes in a feature branch

- First, create a new feature branch to prepare your changes. To do so, run the following commands:

```bash
git checkout -b feat/my-branch
```

- Then, apply any changes you need to manifests, secrets or chart values. For instance, let's change the configuration for the API Mock service so it only accepts GET requests. To do so, edit the `infrastructure/manifests/staging/default/api-mock/deployment.yaml` file adding the environment variable `METHODS` to the `api-mock` container:

```diff
spec:
  template:
    spec:
      containers:
        - name: api-mock
          image: docker.io/juanariza131/api-mock:latest
          (...)
          env:
            - name: LOG_LEVEL
              value: "debug"
+           - name: METHODS
+             value: "GET"
            (...)
            - name: SUB_ROUTES
              value: "/foo,/bar"
```

> Note: please refer to [API Mock documentation](https://github.com/juan131/api-mock#configuration) for more information about the available configuration options.

- Let's also update the API token to use to access the API Mock service. To do so, edit the `infrastructure/secrets/staging/api-mock.json` file:
- Now, commit & push your changes:

```bash
git add infrastructure/manifests/staging/default/api-mock/deployment.yaml infrastructure/secrets/staging/api-mock.json
git commit -m "feat: only accept GET requests & update API token"
git push -u origin feat/my-branch
```

## Create a Pull Request

Once your changes are pushed to the remote repository, create a Pull Request to merge them into the `main` branch. Once the Pull Request is created, some GitHub workflows will be triggered to validate your changes & update the sealed secrets manifests. If everything is ok, you'll be able to merge your changes into the `main` branch.

## Deploy your changes

As you know, ArgoCD is configured to track the changes based on the Git tag `staging`. So, to deploy the services, we just need to update this tag:

- Browse to the Actions tab on your repository and select the "Update tag" action, then click on the "Run workflow" button choosing `staging` as the "Stage to deploy" input.
- Once the workflow finishes, browse to your repository tags and you should see the `staging` tag updated.
- Now, open a tunnel to the ArgoCD server:

```bash
kubectl port-forward -n argo-cd svc/argo-cd-server 9090:80 &
```

- Finally, browse to the ArgoCD UI at [127.0.0.1:9090](http://127.0.0.1:9090) and click on "Refresh" to force ArgoCD to sync the changes.

## Test your changes

- Open a tunnel to the API Mock service:

```bash
kubectl port-forward svc/api-mock 8080:80 &
```

Try to access the `/foo` endpoint using the API token you updated in the `api-mock.json` file & `GET` method:

```console
$ curl -H "Authorization: Bearer <your-token>" -X GET http://127.0.0.1:8080/v1/mock/foo
{"success":true}
```

Try using a different token or method, for instance:

```console
$ curl -H "Authorization: Bearer <wrong-token>" -IX GET http://127.0.0.1:8080/v1/mock/foo
HTTP/1.1 401 Unauthorized
Vary: Origin
Www-Authenticate: Bearer realm="example", error="invalid_token", error_description="invalid access token"
Date: Tue, 10 Oct 2023 06:41:37 GMT
Content-Length: 0
```
