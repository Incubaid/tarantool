box.cfg{listen = 3301}
-- engine = 'sophia'
s = box.schema.space.create('tester', { if_not_exists = true , id=1 } )

i = s:create_index('primary', {id=1,type = 'hash', unique=True, parts = {1, 'NUM'}, if_not_exists = true})

-- box.schema.user.grant('guest', 'read,write,execute', 'universe')

tdb = require('tdb') 
tdb.start() 
i = 1 
j = 'a' .. i 
print('end of program')

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
  for i = 1,100000,1 do
    string_value = string_function()
    t = box.tuple.new({i,string_value})
    box.space.tester:replace(t)
  end
  print 'done'
end

-- function echo2(name)
--   return name
-- end


-- start_time = os.clock()
-- main_function()
-- end_time = os.clock()
-- 'insert done in ' .. end_time - start_time .. ' seconds'

