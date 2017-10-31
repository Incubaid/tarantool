set -ex

apt-get -y update
apt-get install -y git build-essential cmake lua5.1 liblua5.1-0-dev luarocks libssl-dev

## install tarantool from tarantool repo
cd /tmp/
curl http://download.tarantool.org/tarantool/1.7/gpgkey | sudo apt-key add -
release=`lsb_release -c -s`

sudo rm -f /etc/apt/sources.list.d/*tarantool*.list
sudo tee /etc/apt/sources.list.d/tarantool_1_7.list <<- EOF
deb http://download.tarantool.org/tarantool/1.7/ubuntu/ $release main
deb-src http://download.tarantool.org/tarantool/1.7/ubuntu/ $release main
EOF

## install tarantool debugger
sudo apt-get update
sudo apt-get -y install tarantool tarantool-dev

cd /tmp/
git clone --recursive https://github.com/Sulverus/tdb 
cd tdb 
make 
sudo make install prefix=/usr/share/tarantool/
cd ..

## install luajit

git clone http://luajit.org/git/luajit-2.0.git
cd luajit-2.0/
git checkout v2.1
make && sudo make install
ln -sf /usr/local/bin/luajit-2.1.0-beta3 /usr/local/bin/luajit


## tarantool packages
luarocks install luatweetnacl


