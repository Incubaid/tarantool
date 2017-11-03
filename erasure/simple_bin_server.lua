-- Simple Lua HTTP server that serve binary data:
--    - save
--    - get
-- It is a proof of concept for these methods:
--    save : lua string -> c data -> lua string -> tarantool
--    get : taratool -> lua string -> c data -> lua string
local ffi = require("ffi")
ffi.cdef[[
void *malloc(size_t size);
void *memcpy(void *dest, const void *src, size_t n);
void free(void *ptr);
]]

httpd = require('http.server').new('0.0.0.0', 8080)

box.cfg{}
--console = require('console')
--console.connect('localhost:3301')
local j = box.space.jer

-- save binary data
-- by converting it to cdata first
local function save_bin(id, body)
	-- convert to C
	data = ffi.new("char[?]", string.len(body), body)

	-- convert again to string
	str = ffi.string(data, string.len(body))
	j:put{id, str}
end

-- get binary data by converting it 
-- to C data first
local function get_bin(id)
	tup = j:select{id}
	str = tup[1][2]

	-- convert to C
	--cdata = ffi.new("char[?]", string.len(str), str)
	local cdata = ffi.cast("char *", ffi.C.malloc(string.len(str)))
	ffi.copy(cdata, str, string.len(str))

	-- convert to string again
	return ffi.string(cdata, string.len(str))
end

local function save_simple(req)
	local body = req:read()
	local id = req:stash("id")
	save_bin(id, body)
	return rsp
end

local function get_simple(req)
	local id = req:stash("id")
	local body = get_bin(id)
	local resp = req:render({text = body })
	return resp
end

httpd:route({path = '/put/:id'}, save_simple)
httpd:route({path = '/get/:id'}, get_simple)
httpd:start()
