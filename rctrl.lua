local G={...}local N,P=G[3],G[4]if not P then
print("Usage:\nrctrl host <modem> <name> <pass>\nrctrl exe <modem> <name> <pass> <cmd>")return end
rednet.open(G[2])local
L="rctrl"if G[1]=="host"then
rednet.host(L,N)print("Hosting as: "..N)while 1 do
local s,m = rednet.receive(L)if
type(m)~="table"then goto C end
if not m.n or not m.p then
rednet.send(s,{k=false,o="Something went wrong"},L)goto C end
if m.n~=N then goto C end if m.p~=P then
rednet.send(s,{k=false,o="Wrong password"},L)goto C end
local w,h=term.getSize()local
W=window.create(term.current(),1,1,w,h)local
o=term.redirect(W)local
k,e=pcall(function()shell.run(m.c)end)term.redirect(o)local
B={}for y=1,h do W.setCursorPos(1,y)B[#B+1]=W.getLine(y)end
rednet.send(s,{k=k,o=table.concat(B,"\n"),e=e},L)::C::end
elseif G[1]=="exe"then
c=table.concat(G," ",5)if c==""then
print("No command provided");return end
rednet.broadcast({n=N,p=P,c=c},L)local s,r=rednet.receive(L,10)if
not r then print("Timed out")return end
print(r.k and r.o or"ERR: "..tostring(r.o or r.e))else
print("Choose mode: host/exe")end