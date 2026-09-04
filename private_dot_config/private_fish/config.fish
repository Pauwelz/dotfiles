if status is-interactive
    # Commands to run in interactive sessions can go here
end
export SSH_AUTH_SOCK=/home/mpauwels/snap/bitwarden/current/.bitwarden-ssh-agent.sock
starship init fish | source
