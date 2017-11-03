# Erasure encoding in Tarantool

## WARNING

Most of The files here are taken from https://github.com/Incubaid/playenv/tree/master/tarantool/jerasure
and then improved/modified, wich migth make other files to be outdated

Untested files:
- bench.go
- clean.sh
- init.lua
- jerhttp.lua
- nginx.conf
- simple_bin_server.lua
- tarantool_jerasure.lua
- test_tarantool_jerasure.lua

## Install

We need to install jerasure2 & ISA-L C library

```
bash install_c_lib.sh
```

## Lua ISA-L erasure modules

`isa_erasure.lua` is Lua binding for ISA-L erasure library.
Test file can be found on `test_isa_erasure.lua`

## Lua jerasure2 modules

There are two Lua files which gives jerasure in tarantool support:

- **jerasure.lua**

It is Lua binding for C jerasure module from https://github.com/tsuraan/Jerasure.

It can be used in Luajit & Tarantool environment.

`test_jerasure.lua` is test file for `jerasure.lua`.

- **tarantool_jerasure.lua**

It is simple module to save erasure coded file to tarantool.

It still doesn't handle corrupted devices.

Value of k (number of data devices) and m (number of coding devices) still hardcoded
to k=10 and m=2.

It works by:

	- erasure coded the file
	- split resulted 12 file pieces to different spaces (jer_1, jer_2.....jer_12)

`test_tarantool_jerasure.lua` is test file for `tarantool_jerasure.lua`

## Erasure modules benchmark

From my test, jerasure2 is faster than ISA-L

```
root@vagrant:~/incubaid/tarantool/erasure# tarantool
Tarantool 1.7.5-255-gc383806
type 'help' for interactive help
tarantool> dofile("benchmark.lua")
---
...

tarantool> k = 6     
---
...

tarantool> m = 3
---
...

tarantool> failed = 2
---
...

tarantool> data_len = 4096 * 50
---
...

tarantool> benchmark_isa(k, m, failed, data_len)
----- benchmark with `ISA-L erasure lib` 10000 times, datalen=204800, failed_shards=2
=> generating random string
=> checking that we can do encode and decode it properly (with some broken shards) for this datasets
                 OK
=> encode benchmark
        total time : 3.045728 seconds
        avg time   : 0.000305 seconds
=> decode benchmark
        total time : 0.700573 seconds
        avg time   : 0.000070 seconds


---
...

tarantool> benchmark_jerasure(k, m, failed, data_len)
----- benchmark with `jerasure2 lib` 10000 times, datalen=204800, failed_shards=2
=> generating random string
=> checking that we can do encode and decode it properly (with some broken shards) for this datasets
                 OK
=> encode benchmark
        total time : 0.962765 seconds
        avg time   : 0.000096 seconds
=> decode benchmark
        total time : 0.169415 seconds
        avg time   : 0.000017 seconds


---
...

```

## Simple Binary file Server 

`jerhttp.lua` is http file binary file server build for this test.


## test procedure

To get better result it is better to do these steps when testing:

- clean & initialize database (there is already guide & script below)
- do write/upload test
- do read/download test
- clean & init database before doing another write-read test

**Server side**

clean old database 

```
bash clean.sh
```

Initialize database

```
tarantool init.lua
```

Start http server

```
tarantool jerhttp.lua
```

**client side**

Test client written using Go, for upload operation, it will upload file named `payload` in 
current directory.

compile test client

```
go build
```

200x parallel upload operation using 5 goroutines (each goroutine do 40 upload)

```
./jerasure -num=200 -mode=save_parallel
```

Each operation will do upload to different ID (1-200).

To do serial upload, change `mode` option from `save_parallel` to `save_serial`.

To increase number of upload operation to 1000, change `num` option from 200 to 1000.


200x parallel get operation using 5 goroutines (each goroutine do 40 get/download)

```
./jerasure -num=200 -mode=get_parallel
```

Each operation will download from different ID (1-200).

To do serial download, change `mode` option to `get_serial`

## nginx reverse proxy

there is nginx.conf that proxied the jerhttp.lua server.

To do test using nginx:

- cp nginx.conf /etc/nginx/conf.d/jerhttp.conf
- /etc/init.d/nginx restart
- add `-via_nginx=true` option when executing client
