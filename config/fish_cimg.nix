{ ... }:
''
# Convert all images under . to webp, leaving empty placeholders
function cimg
  find . -type f \( -iname \*.jpg -o -iname \*.jpeg -o -iname \*.png -o -iname \*.gif \) -a -print0 | xargs -0 -P 16 -I{} sh -c 'echo $1; a=''${1%.png}; b=''${a%.jpg}; c=''${b%.jpeg}; d=''${c%.gif}; [ -s "$1" ] && [ -n "$d" ] && [ "$d" != "$1" ] && gm convert "$1" -quality 75 -resize 16383x16383\> "$d.webp" && touch -r "$1" "$d.webp" && rm "$1" && touch "$1"' -- {}
end
''
