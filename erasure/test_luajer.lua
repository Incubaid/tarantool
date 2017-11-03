local luajer = require("luajer")
local ffi = require("ffi")

local function test_encode_str(k, m)
	-- initialize the data
	local str = io.open("luajer.lua", "r"):read("*all")

	-- encode it
	local blocks, block_size = luajer:encode_str(k, m, str)

	-- corrupt the data
	blocks[1] = ""
	blocks[2] = ""

	print("block_size = ", block_size)
	-- decode it
	local str_res = luajer:decode_str(k, m, blocks, block_size, {0, 1, -1}, string.len(str))

	-- check data
	if str ~= str_res then
		print("not recovered")
	else
		print("Recovered!!!")
	end
end

local function the_test()
	-- initialize the data
	local tdata = {}
	for i = 1, (15 * 10) do
		tdata[i] = math.random(100)
	end

	-- encode it
	local data_ptrs, coding_ptrs, block_size = luajer:encode(16, 4, tdata)

	-- corrupt the data
	data_ptrs[1] = ffi.cast("char *", ffi.C.malloc(block_size))

	-- decode it
	local tdata_res = luajer:decode(16, 4, data_ptrs, coding_ptrs, block_size, ffi.new("int[2]", {1, -1}))

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

--the_test()
test_encode_str(4, 2)


