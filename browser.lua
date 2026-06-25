local G={...}
local site=G[1]


local function P(I)local
o,i,n={},1,#I local function
T(s)local b=""while i<=n do
local c=I:sub(i,i)if c=="$"then 
b=b..I:sub(i+1,i+1)i=i+2
elseif c==s then break else
b=b..c i=i+1 end end return b end
while i<=n do local c=I:sub(i,i)if
c=="%"then i=i+1 local a=T("?")i=i+1 local
t=T("%")table.insert(o,{t=1,l=a,x=t})i=i+1
else table.insert(o,{t=0,x=T("%")})end
end return o end

local function render(t,d)
    --term.clear()
    --term.setCursorPos(1, 1)
    print(t.."\n")

    local w,h=50,10--term.getSize()
    local y=3

    for _,v in ipairs(d)do
        if y>h then break end

        if v.t==0 then io.write(v.x)end

        if v.t==1 then
            --term.setTextColor(colors.blue)
            io.write(v.x)
            --term.setTextColor(colors.white)
        end

        y=y+1
    end
end



local function dump(t,n)n=n or 0
local p=string.rep(" ",n)for
k,v in pairs(t)do
if type(v)=="table"then
print(p..tostring(k)..":")dump(v,n+2)else
print(p..tostring(k)..": "..tostring(v))end
end end
local tst = "$?test string$%$ %addr.ff?link$% hopeitworkz%$? lets see also \\ $\n \n hm$?"
dump(P(tst))
print("\n\n")
render(site or"Home",P(tst))
