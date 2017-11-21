package.loaded['socket'] = nil

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




local res = todo:update_todo{id=1, payload={title="oufff!", done=false}}
pretty.dump(res.body)


--todo:create_todo{payload={title="new todo awii", done=true}}
local res = todo:list_todos()
if res.status == 200 then   
    for i=0, #res.body do
        local obj = res.body[i]
        print(pretty.dump(obj))
    end
end

