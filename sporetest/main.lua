package.path = './?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;/usr/local/lib/lua/5.1/?.lua;/usr/local/lib/lua/5.1/?/init.lua;/usr/share/lua/5.1/?.lua;/usr/share/lua/5.1/?/init.lua;' .. ';' ..package.path

package.cpath = ' ./?.so;/home/ahmed/.luarocks/lib/lua/5.1/?.so;/home/ahmed/.luarocks/lib/lua/?.so;/usr/local/lib/x86_64-linux-gnu/tarantool/?.so;/usr/lib/x86_64-linux-gnu/tarantool/?.so;/usr/local/lib/tarantool/?.so;/usr/local/lib/x86_64-linux-gnu/lua/5.1/?.so;/usr/lib/x86_64-linux-gnu/lua/5.1/?.so;/usr/local/lib/lua/5.1/?.so;'..package.cpath

local pretty = require 'pl.pretty'
local function slurp(path)
    print(path)
    local f = io.open(path)
    local s = f:read("*a")
    f:close()
    return s
end
local Spore = require 'Spore'

local defs = slurp("todoapi.json")
local todo = Spore.new_from_string(defs)


todo:enable 'Format.JSON'

local res = todo:list_todos()
if res.status == 200 then   
    for i=0, #res.body do
        local obj = res.body[i]
        print(pretty.dump(obj))
    end
end


local res = todo:view_todo({id=1})
if res.status == 200 then   
    pretty.dump(res.body)
end


-- todo:create_todo{payload={title="new todo awii", done=true}}


local res = todo:update_todo{id=20, payload={title="oufff!", done=false}}
pretty.dump(res.body)


local res = todo:list_todos()
if res.status == 200 then   
    for i=0, #res.body do
        local obj = res.body[i]
        print(pretty.dump(obj))
    end
end

