# Setup git-crypt

`git-crypt` is used ensure the secrets inputs are encrypted in the repository. This tutorial will guide you through its initial setup in the repository.

- First, initialize it:

```bash
git-crypt init
```

- Then, create a `.gitattributes` file in the root of the repository with the following content:

```bash
infrastructure/secrets/** filter=git-crypt diff=git-crypt
```

- After that, import the GPG keys of the developers you trust as it's explained on [this guide](https://gpgtools.tenderapp.com/kb/gpg-keychain-faq/how-to-find-public-keys-of-your-friends-and-import-them).
- Now you can add the GPG keys of the developers you trust:

```bash
git-crypt add-gpg-user --trusted DEVELOPER@MAIL.com 
```

- Finally, commit and push the changes:

```bash
git add .gitattributes
git-crypt status
git commit -m "feat: add git-crypt"
git push
```

From this moment on, every developer can encrypt/decrypt the secrets inputs running the commands below:

```bash
# Encrypt secrets inputs
git-crypt lock
# Decrypt secrets inputs
git-crypt unlock
```

## Add a GPG key to GitHub Encrypted Secrets

In order to access secrets inputs in GitHub workflows, it's required to decrypt them in advance. To do so, you need to export a GPG key and add it to GitHub Encrypted Secrets.

- First, export your GPG key using the command below and copy it to your clipboard:

```bash
git-crypt export-key ./tmp-key && cat ./tmp-key | base64 | pbcopy && rm ./tmp-key
```

- Then, follow the steps described in [this guide](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository) to create a new encrypted secret in your repository called `GIT_CRYPT_KEY` with the value of the key you just imported in your clipboard.
