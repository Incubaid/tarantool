local ffi = require("ffi")
ffi.cdef[[
void *malloc(size_t size);
void free(void *ptr);
void *memcpy(void *dest, const void *src, size_t n);

void gf_gen_cauchy1_matrix(unsigned char *a, int m, int k);
void ec_init_tables(int k, int rows, unsigned char* a, unsigned char* gftbls);
void ec_encode_data(int len, int k, int rows, unsigned char *gftbls, unsigned char **data,
		    unsigned char **coding);
int gf_invert_matrix(unsigned char *in, unsigned char *out, const int n);
]]

local isal = ffi.load("isal")

local IsaErasure = {}
IsaErasure.__index = IsaErasure

local C_BLOCK_TYPE = "unsigned char *"
local C_BLOCK_SHARDS_TYPE = "unsigned char **"
local C_BLOCK_POINTER_SIZE = 8 -- sizeof(unsigned char *)

-- creates Isa-l erasurer object
function IsaErasure.new(data_shards, parity_shards)
	local self = setmetatable({}, IsaErasure)

	self.data_shards = data_shards
	self.parity_shards = parity_shards

	-- init encoding table
	-- we can do it multiple times for encoding
	local c_encode_tab = ffi.cast(C_BLOCK_TYPE, ffi.C.malloc(32 * data_shards * (data_shards+parity_shards)))
	local c_encode_matrix = ffi.cast(C_BLOCK_TYPE, ffi.C.malloc(data_shards * (data_shards + parity_shards)))

	isal.gf_gen_cauchy1_matrix(c_encode_matrix, data_shards+parity_shards, data_shards)
	isal.ec_init_tables(data_shards, parity_shards, c_encode_matrix + (data_shards * data_shards), c_encode_tab);

	ffi.C.free(encode_matrix);

	self.encode_tab = c_encode_tab
	return self
end

-- free this object
function IsaErasure.free(self)
	ffi.C.free(self.encode_tab)
end

-- return total number of shards
function IsaErasure.num_shards(self)
	return self.data_shards + self.parity_shards
end

