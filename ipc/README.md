# IPC example

Example of using using shared mem + semaphore as circular ring buffer.

**Lua version is most updated version, and currently not compatible with C one**

Current ring buffer is still work in progress, it is currently only a simple array.

We have 2 semaphores here:

- sem_send : indicate that sender can send message
- sem_recv : indicate that receiver can receive message
- sem_mutex : act as mutex for accessing the queue, so we don't get race condition.


## execute all lua example

in one terminal
```
tarantool receiver.lua
```

in other terminal
```
luajit sender.lua
```

## execute C + Lua example

sender in C, receiver in Lua

exec it in one terminal 

```
luajit receiver.lua
```

in other terminal.

compile C sender
```
gcc -o sender sender.c -lrt -lpthread 
```

```
./sender
```

