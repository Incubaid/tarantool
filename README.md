# tarantool

## Installation
The easiest way is from js9 shell and prefab
```
ex = j.tools.executor.getSSHBased("sevm")

prefab.db.tarantool.install()
```
> sevm is node name
>This will install tarantool, luarocks, redis-lua, yaml, penlight, luasec, shard, document, prometheus, queue, expirationd, connpool, http, lua-cjson

## Erasure Encoding

Check [erasure](./erasure) directory.

## Capnp 

Check [capnp](./capnp) directory.

## Crypto with NaCL library

see [nacl.lua](./nacl.lua)

# Other works

See other works on [varia](./varia) directory.
