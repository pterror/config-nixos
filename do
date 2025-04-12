#!/usr/bin/env sh
HERE=$(dirname $(realpath "$0"))
ACTION=$1
shift
cd $HERE
case $ACTION in
  upgrade)
    nix flake update --flake .
    sudo nixos-rebuild switch --upgrade --flake .
    ;;
  upgrade-less)
    nix flake lock . --update-input unicorn-scribbles-font --update-input pointfree-font --update-input miku-cursor --update-input quickshell --update-input qti
    sudo nixos-rebuild switch --upgrade --flake .
    ;;
esac
cd -
