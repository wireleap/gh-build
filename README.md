# gh-build

This action provides the component building flow for [Wireleap]
components.

[Wireleap]: https://wireleap.com

## using the action

To use this action you need to declare it in the workflow with the
`uses` field of a job definition. Like this:

```
- name: Run component build action
  uses: wireleap/component-build-action
  with:
      token: ${{ secrets.ASSEMBLY_TOKEN }}
      ssh_key: ${{ secrets.SSH_KEY }}
      upload_target: ${{ secrets.UPLOAD_TARGET }}
      gpg_key: ${{ secrets.GPG_KEY }}
```

Parameters:

- `token` is the assembly token to trigger integration tests
- `ssh_key` is the ssh key used to upload releases to the staging
  location
- `upload_target` is the upload target for staging binaries
- `gpg_key` is the GPG key to sign releases

Normally, all of those should be secrets in the calling repo.
