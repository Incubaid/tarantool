local semlib = require("ipc.sem")
local shmlib = require("ipc.shm")
local ffi = require("ffi")
ffi.cdef[[
struct shm_data_t {
	char data[255][1024];
	int capacity;
	int length;
	int start; // read index
	int end_idx; // write index
};
]]

local RING_LEN = 255

local sem_send = assert(semlib.open("sem_send", RING_LEN))
local sem_recv = assert(semlib.open("sem_recv", 1))
local shm = assert(shmlib.create("myshm", 261136))
local sem_mutex = assert(semlib.open("sem_mutex", 1))

-- need to decrement here because semlib.open can't create semaphore with initial value = 0
sem_recv:dec()
local recv = 0
local shm_data = ffi.cast("struct shm_data_t *", shm:addr())
while recv < 10000 do
	sem_recv:dec()
	sem_mutex:dec()

	-- use the data memcpy(data, shm_data->data[shm_data->start], 1024);
	shm_data.start = (shm_data.start + 1) % RING_LEN;
	shm_data.length = shm_data.length -1;
	recv = recv + 1

	--print("recv=", recv)
	
	sem_mutex:inc()
	sem_send:inc()
end


