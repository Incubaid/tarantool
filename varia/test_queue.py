import asyncio
import aiotarantool_queue
import random

@asyncio.coroutine
def put_job(queue, num):
    for tube_name in ("tube1", "tube2", "tube3"):
        tube = queue.tube(tube_name)
        task = yield from tube.put({"task_data": tube_name + "_" +  str(num)})

@asyncio.coroutine
def take_job(tube):
    while True:
        task = yield from tube.take()
        if not task:
            break

        print(task.data)
        yield from task.ack()

loop = asyncio.get_event_loop()

queue = aiotarantool_queue.Queue("127.0.0.1", 3301)
put_tasks = [asyncio.async(put_job(queue, num))
             for num in range(20)]

take_tasks = [asyncio.async(take_job(queue.tube(tube_name)))
              for tube_name in ("tube1", "tube2", "tube3")]

loop.run_until_complete(asyncio.wait(put_tasks + take_tasks))
loop.run_until_complete(queue.close())
loop.close()
