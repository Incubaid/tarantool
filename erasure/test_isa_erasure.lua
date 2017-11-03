local IsaErasure = require("isa_erasure")

local data_shards = 4
local parity_shards = 2
local isa_erasure = IsaErasure.new(data_shards, parity_shards)

function test_encode_decode(filename, broken_idx)
	local data = io.open(filename, "r"):read("*all")
	
	local blocks = isa_erasure:encode(data)
	print("encode OK")

	-- corrupts the data
	local ori_blocks = {}
	for k, v in pairs(broken_idx) do
		ori_blocks[v] = blocks[v]
		blocks[v] = ""
		assert(ori_blocks[v] ~= "")
	end

	-- recover the data
	print("recover data")
	local recovered = isa_erasure:decode(blocks)

	print("checking recovered data ")
	local succeed = true
	for k, v in pairs(broken_idx) do
		if recovered[v] ~= ori_blocks[v] then
			print("failed to recover idx : ", idx)
			succeed = false
		end
	end
	print("recovery result = ", succeed)
end

test_encode_decode("luajer.lua", {1, 2})
