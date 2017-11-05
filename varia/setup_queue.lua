box.cfg{listen=3301}

box.schema.user.grant('guest','read,write,execute','universe')

--- import queue module
queue = require 'queue'

-- start the queue
queue.start()

box.queue = queue

-- create tubes
queue.create_tube('mytube', 'fifo')
queue.create_tube('tube1', 'fifo')
queue.create_tube('tube2', 'fifo')
queue.create_tube('tube3', 'fifo')

