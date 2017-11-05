from JumpScale import j

import tarantool


# schema = {
#     0: { # Space description
#         'name': 'users', # Space name
#         'default_type': tarantool.STR, # Type that used to decode fields that are not listed below
#         'fields': {
#             0: ('numfield', tarantool.NUM), # (field name, field type)
#             1: ('num64field', tarantool.NUM64),
#             2: ('strfield', tarantool.STR),
#             #2: { 'name': 'strfield', 'type': tarantool.STR }, # Alternative syntax
#             #2: tarantool.STR # Alternative syntax
#         },
#         'indexes': {
#             0: ('pk', [0]), # (name, [field_no])
#             #0: { 'name': 'pk', 'fields': [0]}, # Alternative syntax
#             #0: [0], # Alternative syntax
#         }
#     }
# }

server = tarantool.connect("localhost", 3301)

demo = server.space(1)

for i in range(5):
    print(server.call("string_function"))

C="""
function echo3(name)
  return name
end
"""

server.eval(C)
res=server.call("echo3","test")


from IPython import embed
print ("DEBUG NOW id")
embed()


'''
set -ex
mkdir -p /opt/code/varia
cd /opt/code/varia
git clone https://github.com/tarantool/tarantool.git --recursive
cd tarantool
apt install libreadline-dev
apt-get install libncurses5-dev
cmake .
make
make install
cd ..

git clone --recursive https://github.com/Sulverus/tdb 
cd tdb 
make 
sudo make install prefix=/usr/share/tarantool/
cd ..

mkdir ~/.luarocks
echo "rocks_servers = {[[http://rocks.tarantool.org/]]}" >> ~/.luarocks/config.lua


'''