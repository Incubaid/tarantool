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
void *memset(void *s, int c, size_t n);
int usleep(int usec);
]]

local RING_LEN = 255

local sem_send = assert(semlib.open("sem_send"))
local sem_recv = assert(semlib.open("sem_recv"))
local shm = assert(shmlib.attach("myshm"))
local sem_mutex = assert(semlib.open("sem_mutex")) -- semaphore used as mutex

local shm_data = ffi.cast("struct shm_data_t *", shm:addr())

shm_data.capacity = RING_LEN

local sent = 0
while sent < 10000 do
	sem_send:dec()

	sem_mutex:dec()
	
	ffi.C.memset(shm_data.data[shm_data.end_idx], 65, 1024)
	shm_data.end_idx = (shm_data.end_idx + 1) % shm_data.capacity;
	shm_data.length = shm_data.length+1
	
	sent = sent + 1
	sem_mutex:inc()
	
	sem_recv:inc()
end

