local user = require "User_capnp"
local capnp = require "capnp"

-- serialize user data to capnproto 
function serialize_user(id, name)
	local data = {
		id = id,
		name = name,
	}
	return user.User.serialize(data)
end

-- parse capnproto to object
function parse_user(bin)
	return user.User.parse(bin)
end


