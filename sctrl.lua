local G,L,S,N={...},"sctrl",G[2],G[3]if not N then
print("Usage:\nsctrl host <modem> <name> <rctrl?:-/t>\nsctrl exe <modem> <name> <cmd>")return end
if G[4]=="t"then L="rctrl"end
write("Password: ")local
P=read("*")rednet.open(S)local
function H(s)local h=0 for i=1,#s do
h=(h*31+string.byte(s,i))%2^32
end return tostring(h)end local function N()return
tostring(math.random(10^6,10^7-1))..tostring(os.epoch("utc"))end
if G[1]=="host"then
rednet.host(L,N)print("Hosting as "..N.."\nProtocol: "..L)local
E={}while 1 do local s,m=rednet.receive(L)local
W=window.create(term.current(),1,1,term.getSize())if
type(m)~="table"then goto C end
if m.t==0 then if m.n~=N then goto C
end local n=N()E[s]=n
rednet.send(s,{t=1,g=n},L)elseif m.t==2 then
local n=E[s]E[s]=nil if not n then
rednet.send(s,{k=false,o="Handshake failure"},L)goto C end
local x=H(P..n)if m.a~=x then
rednet.send(s,{k=false,o="Auth failed"},L)goto C end 
local d=term.redirect(W)local
k,e=pcall(function()shell.run(m.c)end)term.redirect(d)local
B={}for y=1,select(2,W.getSize())do
B[#B+1]=W.getLine(y)end
rednet.send(s,{k=k,o=table.concat(B,"\n"),e=e},L)elseif
m.p and m.c and G[4]=="t"then if m.n~=N then goto C end    
local d=term.redirect(W)local
k,e=pcall(function()shell.run(m.c)end)term.redirect(d)local
B={}for y=1,select(2,W.getSize())do B[#B+1]=W.getLine(y)end
rednet.send(s,{k=k,o=table.concat(B,"\n"),e=e},L)end::C::end
elseif G[1]=="exe"then local c=table.concat(G," ",4)if
c==""then print("No command")return end
rednet.broadcast({t=0,n=N},L)local
s,r=rednet.receive(L,3)if not r then
print("sctrl failed, using rctrl")L="rctrl"rednet.broadcast({t=0,n=N},L)s,r=rednet.receive(L,4)if
not r then print("Host not found")return end end
if r.t~=1 then print("Handshake failure")return end
rednet.send(s,{t=2,a=H(P..r.g),c=c},L)
local _,R=rednet.receive(L,5)if
not R then print("Timeout")return end
print(R.k and R.o or"ERR: "..tostring(R.o or R.e))else
print("Choose mode: host/exe")end