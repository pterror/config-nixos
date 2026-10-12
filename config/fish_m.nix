{ ... }:
''
# Pull the main branch and merge it into the current branch
function m
  set -l main_branch (git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
  git checkout $main_branch
  git pull
  git checkout -
  git merge $main_branch
end
''
