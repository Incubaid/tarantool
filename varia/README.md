# Tarantool

Table of Contents
=================

  * [Install](#install)
  * [Tarantool Queue](#tarantool-queue)
  
        * [Simple FIFO Queue](#simple-fifo-queue)
        * [FIFO Queue With TTL and TTR](#fifo-queue-with-time-to-live-and-time-to-execute-support)
  
  * [Tarantool HTTP](#tarantool-http)
  * [Sharding](#sharding)
  * [SSL](#ssl)
  * [Jerasure](#jerasure)
  * [Capnproto](#capnproto)

## Install

```
bash install.sh
```

It will install tarantool with these modules:

- queue
- http
- connection pool
- sharding
- luaossl for SSL support
- IPC library
- lightningmdb

## Tarantool Queue

A collection of persistent queue implementations for Tarantool 

### Simple FIFO queue

**setup queue**

Execute this command in tarantool console
```
box.cfg{listen=3301}

box.schema.user.grant('guest','read,write,execute','universe')
queue = require 'queue'
queue.start()
box.queue = queue
queue.create_tube('mytube', 'fifo')
queue.create_tube('tube1', 'fifo')
queue.create_tube('tube2', 'fifo')
queue.create_tube('tube3', 'fifo')
```

you can also find above instruction in setup_queue.lua file.

we can also execute above commands in tarantool console by execute : `dofile("setup_queue.lua")`

**put / create task**

```
queue.tube.mytube:put("task 1")
```

**take task**

```
task = queue.tube.mytube:take()
print(task)
```


**use the queue from python**

There is `test_queue.py` to test tarantool queue using python3

install packages
```
pip install aiotarantool_queue aiotarantool
```

execute 
```
python3 test_queue.py
```

### FIFO Queue With Time To Live and Time To Execute Support

With time to execute (ttr), we can handle failed task

**Setup Queue**

We create **fifottl** queue
```
queue.create_tube('tubeftl', 'fifottl')
```

**Non Failed Scenario**

create task with ttr = 10. It means the worker has 10 second to do the task and give `ack` to server.
by giving `ack`, worker says to server that the task is completed
```
queue.tube.tubeftl:put("task 10 seconds", {ttr = 10})
```

take the task
```
task = queue.tube.tubeftl:take()
```

do the work, and give `ack`
```
tarantool> print(task)
[0, 't', 'task 10 seconds']
---
...

tarantool> queue.tube.tubeftl:ack(0)
```
'0' in ack argument is the task id

**Failed Scenario**


worker doesn't give `ack`, so the task is available again in server

```
tarantool> queue.tube.tubeftl:put("task 10 seconds - 2", {ttr = 10})
---
- [0, 'r', 'task 10 seconds - 2']
...

tarantool> task = queue.tube.tubeftl:take()
---
...

tarantool> print(task)
[0, 't', 'task 10 seconds - 2']
---
...

tarantool> task = queue.tube.tubeftl:take()
---
...

tarantool> print(task)
[0, 't', 'task 10 seconds - 2']
---
...

```
for second `take` to work, we need to wait for 10 seconds

## Tarantool HTTP

A Tarantool rock for an HTTP client and a server.

Create http server
```
tarantool> httpd = require('http.server').new('0.0.0.0', 8080)
```

define the handler
```
tarantool> function my_handler(req)
        -- req is a Request object
        local resp = req:render({text = req.method..' '..req.path })
        -- resp is a Response object
        resp.headers['x-test-header'] = 'test';
        resp.status = 201
        return resp
    end
```
add route which will be server by `my_handler`
```
httpd:route({path = '/my'}, my_handler)
```
start the server
```
tarantool> httpd:start()
```

Test using `curl`
```
root@tarantool:~/tarantool_sandbox# curl http://localhost:8080/my
GET /my
```

## Sharding

There are two shards, and each shard contains one replica. This requires two nodes. In real life the two nodes would be two computers, but for this illustration the requirement is merely: start two shells, which we'll call Terminal#1 and Terminal #2.

On Terminal #1, say:

```
$ mkdir ~/tarantool_sandbox_1
$ cd ~/tarantool_sandbox_1
$ rm -r *.snap
$ rm -r *.xlog
$ ~/tarantool-1.6/src/tarantool

tarantool> box.cfg{listen = 3301}
tarantool> box.schema.space.create('tester')
tarantool> box.space.tester:create_index('primary', {})
tarantool> box.schema.user.passwd('admin', 'password')
tarantool> console = require('console')
tarantool> cfg = {
         >   servers = {
         >     { uri = 'localhost:3301', zone = '1' },
         >     { uri = 'localhost:3302', zone = '2' },
         >   },
         >   login = 'admin',
         >   password = 'password',
         >   redundancy = 1,
         >   binary = 3301,
         > }
tarantool> shard = require('shard')
tarantool> shard.init(cfg)
tarantool> -- Now put something in ...
tarantool> shard.tester:insert{1,'Tuple #1'}
```

What will appear on Terminal #1 is: a loop of error messages saying "Connection refused" and "server check failure". This is normal. It will go on until Terminal #2 process starts.

On Terminal #2, say:

```
 mkdir ~/tarantool_sandbox_2
$ cd ~/tarantool_sandbox_2
$ rm -r *.snap
$ rm -r *.xlog
$ ~/tarantool-1.6/src/tarantool

tarantool> box.cfg{listen = 3302}
tarantool> box.schema.space.create('tester')
tarantool> box.space.tester:create_index('primary', {})
tarantool> box.schema.user.passwd('admin', 'password')
tarantool> console = require('console')
tarantool> cfg = {
         >   servers = {
         >     { uri = 'localhost:3301', zone = '1' };
         >     { uri = 'localhost:3302', zone = '2' };
         >   };
         >   login = 'admin';
         >   password = 'password';
         >   redundancy = 1;
         >   binary = 3302;
         > }
tarantool> shard = require('shard')
tarantool> shard.init(cfg)
tarantool> -- Now get something out ...
tarantool> shard.tester:select{1}
```

What will appear on Terminal #2, at the end, should look like this:

```
tarantool> shard.tester:select{1}
---
- - - [1, 'Tuple #1']
...
```

This shows that what was inserted by Terminal #1 can be selected by Terminal #2, via the shard package.

## SSL

Tarantool SSL support is using luaossl library.

**public key encryption**

Public key encryption or asymmetric encryption is using modified version of 
lua-resty-rsa library from https://github.com/doujiang24/lua-resty-rsa.

The modification is about how we call openssl C library from Lua.
The original lua-resty-rsa seems only work in nginx/openresty environment.

create private key (private.pem)
```
openssl genrsa -out private.pem 1024
```

create public key from private key (public.pem)

```
ssh-keygen -f private.pem -e -m pem > public.pem 
```

see `pubkey_enc.lua` to see how to do public key encryption.
There is comment on the code, so it is better to see the code directly.

to execute it in tarantool

```
tarantool> dofile("pubkey_enc.lua")
encrypted length:   128
true
---
...
```

**public key signature verification**
See `verify.lua` for public-key signature verification example.

```
tarantool> dofile("verify.lua")
okay    true
type    id-ecPublicKey
sig 303402181ca50be5205a93c00cb3a6da61e440e75455e64a3ef8df2202187d3498046c0db8ee706ccdbdb5edf2ef7384c510f6f8d9e5
---
...
```

## jerasure

See `jerasure` directory

## capnproto

Capnproto guide and tutorial can be found in https://github.com/gig-projects/playenv/tree/master/capnproto/tarantool
