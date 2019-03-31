#!/bin/zsh

[ -z $GITHUB_TOKEN ] && exit

echo "https://$ENV{GITHUB_TOKEN}:x-oauth-basic@github.com" > $HOME/.git-credentials
git config user.email "scripts@irssi.org"
git config user.name "Irssi Scripts Helper"
git config credential.helper store
git config remote.origin.url https://github.com/$GITHUB_REPOSITORY
git checkout master
if [ "$(git log -1 --format=%an)" != "$(git config user.name)" -a \\
     "$(git log -1 --format=%cn)" != "$(git config user.name)" ]; then
    git add _data/scripts.yaml
    git commit -m 'automatic scripts database update for $GITHUB_SHA

[skip ci]'
    git config push.default simple
    git push origin
fi
