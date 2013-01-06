#!/usr/bin/env sh

local dir=$(pwd)
mkdir /tmp/ruby-library-install
cd /tmp/ruby-library-install

wget https://github.com/rubyworks/autoload/archive/0.2.0.zip
unzip 0.2.0.zip
rm 0.2.0.zip

wget https://github.com/rubyworks/versus/archive/0.2.0.zip
unzip 0.2.0.zip
rm 0.2.0.zip

wget https://github.com/rubyworks/library/archive/0.2.0.zip
unzip 0.2.0.zip
rm 0.2.0.zip

cd autoload-0.2.0
ruby setup.rb
cd ..

cd versus-0.2.0
ruby setup.rb
cd ..

cd library-0.2.0
ruby setup.rb
cd ..

cd $dir
rm -r /tmp/ruby-library-install

