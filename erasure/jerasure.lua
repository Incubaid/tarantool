local ffi = require("ffi")

local _M = { _VERSION = '0.01' }

-- C function declaration
ffi.cdef[[
int *reed_sol_vandermonde_coding_matrix(int k, int m, int w);
void jerasure_matrix_encode(int k, int m, int w, int *matrix,
                          char **data_ptrs, char **coding_ptrs, int size);
int jerasure_matrix_decode(int k, int m, int w,
                          int *matrix, int row_k_ones, int *erasures,
						  char **data_ptrs, char **coding_ptrs, int size);
void *malloc(size_t size);
void *memcpy(void *dest, const void *src, size_t n);
void free(void *ptr);
]]

local jerasure2 = ffi.load("Jerasure")
local w = 8

local function do_free(data_ptrs, n)
	for i = 0, n-1 do
		ffi.C.free(data_ptrs[i])
	end
	ffi.C.free(data_ptrs)
end

function _M.free(self, data_ptrs, n)
	do_free(data_ptrs, n)
end


local function get_aligned_size(k, w, data_len)
	local ws = w / 8
	local mul = k * ws
	return math.ceil(data_len/mul) * mul
end

-- reconstruct data from data_ptrs to table (array)
local function encoded_data_to_table(data_ptrs, k, block_size)
	local tdata = {}
	local cur = 1

	for i =0, k -1 do -- iterate over k
		for j = 0, block_size -1 do
			tdata[cur] = data_ptrs[i][j]
			cur = cur + 1
		end
	end
	return tdata
end

-- jerasure2 decode which accept & returns c data structure
local function decode_c(k, m, data_ptrs, coding_ptrs, block_size, broken_ids)
	local matrix = jerasure2.reed_sol_vandermonde_coding_matrix(k, m, w)
	
	jerasure2.jerasure_matrix_decode(k, m, w, matrix, 1, broken_ids,
		data_ptrs, coding_ptrs, block_size)
	
	return data_ptrs
end

-- decode str and get back and str
function _M.decode_str(self, k, m, blocks, block_size, l_broken_ids, data_size)
	-- copy the data
	local data_ptrs = ffi.cast("char **", ffi.C.malloc(8 * k))
	for i = 1, k do
		data_ptrs[i-1] = ffi.cast("char *", ffi.C.malloc(block_size))
		ffi.copy(data_ptrs[i-1], blocks[i], block_size)
	end

	-- copy the coding table
	local coding_ptrs = ffi.cast("char **", ffi.C.malloc(8 * m))
	for i = 1, m do
		coding_ptrs[i-1] = ffi.cast("char *", ffi.C.malloc(block_size))
		ffi.copy(coding_ptrs[i-1], blocks[i+k], block_size)
	end

	-- broken ids
	local c_broken_ids = ffi.cast("int *", ffi.C.malloc(4 * (#l_broken_ids+1)))
	for i=1, #l_broken_ids do
		c_broken_ids[i-1] = l_broken_ids[i] -1
	end
	c_broken_ids[#l_broken_ids] = -1 -- the C library need the array to be ended with -1


	data_ptrs = decode_c(k, m , data_ptrs, coding_ptrs, block_size, c_broken_ids)

	-- repair the broken blocks
	for i, idx in pairs(l_broken_ids) do
		blocks[idx] = ffi.string(data_ptrs[idx-1], block_size)
	end

	do_free(data_ptrs, k)
	do_free(coding_ptrs, m)
	ffi.C.free(broken_ids)

	return blocks
end

-- jerasure2 decode
-- accept C data structures & return the lua one
function _M.decode(self, k, m, data_ptrs, coding_ptrs, block_size, broken_ids)
	-- decode it
	local result_ptrs = decode_c(k, m, data_ptrs, coding_ptrs, block_size, broken_ids)

	-- convert to Lua data structure
	local tdata = encoded_data_to_table(data_ptrs, k, block_size)
	
	-- deallocate c data structure
	for i=0, k-1 do
		ffi.C.free(result_ptrs[i])
	end
	ffi.C.free(result_ptrs)

	return tdata
end

-- encode_c
-- accept lua table, return C array
local function encode_c(k, m, c_data, data_len)
	-- initialize jerasure coding matrix
	local matrix = jerasure2.reed_sol_vandermonde_coding_matrix(k, m, w)
	local block_size = get_aligned_size(k, w, data_len)/ k

	--print("block_size = ", block_size)

	-- initiate data arrays
	local data_ptrs = ffi.cast("char **", ffi.C.malloc(8 * k))

	-- copy the data
	local cursor = 0
	local remaining = data_len
	for i = 0, k -1 do
		local to_copy = block_size
		if remaining < block_size then
			to_copy = remaining
		end
		data_ptrs[i] = ffi.cast("char *", ffi.C.malloc(to_copy))
		ffi.C.memcpy(data_ptrs[i], c_data + cursor, to_copy)
		cursor = cursor + to_copy
	end

	-- initiate coding arrays
	local coding_ptrs = ffi.cast("char **", ffi.C.malloc(8 * m))
	for i = 0, m - 1 do
		coding_ptrs[i] = ffi.C.malloc(8 * block_size)
	end
	
	-- encode it
	jerasure2.jerasure_matrix_encode(k, m, w, matrix, data_ptrs, coding_ptrs, block_size)

	return data_ptrs, coding_ptrs, block_size
end

-- encode a string and return result as table of string
function _M.encode_str(self, k, m, str)
	local data_len = string.len(str)
	local c_data = ffi.cast("char*", ffi.C.malloc(data_len))
	ffi.copy(c_data, str, string.len(str))

	local data_ptrs, coding_ptrs, block_size =  encode_c(k, m, c_data, data_len)

	-- copy the result to Lua
	local blocks = {}
	
	-- copy the data blocks
	for i = 1, k do
		table.insert(blocks, ffi.string(data_ptrs[i-1], block_size))
	end
	-- copy the coding blocks
	for i = 1, m do
		table.insert(blocks, ffi.string(coding_ptrs[i-1], block_size))
	end


	do_free(data_ptrs, k)
	do_free(coding_ptrs, m)
	ffi.C.free(c_data)

	return blocks, block_size
end

-- encode a lua table and
-- and return back C arrays
function _M.encode(self, k, m, tdata)
	local data_len = table.getn(tdata)
	local c_data = ffi.new("char[?]", data_len, unpack(tdata))

	local data_ptrs, coding_ptrs, block_size = encode_c(k, m, c_data, data_len)
	return data_ptrs, coding_ptrs, block_size
end


return _M
