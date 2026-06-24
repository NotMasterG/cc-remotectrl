local args = {...}

local mode = args[1]
local modemSide = args[2]
local name = args[3]
local password = args[4]

if not modemSide or not mode or not name or not password then
    print("Usage:")
    print("Host: rctrl host <modem> <name> <pass>")
    print("Exe: rctrl exe <modem> <name> <pass> <cmd>")
    return
end

rednet.open(modemSide)

local PROTOCOL = "rctrl"

--
-- HOST MODE
--
if mode == "host" then

    rednet.host(PROTOCOL, name)
    print("Hosting as: " .. name)

    while true do
        local sender, msg = rednet.receive(PROTOCOL)

        if type(msg) ~= "table" then goto continue end
        if not msg.n or not msg.p then
            rednet.send(sender, {
                k = false,
                o = "Something went wrong"
            }, PROTOCOL)
            goto continue
        end
        if msg.n ~= name then goto continue end

        if msg.p ~= password then
            rednet.send(sender, {
                k = false,
                o = "Wrong password"
            }, PROTOCOL)
            goto continue
        end

        -- capture output safely using window
        local w, h = term.getSize()
        local win = window.create(term.current(), 1, 1, w, h)
        local old = term.redirect(win)

        local ok, err = pcall(function()
            shell.run(msg.c)
        end)

        term.redirect(old)

        -- extract buffer
        local buffer = {}

        for y = 1, h do
            win.setCursorPos(1, y)
            local line = win.getLine and win.getLine(y) or ""
            buffer[#buffer+1] = line
        end

        rednet.send(sender, {
            k = ok,
            o = table.concat(buffer, "\n"),
            e = err
        }, PROTOCOL)

        ::continue::
    end

-------------------------------------------------------
-- CONNECT MODE
-------------------------------------------------------
elseif mode == "exe" then

    local command = table.concat(args, " ", 5)

    if command == "" then
        print("No command provided")
        return
    end

    rednet.broadcast({
        n = name,
        p = password,
        c = command
    }, PROTOCOL)

    local sender, resp = rednet.receive(PROTOCOL, 10)

    if not resp then
        print("Timed out")
        return
    end

    if resp.k then
        print(resp.o)
    else
        print("ERROR: " .. tostring(resp.o or resp.e))
    end

else
    print("Choose mode: host/exe")
end