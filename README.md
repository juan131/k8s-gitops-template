# GitOps on Kubernetes

A sample K8s project template following GitOps mindset.

## Table of Contents

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Prerequisites](#prerequisites)
- [Tutorials](#tutorials)
- [Environments](#environments)
- [Secrets management](#secrets-management)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Prerequisites

The following tools are required to use this project:

- [Git](https://git-scm.com)
- [Kubernetes cluster](https://kubernetes.io/docs/setup)
- [Helm](https://helm.sh)
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) & [Sealed Secrets Updater](https://github.com/juan131/sealed-secrets-updater)
- [git-crypt](https://github.com/AGWA/git-crypt)
- [yq](https://github.com/mikefarah/yq)

Please refer to each tool's installation instructions to setup your environment.

## Tutorials

Please refer to [tutorials](docs/tutorials/index.md) section for detailed instructions on how to use this project.

## Environments

This project template assumes you're using two different environments (two different K8s clusters) to deploy your services:

- **Production cluster**: public cluster for production workloads.
- **Staging cluster**: internal cluster for validating new features and fixes.

You can find the chart values & k8s manifests used to deploy the services on each environment under the `environments/charts-values` & `environments/manifests` directories, respectively.

## Secrets management

This project uses Sealed Secrets & the [Sealed Secrets Updater](https://github.com/juan131/sealed-secrets-updater) in combination with git-crypt to adopt a GitOps approach & ensuring everything is committed in the Git repository. You can find more information about this setup in the tutorials below:

- [Using file inputs encrypted with git-crypt](https://github.com/juan131/sealed-secrets-updater/blob/main/docs/tutorials/git-crypt.md).
- [Using Sealed Secrets Updater in your CI pipeline](https://github.com/juan131/sealed-secrets-updater/blob/main/docs/tutorials/ci.md).

> Note: you can find the Sealed Secrets Updater config files used for each environment the [.sealed-secrets-updater](.sealed-secrets-updater) directory.
