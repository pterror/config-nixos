#!/usr/bin/env sh
ACTION=$1
shift
case $ACTION in
  upgrade) sudo nixos-rebuild switch --upgrade --flake path:.;;
esac