-- decode data
function IsaErasure.decode(self, blocks)
	local block_size = 0

	-- creates broken index table
	local broken_idx = {}
	for i = 1, #blocks do
		if blocks[i] == "" then
			table.insert(broken_idx, i)
		else
			block_size = #blocks[i]
		end
	end

	-- copy blocks to C
	local c_blocks = ffi.cast(C_BLOCK_SHARDS_TYPE, ffi.C.malloc(C_BLOCK_POINTER_SIZE * (#blocks-#broken_idx)))
	local c_row = 0
	for i = 1, #blocks do
		if blocks[i] ~= "" then
			c_blocks[c_row] = ffi.cast(C_BLOCK_TYPE, ffi.C.malloc(block_size))
			ffi.copy(c_blocks[c_row], blocks[i], block_size)
			c_row = c_row + 1
		end
	end

	-- decoding tables
	local c_decode_tab = self:init_decode_tab(broken_idx)

	-- allocate C results
	local c_results = ffi.cast(C_BLOCK_SHARDS_TYPE, ffi.C.malloc(C_BLOCK_POINTER_SIZE * #broken_idx))
	for i=0, #broken_idx - 1 do
		c_results[i] = ffi.cast(C_BLOCK_TYPE, ffi.C.malloc(block_size))
	end

	-- erasure decode
	isal.ec_encode_data(block_size, self.data_shards, #broken_idx, c_decode_tab, c_blocks, c_results)


	-- repair the data
	for i, idx in pairs(broken_idx) do
		blocks[idx] = ffi.string(c_results[i-1], block_size)
	end

	ffi.C.free(c_decode_tab)
	return blocks
end

-- decoding table initialization
function IsaErasure.init_decode_tab(self, broken_idx)
	-- init encoding table
	local c_encode_tab = ffi.cast(C_BLOCK_TYPE, ffi.C.malloc(32 * self.data_shards * self:num_shards()))
	local c_encode_matrix = ffi.cast(C_BLOCK_TYPE, ffi.C.malloc(self.data_shards * self:num_shards()))

	isal.gf_gen_cauchy1_matrix(c_encode_matrix, self:num_shards(), self.data_shards)
	isal.ec_init_tables(self.data_shards, self.parity_shards, c_encode_matrix + (self.data_shards * self.data_shards), c_encode_tab);


	-- init broken_table
	local is_broken = {}
	for i=1, self:num_shards() do
		is_broken[i] = false
	end

	for i=1, #broken_idx do
		is_broken[broken_idx[i]] = true
	end
	
	-- decoding matrix
	local c_smatrix = ffi.cast(C_BLOCK_TYPE, ffi.C.malloc(self.data_shards * self:num_shards()))
	local c_invmatrix = ffi.cast(C_BLOCK_TYPE, ffi.C.malloc(self.data_shards * self:num_shards()))

	-- remove damaged entries from smatrix
	local row = 0
	for i=0, self:num_shards()-1 do
		if is_broken[i+1] == false then
			for j=0, self.data_shards -1 do
				c_smatrix[self.data_shards * row + j] = c_encode_matrix[self.data_shards * i + j]
			end
			row = row + 1
		end
	end

	assert(isal.gf_invert_matrix(c_smatrix, c_invmatrix, self.data_shards) == 0)

	-- put damaged entries from the inverted matrix
	local c_decode_matrix = ffi.cast(C_BLOCK_TYPE, ffi.C.malloc(self.data_shards * self:num_shards()))
	for i=0, #broken_idx - 1 do
		for j=0, self.data_shards -1 do
			local idx = self.data_shards * i + j
			c_decode_matrix[idx] = c_invmatrix[idx]
		end
	end

	-- init decoding table

	local c_decode_tab = ffi.cast(C_BLOCK_TYPE, ffi.C.malloc(32 * self.data_shards * self:num_shards()))
	isal.ec_init_tables(self.data_shards, #broken_idx, c_decode_matrix, c_decode_tab)

	-- free all allocated data
	ffi.C.free(c_encode_tab)
	ffi.C.free(c_encode_matrix)
	ffi.C.free(c_smatrix)
	ffi.C.free(c_invmatrix)
	ffi.C.free(c_decode_matrix)

	return c_decode_tab
end

-- encode lua string
function IsaErasure.encode(self, data)
	local chunk_size = self:get_chunk_size(#data)
	local c_encoded = self:allocate_encoded(data)
	
	isal.ec_encode_data(chunk_size, self.data_shards, self.parity_shards, self.encode_tab, c_encoded, c_encoded+self.data_shards)

	-- copy the result to Lua table
	local encoded = {}
	for i = 1, self:num_shards() do
		encoded[i] = ffi.string(c_encoded[i-1], chunk_size)
	end
	self:do_free(c_encoded, self:num_shards())
	return encoded
end

-- allocate encoded result
function IsaErasure.allocate_encoded(self, data)
	local chunk_size = self:get_chunk_size(#data)
	local encoded_len = chunk_size * self.data_shards

	c_encoded = ffi.cast(C_BLOCK_SHARDS_TYPE, ffi.C.malloc(C_BLOCK_POINTER_SIZE * self:num_shards()))

	-- check whether we need to add padding
	local pad_len = encoded_len - #data
	if pad_len > 0 then
		-- TODO find a way to append the padding in more effective way
		for i=1, pad_len do
			data = data .. 0
		end
	end

	local c_data = ffi.cast(C_BLOCK_TYPE, ffi.C.malloc(#data))
	ffi.copy(c_data, ffi.cast("const void *", data), #data)

	
	-- copy data blocks
	-- TODO : find a way without copy
	for i=0, self.data_shards-1 do
		c_encoded[i] = ffi.cast(C_BLOCK_TYPE, ffi.C.malloc(chunk_size))
		ffi.C.memcpy(c_encoded[i], c_data + (i * chunk_size), chunk_size)
	end

	for i=self.data_shards, self:num_shards()-1 do
		c_encoded[i] = ffi.cast(C_BLOCK_TYPE, ffi.C.malloc(chunk_size))
	end

	ffi.C.free(c_data)
	return c_encoded
end


function IsaErasure.do_free(self, data_ptrs, n)
	for i = 0, n-1 do
		ffi.C.free(data_ptrs[i])
	end
	ffi.C.free(data_ptrs)
end

function IsaErasure.get_chunk_size(self, data_len)
	local size = math.floor(data_len / self.data_shards)
	if data_len % self.data_shards > 0 then
		size = size + 1
	end
	return size
end

return IsaErasure
