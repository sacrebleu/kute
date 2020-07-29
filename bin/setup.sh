#!/usr/bin/env bash
#set -e

echo Checking local ruby version is 2.5...

# verify ruby
if [[ $(ruby -e "print RUBY_VERSION.split('.')[0..1].join('.')") != "2.5" ]]; then
    RBENV=$(which rbenv)
    if [[ -z ${RBENV} ]]; then
        echo "rbenv not installed and ruby >= 2.5 not present in \$PATH"
        exit 1
    fi

    VERSION=$(${RBENV} versions --bare | grep 2.5 | cut -d' ' -f2 | awk '{print substr($0,0,5)}')
    if [[ -z $VERSION ]]; then
        echo "installing ruby 2.5.8"
        $RBENV install 2.5.8
        eval "$(rbenv init -)"
        $RBENV rehash
        $RBENV shell 2.5.8
    else
        echo "setting ruby shell version to ${VERSION}"
        eval "$(rbenv init -)"
        $RBENV rehash
        $RBENV shell $VERSION
    fi
fi

BUNDLER=$(gem list bundler | tr '(),' ' ' | awk '{ split($0,v," "); for (word in v){ print v[word];} }'  | head -1 | grep 2.1)

# verify bundler
if [[ -z $BUNDLER ]]; then
    echo "Installing bundler 2.1.4"
    gem install bundler -v=2.1.4
    # ensure bundler was installed correctly on the path
    if [[ "$(bundle -v)" != "Bundler version 2.1.4" ]]; then
        echo "Could not install bundler v2.1.4, exiting"
        exit 1
    fi
fi

echo "Running bundle install --deployment"
bundle install --deployment
