#!/usr/bin/env sh
HERE=$(dirname $(realpath "$0"))
ACTION=$1
shift
cd $HERE
case $ACTION in
  upgrade)
    nix flake lock . --update-input unicorn-scribbles-font --update-input miku-cursor --update-input quickshell
    sudo nixos-rebuild switch --upgrade --flake .
    ;;
  upgrader)
    nix flake update .
    sudo nixos-rebuild switch --upgrade --flake .
    ;;
esac
cd -
