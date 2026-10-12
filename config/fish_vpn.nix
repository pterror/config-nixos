{ ... }:
''
# Run a command as the current user inside the chub-vpn WireGuard netns
function vpn
  sudo ip netns exec chub-vpn runuser -u $USER -- $argv
end
''
