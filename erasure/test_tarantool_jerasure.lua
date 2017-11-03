local tarjer = require("tarantool_jerasure")

box.cfg{}

local j1 = box.space.jer_1
local j2 = box.space.jer_2
local j3 = box.space.jer_3
local j4 = box.space.jer_4
local j5 = box.space.jer_5
local j6 = box.space.jer_6
local j7 = box.space.jer_7
local j8 = box.space.jer_8
local j9 = box.space.jer_9
local j10 = box.space.jer_10
local j11 = box.space.jer_11
local j12 = box.space.jer_12

local K = 10
local M = 2

local jtable  = {j1, j2, j3, j4, j5, j6, j7, j8, j9, j10, j11, j12}


local function test_tarantool(filename)
    local body = io.open(filename, "r"):read("*all")
   
	-- save to tarantool
	tarjer:save(jtable, K, M, '99', body)

	-- get it back
    local saved = tarjer:get(jtable, K, M, '99')

    for i=1, string.len(body) do
        if saved[i] ~= body[i] then
            print "trtl not recovered"
            return
        end
    end
    print("Recovered !!!")
end

test_tarantool("luajer.lua")

