#!/usr/bin/env sh

local dir=$(pwd)
mkdir /tmp/ruby-library-install
cd /tmp/ruby-library-install

wget https://github.com/rubyworks/autoload/archive/master.zip
unzip master.zip
rm master.zip

wget https://github.com/rubyworks/versus/archive/master.zip
unzip master.zip
rm master.zip

wget https://github.com/rubyworks/library/archive/master.zip
unzip master.zip
rm master.zip

cd autoload-master
ruby setup.rb
cd ..

cd versus-master
ruby setup.rb
cd ..

cd library-master
ruby setup.rb
cd ..

cd $dir
rm -r /tmp/ruby-library-install

