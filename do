#!/usr/bin/env sh
HERE=$(dirname $(realpath "$0"))
ACTION=$1
shift
cd $HERE
case $ACTION in
  upgrade) sudo nixos-rebuild switch --upgrade --flake .;;
esac
cd -
