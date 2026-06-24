local args = {...}
local PROTOCOL = "sctrl"

local mode = args[1]
local modemSide = args[2]
local name = args[3]
local cmd = args[4]

if not modemSide or not mode or not name then
    print("Usage:")
    print("Host: sctrl host <modem> <name> <useRctrl:t/f>")
    print("Exe: sctrl exe <modem> <name> <cmd>")
    return
end

if args[4] == "t" then PROTOCOL = "rctrl" end

write("Password: ")
local password = read("*")

rednet.open(modemSide)

--------------------------------------------------
-- simple hash (not crypto-secure, but fine for CC)
--------------------------------------------------
local function hash(str)
    local h = 0
    for i = 1, #str do
        h = (h * 31 + string.byte(str, i)) % 2^32
    end
    return tostring(h)
end

local function randomNonce()
    return tostring(math.random(100000, 999999)) .. tostring(os.epoch("utc"))
end

--------------------------------------------------
-- HOST
--------------------------------------------------
if mode == "host" then

    rednet.host(PROTOCOL, name)
    print("Hosting as " .. name)
    print("Protocol: " .. PROTOCOL)

    local pending = {} -- sender -> nonce

    while true do
        local sender, msg = rednet.receive(PROTOCOL)

        if type(msg) ~= "table" then goto continue end

        --------------------------------------------------
        -- INIT (new clients)
        --------------------------------------------------
        if msg.t == 0 then
            if msg.n ~= name then goto continue end
            local nonce = randomNonce()
            pending[sender] = nonce

            rednet.send(sender, {
                t = 1,
                g = nonce
            }, PROTOCOL)

        --------------------------------------------------
        -- AUTH (new clients)
        --------------------------------------------------
        elseif msg.t == 2 then

            local nonce = pending[sender]
            pending[sender] = nil

            if not nonce then
                rednet.send(sender, {
                    k = false,
                    o = "Handshake failure"
                }, PROTOCOL)
                goto continue
            end

            local expected = hash(password .. nonce)

            if msg.a ~= expected then
                rednet.send(sender, {
                    k = false,
                    o = "Auth failed"
                }, PROTOCOL)
                goto continue
            end

            -- run command safely
            local win = window.create(term.current(), 1, 1, term.getSize())
            local old = term.redirect(win)

            local ok, err = pcall(function()
                shell.run(msg.c)
            end)

            term.redirect(old)

            local buffer = {}
            for y = 1, select(2, win.getSize()) do
                local line = win.getLine and win.getLine(y) or ""
                buffer[#buffer+1] = line
            end

            rednet.send(sender, {
                k = ok,
                o = table.concat(buffer, "\n"),
                e = err
            }, PROTOCOL)

        --------------------------------------------------
        -- LEGACY rctrl SUPPORT
        --------------------------------------------------
        elseif msg.n and msg.p and msg.c and args[4] == "t" then

            local win = window.create(term.current(), 1, 1, term.getSize())
            local old = term.redirect(win)

            local ok, err = pcall(function()
                shell.run(msg.c)
            end)

            term.redirect(old)

            local buffer = {}
            for y = 1, select(2, win.getSize()) do
                buffer[#buffer+1] = win.getLine and win.getLine(y) or ""
            end

            rednet.send(sender, {
                k = ok,
                o = table.concat(buffer, "\n"),
                e = err
            }, PROTOCOL)
        end

        ::continue::
    end

--------------------------------------------------
-- CLIENT
--------------------------------------------------
elseif mode == "exe" then

    local command = table.concat(args, " ", 4)

    if command == "" then
        print("No command")
        return
    end

    -- broadcast init on sctrl then rctrl
    rednet.broadcast({
        t = 0,
        n = name
    }, PROTOCOL)


    local sender, resp = rednet.receive(PROTOCOL, 5)
    if not resp then
        print("sctrl failed, searching rctrl")
        PROTOCOL = "rctrl"
        rednet.broadcast({
            t = 0,
            n = name
        })
        sender, resp = rednet.receive(PROTOCOL, 5)
        if not resp then
            print("Host not found")
            return
        end
    end
    
    if resp.t ~= 1 then
        print("Handshake failure")
        return
    end

    local auth = hash(password .. resp.g)

    rednet.send(sender, {
        t = 2,
        a = auth,
        c = command
    }, PROTOCOL)

    local _, result = rednet.receive(PROTOCOL, 10)

    if not result then
        print("Timeout")
        return
    end

    if result.k then
        print(result.o)
    else
        print("ERROR: " .. tostring(result.o or result.e))
    end
end
