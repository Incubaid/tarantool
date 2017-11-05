-- this file demonstrate a way to do public key encryption in Lua
local rsa = require("rsa")

-- loading public & private key pem
local pub_key_pem = io.open("public.pem", "r"):read("*all")
local priv_key_pem = io.open("private.pem", "r"):read("*all")

-- create public key instance
local pub, err = rsa:new({ public_key = pub_key_pem })
if not pub then
	print("new rsa err: ", err)
	return
end


-- encrypt
local encrypted, err = pub:encrypt("hello")
if not encrypted then
	print("failed to encrypt: ", err)
	return
    
end

print("encrypted length: ", #encrypted)

-- create private key instance
local priv, err = rsa:new({ private_key = priv_key_pem })
if not priv then
	print("new rsa err: ", err)
	return
end

-- decrypt
local decrypted = priv:decrypt(encrypted)

-- make sure the decrypted message is the same as original message
print(decrypted == "hello")
