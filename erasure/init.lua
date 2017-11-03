box.cfg{}

local function init(n)
	local base = "jer_"
	for i=1, n do
		local name = base .. i
		print("space name = ", name)
		local s = box.schema.space.create(name, {engine='sophia', if_not_exists=true})
		s:create_index('primary', {parts = {1, 'STR'}})
	end
end

init(12)
