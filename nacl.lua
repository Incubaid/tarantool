local nacl = require("luatweetnacl")

sender_pub, sender_secret = nacl.box_keypair()
reciever_pub, reciever_secret = nacl.box_keypair()

-------- BOX -----------

-- encrypt:
nonce = nacl.randombytes(24)
encrypted = nacl.box("plain text", nonce, reciever_pub, sender_secret)

print("encryted:")
print(encrypted)
print()

-- decrypt:
decrypted = nacl.box_open(encrypted, nonce, sender_pub, reciever_secret)

print("decrypted")
print(decrypted)
print()


------- SECRET BOX ------

-- encrypt
nonce = nacl.randombytes(24)
key = nacl.randombytes(32)
sb_encrypted = nacl.secretbox("plain text", nonce, key)

print("secret box encrypted:")
print(sb_encrypted)
print()

-- decrypt
sb_decrypted = nacl.secretbox_open(sb_encrypted, nonce, key)

print("secret box decrypted")
print(sb_decrypted)
print()



---------- SIGNING -----------

--- sign
pk, sk = nacl.sign_keypair()
signed = nacl.sign("text to sign", sk)

print("signed:")
print (signed)
print()

-- verify
verified = nacl.sign_open(signed, pk)

print("verified")
print (verified)
print()
