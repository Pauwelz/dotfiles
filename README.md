# dotfiles

Personal [chezmoi](https://www.chezmoi.io/) configuration for Ubuntu.

## Install

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply pauwelz
```

On first init chezmoi asks three questions:

- **Is this a GNOME desktop?** Answer `y` on the laptop: GUI apps, fonts and
  dconf settings are applied. Answer `n` on servers or WSL.
- **Is this a development machine?** Answer `y` to get Docker, .NET, the
  Kubernetes and Azure tooling and a local k3d cluster. A headless devbox
  answers `n` / `y`; the laptop can answer `y` to both.
- **Work email?** Used as the git author email for Azure DevOps remotes.

Run `chezmoi init --prompt` to re-ask. After pulling a change that adds a new
question, run `chezmoi init` once; it asks only the unanswered one.

Before reading the source state, chezmoi runs `.install-password-manager.sh`
(a `read-source-state.pre` hook). It installs the Bitwarden CLI via snap if
missing, points it at the EU cloud (`vault.bitwarden.eu`) and runs `bw login`
once if not logged in. The vault is only used by the SSH-key script (see
[SSH](#ssh)), which prompts for the master password on every apply unless
`BW_SESSION` is exported:

```fish
set -gx BW_SESSION (bw unlock --raw)
chezmoi apply
```

## What every Linux install does

- Installs git, fish, starship and curl from apt and makes fish the login shell
- Adds the Tailscale apt repository and installs `tailscale`. Connecting is
  manual: run `sudo tailscale up` once (chezmoi prints a reminder on every
  apply until the node is connected)
- Puts `~/.local/bin` on the fish PATH
- Writes `~/.ssh/config` and syncs the SSH public keys from Bitwarden (see
  [SSH](#ssh))

## What a desktop install does

- Adds the VS Code, Google Chrome and Claude Desktop apt repositories and
  installs the packages listed in `.chezmoidata/packages.yaml`
- Installs Ghostty from [ghostty-ubuntu](https://github.com/mkasberg/ghostty-ubuntu)
  and registers it as the default terminal
- Purges the stock apps those replace: Firefox (deb and snap) and Ptyxis. The
  Ptyxis removal waits until Ghostty is present, because `apport-gtk` needs an
  `x-terminal-emulator` provider
- Installs FiraCode Nerd Font (pinned in `.chezmoidata/packages.yaml`)
- Unpacks the dash-to-panel and Tailscale quick-settings GNOME extensions from
  their GitHub release zips (pinned under `gnome_extensions:`) into
  `~/.local/share/gnome-shell/extensions` and enables them through the curated
  dconf settings from `.chezmoitemplates/`. GNOME Shell loads them at the next
  login. The current user is made the Tailscale operator so the extension can
  toggle the connection without root
- Pins Chrome, VS Code, Claude Desktop and Files to the Dash
- Points `SSH_AUTH_SOCK` at the Bitwarden snap SSH agent

## What a devtools install does

- Adds the Docker CE and Azure CLI apt repositories and installs
  `docker-ce` (with buildx and compose), `azure-cli`, `dotnet-sdk-10.0`
  (Ubuntu's package), `fzf`, `jq`, `unzip` and `gh`
- Downloads pinned release binaries of kubectl, helm, k9s, kubectx, kubens,
  k3d and tilt into `~/.local/bin` (versions under `tools:` in
  `.chezmoidata/packages.yaml`; bump one and `chezmoi apply` to upgrade)
- Enables the Docker service and adds you to the `docker` group. Log out and
  back in afterwards
- Installs Azure Bicep and generates fish completions for kubectl, helm, k3d
  and tilt
- Creates a k3d registry (`k3d-local:5000`, aliased in `/etc/hosts`) and a
  `dev` cluster from `~/.config/k3d/dev.yaml`: two agents, ports 8080/8443 on
  the load balancer, metrics-server disabled
- Sets `DOTNET_CLI_TELEMETRY_OPTOUT`, `DOTNET_NOLOGO` and puts
  `~/.dotnet/tools` on the fish PATH

Typical .NET inner loop against the cluster:

```sh
dotnet publish -t:PublishContainer -p:ContainerRepository=myapp -p:ContainerImageTag=dev
k3d image import myapp:dev -c dev
kubectl rollout restart deploy/myapp
```

## Pinned versions

Nerd Fonts, the release binaries and the GNOME extensions are pinned in
`.chezmoidata/packages.yaml`. To see what is outdated, or to bump every pin to
the latest upstream release:

```sh
.github/scripts/update-versions.sh --check
.github/scripts/update-versions.sh
```

The script needs `curl` and `jq`; export `GITHUB_TOKEN` if you hit the
anonymous GitHub API rate limit. Review the diff, `chezmoi apply` and commit.

The `Update pinned versions` workflow runs the same script every Monday (or on
demand from the Actions tab) and opens a pull request on the `update-versions`
branch. CI on that PR dry-run applies the externals, which proves the new
release assets exist. GitHub does not run CI on pull requests opened with the
default workflow token, so either close and reopen the PR by hand or add a
fine-grained personal access token with contents and pull-requests write
access to the repository secrets as `UPDATE_VERSIONS_TOKEN`.

## SSH

`~/.ssh/config` sets `IdentitiesOnly`, `HashKnownHosts` and (on desktops)
`IdentityAgent` pointing at the Bitwarden SSH agent, and includes
`~/.ssh/config.d/*.conf`. chezmoi manages `github.conf` (key `id_ed25519`)
and `azure-devops.conf` (key `id_rsa`, the only type Azure DevOps accepts) in
that directory; drop other host entries there yourself, they are left alone.

Private keys never touch the disk. On every apply the SSH-key script lists
the SSH-key items in the Bitwarden vault and writes each public key to
`~/.ssh/<item name>.pub` (name lowercased, other characters replaced by `-`),
which is what the `IdentityFile` lines above point at so ssh offers the right
agent key. The same keys are kept in a `# >>> bitwarden ssh keys >>>` block
of `~/.ssh/authorized_keys`; lines outside the block are preserved. Without
`bw`, or without a terminal and `BW_SESSION`, the sync is skipped with a
message.

## Git identity

`~/.gitconfig` sets only the user name. The email is chosen per remote host
through conditional includes: GitHub remotes use the noreply address and Azure
DevOps remotes use the work email answered on `chezmoi init`. A repo that
matches neither host needs `git config user.email` set locally before it can
commit.

Known limitation: git (verified on 2.43) does not match SCP-style SSH remotes
such as `git@github.com:owner/repo.git` against `hasconfig` patterns. Clone
with `https://github.com/...` or `ssh://git@github.com/...` instead, or set
the email locally in such repos.

## Notes

- Ghostty and the k3d cluster are set up by `run_once_` scripts and are not
  updated by chezmoi. To reinstall Ghostty or recreate the cluster (after
  `k3d cluster delete dev`), run
  `chezmoi state delete-bucket --bucket=scriptState && chezmoi apply`.
- After a GNOME extension pin changes, log out and back in so GNOME Shell
  loads the new version.
- Machines set up before the extensions moved to `.chezmoiexternal` still have
  pipx and `gext`. Remove them with
  `sudo apt-get purge --autoremove pipx && rm -rf ~/.local/share/pipx ~/.local/bin/gext`.
- The install script only runs again when `.chezmoidata/packages.yaml` or the
  script itself changes. Force it with the same `delete-bucket` command.
