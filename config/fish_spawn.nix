{ ... }:
''
# Run a command detached from the terminal
function spawn
  nohup $argv > /dev/null 2>&1 & disown
end
''
