set -ex

apt-get -y update
apt-get install -y git build-essential cmake lua5.1 liblua5.1-0-dev luarocks libssl-dev

mkdir -p /opt/code/varia
cd /opt/code/varia

#  install from git repo
#git clone https://github.com/tarantool/tarantool.git --recursive
#cd tarantool
#apt-get install libreadline-dev
#apt-get install libncurses5-dev
#cmake .
#make
#mkdir -p /usr/share/tarantool
#make install
#cd ..

## install tarantool from tarantool repo
curl http://download.tarantool.org/tarantool/1.7/gpgkey | sudo apt-key add -
release=`lsb_release -c -s`

sudo rm -f /etc/apt/sources.list.d/*tarantool*.list
sudo tee /etc/apt/sources.list.d/tarantool_1_6.list <<- EOF
deb http://download.tarantool.org/tarantool/1.7/ubuntu/ $release main
deb-src http://download.tarantool.org/tarantool/1.7/ubuntu/ $release main
EOF

## install tarantool debugger
sudo apt-get update
sudo apt-get -y install tarantool tarantool-dev

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
ln -sf /usr/local/bin/luajit-2.1.0-beta2 /usr/local/bin/luajit



## tarantool packages
luarocks install luatweetnacl


mkdir -p ~/.luarocks/
cat > ~/.luarocks/config.lua <<EOF
rocks_servers = {
    [[http://rocks.tarantool.org/]]
}
EOF

rm ~/.luarocks/config.lua
