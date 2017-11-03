local IsaErasure = require("isa_erasure")
local jerasure = require("jerasure")

local N_LOOP = 10000

local function random_string(len)
	local str = ""
	for i = 1, len do
		str = str .. string.char(math.random(0, 255))
	end
	return str
end

local function test_validity(erasurer, data, failed_shards)
	local blocks = erasurer:encode(data)

	-- corrupts the data
	local broken_idx = {}
	for i =1, failed_shards do
		table.insert(broken_idx, i)
	end
	local ori_blocks = {}
	
	for k, v in pairs(broken_idx) do
		ori_blocks[v] = blocks[v]
		blocks[v] = ""
		assert(ori_blocks[v] ~= "")
	end

	--- recover the data
	local recovered = erasurer:decode(blocks)

	--checking recovered data
	for k, v in pairs(broken_idx) do
		if recovered[v] ~= ori_blocks[v] then
			print("failed to recover idx : ", idx)
			return false
		end
	end
	return true
end

local function do_perf_benchmark(erasurer, data_len, failed_shards, title)
	print(string.format("----- benchmark with `%s` %d times, datalen=%d, failed_shards=%d", title, N_LOOP, data_len, failed_shards))
	print("=> generating random string")
	local str = random_string(data_len)
	assert(#str == data_len)

	print("=> checking that we can do encode and decode it properly (with some broken shards) for this datasets")
	if test_validity(erasurer, str, failed_shards) == false then
		print("encode - decode is not working properly")
		return
	end
	print("\t\t OK")

	print("=> encode benchmark")
	local start = os.clock()
	for i = 1, N_LOOP do
		local blocks = erasurer:encode(str)
	end
	local elapsed = os.clock() - start
	print(string.format("\ttotal time : %f seconds", elapsed))
	print(string.format("\tavg time   : %f seconds", elapsed / N_LOOP))

	print("=> decode benchmark")
	local blocks = erasurer:encode(str)
	-- simulate failed shards
	for i = 1, failed_shards do
		blocks[i] = ""
	end
	
	local start = os.clock()
	for i = 1, N_LOOP do
		local recovered = erasurer:decode(blocks)
	end
	local elapsed = os.clock() - start
	print(string.format("\ttotal time : %f seconds", elapsed))
	print(string.format("\tavg time   : %f seconds", elapsed / N_LOOP))

	print("\n")
end

function benchmark_isa(data_shards, parity_shards, failed_shards, data_len)
	local erasurer = IsaErasure.new(data_shards, parity_shards)
	do_perf_benchmark(erasurer, data_len, failed_shards, "ISA-L erasure lib")
end

function benchmark_jerasure(data_shards, parity_shards, failed_shards, data_len)
	local erasurer = jerasure.new(data_shards, parity_shards)
	do_perf_benchmark(erasurer, data_len, failed_shards, "jerasure2 lib")
end

--[[
local data_shards = 6
local parity_shards = 3
local failed_shards = 2
local data_len = 4096 * 25
benchmark_isa(data_shards, parity_shards, failed_shards, data_len)
benchmark_jerasure(data_shards, parity_shards, failed_shards, data_len)
]]--
