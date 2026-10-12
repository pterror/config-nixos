{ ... }:
''
# Convert a single image to webp, leaving an empty placeholder
function cimg1
  sh -c 'a=''${1%.png}; b=''${a%.jpg}; c=''${b%.jpeg}; d=''${c%.gif}; [ -s "$1" ] && [ -n "$d" ] && [ "$d" != "$1" ] && gm convert "$1" -quality 75 -resize 16383x16383\> "$d.webp" && touch -r "$1" "$d.webp" && rm "$1" && touch -r "$d.webp" "$1"' -- $argv[1]
end
''
