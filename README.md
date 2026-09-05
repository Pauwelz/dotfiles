# dotfiles

Personal [chezmoi](https://www.chezmoi.io/) configuration for Ubuntu with GNOME.

## Install

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply pauwelz
```

On first init chezmoi asks whether the machine is a GNOME desktop. Answer `n`
on servers or WSL: only the git and fish configuration is applied there. Run
`chezmoi init --prompt` to re-ask.

Before reading the source state, chezmoi runs `.install-password-manager.sh`
(a `read-source-state.pre` hook). It installs the Bitwarden CLI via snap if
missing, points it at the EU cloud (`vault.bitwarden.eu`) and runs `bw login`
once if not logged in. The work email is then read
from the Bitwarden identity item `Identiteitskaart` (custom field `Work Email`)
every time the DevOps git include is rendered. chezmoi unlocks the vault
itself, prompting for the master password, unless `BW_SESSION` is exported:

```fish
set -gx BW_SESSION (bw unlock --raw)
chezmoi apply
```

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
DevOps remotes use the work address read from Bitwarden. A repo that matches neither host needs
`git config user.email` set locally before it can commit. On a machine without
the Bitwarden CLI the DevOps include is skipped entirely.

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
