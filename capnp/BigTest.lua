local big = require "Big_capnp"
local capnp = require "capnp"

-- serialize user data to capnproto
function serialize_data()
	local data = {
		title = "thisnis a unique title ",
		repo = "this is a repo, we should add some data",
        organization = "this is a repo, we should add some data",
        content = "this is a repo, we should add some data",
	}
	return big.Issue.serialize(data)
end

-- -- parse capnproto to object
-- function parse_user(bin)
-- 	return user.User.parse(bin)
-- end

-- local res = []

box.cfg {
    listen = 3313
}

box.once("bootstrap", function()
    box.schema.space.create('tester')
    box.space.tester:create_index('primary',
        { type = 'TREE', parts = {1, 'unsigned'}})
end)



-- box.cfg{listen = 3301}
-- -- engine = 'sophia'
-- s = box.schema.space.create('tester', { if_not_exists = true , id=1 } )
--
-- i = s:create_index('primary', {id=1,type = 'hash', unique=True, parts = {1, 'unsigned'}, if_not_exists = true})

-- box.schema.user.grant('guest', 'read,write,execute', 'universe')

-- tdb = require('tdb')
-- tdb.start()
-- i = 1
-- j = 'a' .. i
-- print('end of program')

function string_function()
  local random_number
  local random_string
  random_number = math.random(65, 90)
  random_string = string.char(random_number)
  return random_string
end

function main_function()
  print 'start'
  local string_value, t

  for i = 1,10000,1 do
    data = serialize_data()
    -- string_value = string_function()
    t = box.tuple.new({i,data})
    box.space.tester:replace(t)
    -- s.insert(i,data)
  end
  print 'done'
end

function read_test()
  print 'start2'
  local string_value, t

  for i = 1,10000,1 do
    data=box.space.tester:get(i)[2]
    obj=big.Issue.parse(data)
  end
  print 'done2'
end
-- main_function()
-- read_test()



function hhash()
  print 'start'
  digest=require("digest")
  data = serialize_data()
  for i = 1,100000,1 do
      hh=digest.sha256_hex(data)
  end
  print 'done'
end
-- hhash()

digest=require("digest")
key="1234567890abcdef1234567890abcdef"

-- data = serialize_data()
-- obj=big.Issue.parse(data)



require('console').start()
