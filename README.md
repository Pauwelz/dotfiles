# dotfiles

Personal [chezmoi](https://www.chezmoi.io/) configuration for Ubuntu with GNOME.

## Install

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Pauwelz/dotfiles/main/install.sh)"
```

`install.sh` installs chezmoi and the Bitwarden CLI (via snap), logs in and
unlocks Bitwarden, then runs `chezmoi init --apply pauwelz`. Extra arguments
are passed to `chezmoi init`, for example `-- --branch some-branch`.

Without the bootstrap script the plain one-liner also works, but then `bw`
must already be installed and logged in, or the work email is prompted for:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply pauwelz
```

On first init chezmoi asks whether the machine is a GNOME desktop. Answer `n`
on servers or WSL: only the git and fish configuration is applied there. Run
`chezmoi init --prompt` to re-ask.

Every `chezmoi init` also reads the work email from the Bitwarden identity
item `Identiteitskaart` (custom field `Work Email`) when `bw` is installed and
logged in, unlocking the vault if needed. Without `bw` the value cached in
`~/.config/chezmoi/chezmoi.toml` is reused, and if there is none it is
prompted for. Leaving the prompt empty disables the DevOps email include.

## What a desktop install does

- Adds the VS Code, Google Chrome and Claude Desktop apt repositories and
  installs the packages listed in `.chezmoidata/packages.yaml`
- Installs Ghostty from [ghostty-ubuntu](https://github.com/mkasberg/ghostty-ubuntu)
  and registers it as the default terminal
- Makes fish the login shell, with starship as the prompt
- Installs FiraCode Nerd Font (pinned in `.chezmoidata/packages.yaml`)
- Installs and enables the dash-to-panel GNOME extension and applies the
  curated dconf settings from `.chezmoitemplates/`
- Points `SSH_AUTH_SOCK` at the Bitwarden snap SSH agent

## Git identity

`~/.gitconfig` sets only the user name. The email is chosen per remote host
through conditional includes: GitHub remotes use the noreply address and Azure
DevOps remotes use the work address fetched from Bitwarden at init. A repo that matches neither host needs
`git config user.email` set locally before it can commit.

Known limitation: git (verified on 2.43) does not match SCP-style SSH remotes
such as `git@github.com:owner/repo.git` against `hasconfig` patterns. Clone
with `https://github.com/...` or `ssh://git@github.com/...` instead, or set
the email locally in such repos.

## Notes

- Ghostty is installed by a `run_once_` script and is not updated by chezmoi.
  To reinstall or upgrade it, run
  `chezmoi state delete-bucket --bucket=scriptState && chezmoi apply`.
- To update the Nerd Font, bump `fonts.nerd_fonts_version` and run
  `chezmoi apply`.
