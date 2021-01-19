#!/usr/bin/env bash

set -e

REV=$(git describe --tags --abbrev=0)

LREV=$(cat ./.version)

if [[ $REV == $LREV ]]; then
    echo Local revision matches latest remote tag $REV
    exit 1
else
    echo Local revision differs
fi

sed -i "3s/version.*$/version $LREV/" ReadMe.md

echo Bumped version number in ReadMe.md

git commit -m "release $LREV - commit and push to master"

git push origin master

git tag $LREV

git push --tags
