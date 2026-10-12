{
  enable = true;
  interactiveShellInit = ''
    set fish_greeting

    alias x='exit'

    abbr gl "git log --format='format:%Cblue%h %C(yellow)%aN %Cgreen%>(14)%ar %Creset%s'"
    abbr nld 'LD=$NIX_LD LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH'

    # Event handler, so it must be defined at startup rather than autoloaded
    function _pterror_ssh_direnv --on-variable DIRENV_DIR
        # Leaving direnv, or moving to a non-pterror one: drop our agent
        if test -z "$DIRENV_DIR"; or not string match -q -- pterror (git config --local user.name 2>/dev/null)
            _pterror_ssh_agent_kill
            return
        end
        # Agent we started is still alive
        set -q _pterror_agent_pid; and kill -0 $_pterror_agent_pid 2>/dev/null; and return
        # Skip if key already loaded in a running agent (e.g. inherited from parent shell)
        if set -q SSH_AGENT_PID; and kill -0 $SSH_AGENT_PID 2>/dev/null
            ssh-add -l 2>/dev/null | string match -q "*pterror_id_ed25519*"; and return
        end
        set -g _pterror_prev_sock $SSH_AUTH_SOCK
        set -g _pterror_prev_pid $SSH_AGENT_PID
        eval "$(ssh-agent -c)" >/dev/null
        set -g _pterror_agent_pid $SSH_AGENT_PID
        ssh-add ~/.ssh/pterror_id_ed25519
    end

    # Kill the agent started by _pterror_ssh_direnv and restore the previous one
    function _pterror_ssh_agent_kill --on-event fish_exit
        set -q _pterror_agent_pid; or return
        kill $_pterror_agent_pid 2>/dev/null
        set -e _pterror_agent_pid
        if test -n "$_pterror_prev_sock"
            set -gx SSH_AUTH_SOCK $_pterror_prev_sock
        else
            set -e SSH_AUTH_SOCK
        end
        if test -n "$_pterror_prev_pid"
            set -gx SSH_AGENT_PID $_pterror_prev_pid
        else
            set -e SSH_AGENT_PID
        end
        set -e _pterror_prev_sock _pterror_prev_pid
    end
  '';
}
