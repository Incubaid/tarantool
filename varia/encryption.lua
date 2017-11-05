--https://github.com/philanc/luatweetnacl/

nacl=require("luatweetnacl")

q=string.rep("a",24)
q2=string.rep("b",32)

tdata="test"

r=nacl.secretbox(tdata,q,q2)
result=nacl.secretbox_open(r,q,q2)

print (result)

-- print result=tdata
