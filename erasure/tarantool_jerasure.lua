local luajer = require("luajer")

local _M = { _VERSION = '0.01' }

-- save to tarantool
local function save_to_tarantool(spaces_table,k, m, id, data_table, coding_table, block_size, data_size)
	-- data table
	for i = 1, k do
		local x = spaces_table[i]
		x:put{id, data_table[i], block_size, data_size}
	end
	
	-- coding table
	for i = 1, m  do
		local x = spaces_table[i+k]
		x:put{id, coding_table[i], block_size, data_size}
	end
end

-- save data to tarantool
function _M.save(self, spaces_table, k, m, id, body)
	local data_len = string.len(body)
	local data_table, coding_table, block_size = luajer:encode_str(k, m, body)
	save_to_tarantool(spaces_table, k, m, id, data_table, coding_table, block_size, data_len)
end

-- get data from tarantool
function _M.get(self, spaces_table, k, m,  id)
	local block_size = 0
	local data_size = 0

	-- data table
	local data_table = {}
	for i = 1, k do
		local x = spaces_table[i]
		local data = x:select{id}
		data_table[i] = data[1][2]

		-- get block size and data_size
		if data[1][3] > 0 then
			block_size = data[1][3]
		end
		if data[1][4] > 0 then
			data_size = data[1][4]
		end
	end

	local coding_table = {}
	-- coding ptrs
	for i = 1, m  do
		local x = spaces_table[i+k]
		local data = x:select{id}
		coding_table[i] = data[1][2]
	end
	--print("data_size = ", data_size, ".block_size=", block_size, "data_table[i] len = ", string.len(data_table[1]))

	return luajer:decode_str(k, m, data_table, coding_table, block_size, {-1}, data_size) 
end

return _M
