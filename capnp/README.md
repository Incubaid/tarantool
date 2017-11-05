# Capnproto on Tarantool

## Tarantool

Install tarantool and all dependencies:
- luajit
- tarantool modules
- lua-capnproto

```
bash install.sh
```

## capnproto

```
sudo apt-get install capnproto
```

## benchmark test

Benchmark file can be found in [benchmark.lua](./benchmark.lua).

The benchmark function is `benchmark`, we can execute the benchmark by
execute `tarantool benchmark.lua` and then type `benchmark` in Tarantool console

```
# tarantool benchmark.lua 
2017-10-31 10:01:19.354 [2623] main/101/benchmark.lua I> systemd: NOTIFY_SOCKET variable is empty, skipping
2017-10-31 10:01:19.355 [2623] main/101/benchmark.lua C> Tarantool 1.7.5-255-gc383806
2017-10-31 10:01:19.357 [2623] main/101/benchmark.lua C> log level 5
2017-10-31 10:01:19.358 [2623] main/101/benchmark.lua I> mapping 503316480 bytes for memtx tuple arena...
2017-10-31 10:01:19.359 [2623] main/101/benchmark.lua I> mapping 134217728 bytes for vinyl tuple arena...
2017-10-31 10:01:19.361 [2623] iproto/101/main I> binary: bound to 0.0.0.0:3313
2017-10-31 10:01:19.363 [2623] main/101/benchmark.lua I> initializing an empty data directory
2017-10-31 10:01:19.368 [2623] snapshot/101/main I> saving snapshot `./00000000000000000000.snap.inprogress'
2017-10-31 10:01:19.370 [2623] snapshot/101/main I> done
2017-10-31 10:01:19.371 [2623] main/101/benchmark.lua I> ready to accept requests
2017-10-31 10:01:19.373 [2623] main/104/checkpoint_daemon I> started
2017-10-31 10:01:19.374 [2623] main/104/checkpoint_daemon I> scheduled the next snapshot at Tue Oct 31 11:23:16 2017
bootstraping database...
tarantool> benchmark()
start with memtx_memory =       488281.25        kbytes
number of data =        1000000
length of one data =    248      bytes
total time :   6.212417 seconds
number of data * lengt of one data =    242187.5         kbytes
tarantool memory usage =        249871ULL        kbytes
tarantool memory overhead =     7868548ULL       bytes
Lua memory used:        197621.6640625   kbytes
---
...

tarantool> 

```

## lua-capnproto

```
sudo apt-get install lua5.3 luarocks
sudo luarocks install lua-cjson
```

## simple tarantool stored procedure using lua-capnproto

**create canpnp file**

User.capnp, it is capnproto definition
```
@0x9a7562d859cc7ffa;

struct User {
  id @0 :UInt32;
  name @1 :Text;
}
```

**compile canpnp file**

```
capnpc -olua User.capnp
```

It will produce `User_capnp.lua` file

**Use it as tarantool stored procedure**

We created two functions in serialize_user.lua:

- serialize_user : to serialize user data into capnp
- parse user : parse serialized user data to lua object

```
ubuntu@ubuntu-xenial:~/playenv/capnproto/tarantool$ tarantool
tarantool: version 1.6.8-691-g4ed9d50
type 'help' for interactive help
tarantool> dofile("serialize_user.lua")
---
...

tarantool> bin = serialize_user(1, "john doe")
---
...

tarantool> user = parse_user(bin)
---
...

tarantool> print(user.name)
john doe
---
...

tarantool> print(user.id)
1
---
...

tarantool> 
```
