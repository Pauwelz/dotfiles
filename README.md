# dotfiles

Personal [chezmoi](https://www.chezmoi.io/) configuration for Ubuntu with GNOME.

## Install

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply pauwelz
```

On first run chezmoi asks whether the machine is a GNOME desktop. Answer `n`
on servers or WSL: only the git and fish configuration is applied there. The
answer is stored in `~/.config/chezmoi/chezmoi.toml`.

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
DevOps remotes use the work address. A repo that matches neither host needs
`git config user.email` set locally before it can commit.

## Notes

- Ghostty is installed by a `run_once_` script and is not updated by chezmoi.
  To reinstall or upgrade it, run
  `chezmoi state delete-bucket --bucket=scriptState && chezmoi apply`.
- To update the Nerd Font, bump `fonts.nerd_fonts_version` and run
  `chezmoi apply`.
