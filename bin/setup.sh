#!/usr/bin/env bash
set -e

echo Checking local ruby version is 2.5...

# verify ruby
if [[ $(ruby -e "print RUBY_VERSION.split('.')[0..1].join('.')") != "2.5" ]]; then
    RBENV=$(which rbenv)
    if [[ -z ${RBENV} ]]; then
        echo "rbenv not installed and ruby >= 2.5 not present in \$PATH"
        exit 1
    fi

    VERSION=$(${RBENV} versions | grep 2.5 | cut -d' ' -f2 | awk '{print substr($0,0,3)}')

    if [[ "$VERSION" != "2.5" ]]; then
        echo "Installing ruby 2.5.8 with rbenv"
        $RBENV install 2.5.8
        eval "$(rbenv init -)"
        $RBENV shell 2.5.8
        $RBENV rehash
    fi
fi

BUNDLER=$(gem list bundler | tr '(),' ' ' | awk '{ split($0,v," "); for (word in v){ print v[word];} }'  | head -1 | grep 2.1)

# verify bundler
if [[ -z "$BUNDLER" ]]; then
    echo "Installing bundler 2.1.4"
    gem install bundler -v=2.1.4
    # ensure bundler was installed correctly on the path
    if [[ "$(bundle -v)" != "Bundler version 2.1.4" ]]; then
        echo "Could not install bundler v2.1.4, exiting"
        exit 1
    fi
fi

bundle install --deployment
