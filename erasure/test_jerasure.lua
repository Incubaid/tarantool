local jerasure = require("jerasure")
local ffi = require("ffi")

local function test_encode_str(k, m)
	local luajer = jerasure.new(k, m)
	-- initialize the data
	local str = io.open("jerasure.lua", "r"):read("*all")

	-- encode it
	local blocks, block_size = luajer:encode_str(str)

	-- corrupt the data
	local ori_blocks = {}
	ori_blocks[1] = blocks[1]
	blocks[1] = ""

	ori_blocks[2] = blocks[2]
	blocks[2] = ""

	local broken_idxs = {1, 2}

	print("block_size = ", block_size)

	-- decode it
	local recovered = luajer:decode_str(blocks, block_size, broken_idxs, string.len(str))

	-- check data
	for k, v in pairs(broken_idxs) do
		if recovered[v] ~= ori_blocks[v] then
			print("not recovered")
			return
		end
	end
	print("RECOVERED")
end

local function the_test(k, m)
	local luajer = jerasure.new(k, m)
	-- initialize the data
	local tdata = {}
	for i = 1, (15 * 10) do
		tdata[i] = math.random(100)
	end

	-- encode it
	local data_ptrs, coding_ptrs, block_size = luajer:encode(tdata)

	-- corrupt the data
	data_ptrs[1] = ffi.cast("char *", ffi.C.malloc(block_size))

	-- decode it
	local tdata_res = luajer:decode(data_ptrs, coding_ptrs, block_size, ffi.new("int[2]", {1, -1}))

	-- check data
	for i = 1, table.getn(tdata) do
		if tdata[i] ~= tdata_res[i] then
			print("not recovered,td=", tdata[i]," res=", tdata_res[i])
			return
		end
	end
	-- check data
	print("Recovered!!!")
end

the_test(4, 2)
print("test encode_str")
test_encode_str(4, 2)


