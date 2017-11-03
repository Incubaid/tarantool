# create build dir
mkdir /tmp/jerasure2

# install required packages
sudo apt-get -y install build-essential autoconf libtool git

# install gf-complete, required by jerasure2
cd /tmp/jerasure2
git clone https://github.com/iwanbk/gf-complete.git
cd gf-complete
autoreconf -i ; autoreconf -i && ./configure && make && sudo make install

# install jerasure2 library
cd /tmp/jerasure2
git clone https://github.com/tsuraan/Jerasure.git jerasure2
cd jerasure2
autoreconf --force --install && ./configure && make && sudo make install && sudo ldconfig

# fix some include file
cd /usr/local/include/
sudo ln -s jerasure/galois.h 
BUILD_DIR=/tmp/build_seastar_tlog
rm -rf $BUILD_DIR
mkdir $BUILD_DIR

apt-get update
apt-get install -y libsnappy-dev capnproto libcapnp-dev build-essential  autoconf automake nasm yasm libb2-dev
apt-get install -y g++-5 gcc-5 wget git libtool pkg-config

# install isa-l
cd $BUILD_DIR
git clone https://github.com/01org/isa-l.git
cd isa-l
./autogen.sh
./configure
make
make install
