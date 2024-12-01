library = {}
blockoutlist={}
rednetCompat = false

function library.openAll()
    peripheral.find("modem",function(name,modem)
        modem.open(65490)
        if modem.isWireless() then
            modem.open(65493)
        end
    end)
end
function library.open(modem)
    if modem then
        pModem = peripheral.wrap(modem)
        pModem.open(65490)
        if pModem.isWireless() then
            pModem.open(65493)
        end
        if rednetCompat then
            rednet.open(modem)
        end
    else
        library.openAll()
    end
end
function library.close(modem)
    if modem then
        modem = peripheral.wrap(modem)
        modem.close(65490)
        if modem.isWireless() then
            modem.close(65493)
        end
    else
        library.closeAll()
    end
end
function library.isOpen(modem)
    if modem then
        modem = peripheral.wrap(modem)
        if modem.isOpen(65490) then
            if modem.isWireless() then
                return modem.isOpen(65493)
            else
                return true
            end
        else
            return false
        end
    else
        return library.isAnyOpen()
    end
end
function library.isAnyOpen()
    state = false
    peripheral.find("modem",function(name,modem)
        if library.isOpen(name) then
            state = true
        end
    end)
    return state
end
function library.closeAll()
    peripheral.find("modem",function(name,modem)
        modem.close(65490)
        if modem.isWireless() then
            modem.close(65493)
        end
    end)
end

function library.rednetMode(state)
    if state then
        peripheral.find("modem",function(name,modem)
            if library.isOpen(name) then
                rednet.open(name)
            end
        end)
    else
        rednet.close()
    end
    rednetCompat=state
end

function validatePacket(packet,protocol)--validates the incoming modem messages are uninet packets and ment for this machine to recieve
    if not pcall(function()
        buffer = textutils.serializeJSON(packet)
        textutils.unserializeJSON(buffer)
    end) then
        return false
    end
    required = {"source","destination","data","check","compat"}
    for x=1,#required do
        if packet[required[x]]==nil then
            return false
        end
    end
    for x=1,#blockoutlist do
        if blockoutlist[x]==packet["check"] then
            return false
        end
    end
    if packet["destination"]~=os.getComputerID() and packet["destination"] ~= -1 then
        return false
    end
    if protocol~=nil and packet["protocol"] ~= protocol then
        return false
    end
    return true
end

function validateRednet(packet,protocol)--validates the incoming modem messages are rednet packets and ment for this machine to recieve
    if not pcall(function()
        buffer = textutils.serializeJSON(packet)
        textutils.unserializeJSON(buffer)
    end) then
        return false
    end
    required = {"message","nMessageID","nRecipient","nSender"}
    for x=1,#required do
        if packet[required[x]]==nil then
            return false
        end
    end
    for x=1,#blockoutlist do
        if blockoutlist[x]==packet["nMessageID"] then
            return false
        end
    end
    if packet["nRecipient"]~=os.getComputerID() and packet["nRecipient"] ~= -1 then
        return false
    end
    if protocol~=nil and packet["sProtocol"] ~= protocol then
        return false
    end
    return true
end

function transmit(modem,packet)
    modem.transmit(65490,0,packet)
    if rednetCompat then
        rednetPacket = {
            ["message"] = packet["data"],
            ["nMessageID"] = packet["check"],
            ["nRecipient"] = packet["destination"],
            ["nSender"] = packet["source"],
            ["sProtocol"] = packet["protocol"]
        }
        modem.transmit(packet["destination"]%65500, packet["source"]%65500, rednetPacket)
    end
end

function attemptDirect(id,message)--attempts to find the target computer before needing to forward it to a switch (same as attemptForward on a switch)
    peripheral.find("modem",function(name,modem)
        if message["destination"]==-1 then --broadcasting
            message["from"] = os.getComputerID()
            transmit(modem,message)
        else
            if modem.isWireless() then
                handshakeid = os.startTimer(0.1)
                modem.transmit(65493,id,handshakeid)
                state = true
                while state do
                    event,timerid,channel,_,reply = os.pullEvent()
                    if event=="timer" and timerid==handshakeid then
                        state=false
                        if rednetCompat then
                            rednetPacket = {
                                ["message"] = message["data"],
                                ["nMessageID"] = message["check"],
                                ["nRecipient"] = message["destination"],
                                ["nSender"] = message["source"],
                                ["sProtocol"] = packet["protocol"]
                            }
                            modem.transmit(message["destination"]%65500, message["source"]%65500, rednetPacket)
                        end
                    elseif event=="modem_message" and channel==65494 then
                        if reply==handshakeid then
                            message["from"] = os.getComputerID()
                            transmit(modem,message)
                            return true
                        end
                    end
                end
            else
                terminals = modem.getNamesRemote()
                for y=1,#terminals do
                    if peripheral.hasType(terminals[y],"computer") then
                        if peripheral.wrap(terminals[y]).getID()==id then
                            message["from"] = os.getComputerID()
                            transmit(modem,message)
                            return true
                        end
                    end
                end
            end
        end
    end)
    return false
end

function unicast(reciever,data,protocol)-- the basic sending function all the others build off of
    --packet creation
    packet = {
        ["destination"] = reciever,
        ["source"] = os.getComputerID(),
        ["data"] = data,
        ["protocol"] = protocol,
        ["compat"] = rednetCompat
    }
    packet["check"] = math.random(1,21474833647)

    if not attemptDirect(reciever,packet) then
        peripheral.find("modem",function(name,modem)
            modem.transmit(65491,0,packet)
        end)
    end

    return packet["check"]
end

function library.broadcast(data,protocol)--sends a message with a recipient id of -1, which functions as a broadcast
    check = unicast(-1,data,protocol)
    table.insert(blockoutlist,check)
end

function library.send(reciever,data,protocol)--sends a packet with encapsulated data
    if not library.isOpen() then return false end
    unicast(reciever,data,protocol)
    return true
end

function library.recieve(protocol,timeout)--recieves uninet packets and unencapsulate's them
    if timeout then
        timeoutid = os.startTimer(timeout)
    else
        timeoutid = nil
    end
    while true do
        event,timerid,channel,handshakeid,packet = os.pullEvent()
        if event=="timer" and timeoutid==timerid then
            return nil
        elseif event=="modem_message" then
            if channel==65490 then
                if validatePacket(packet,protocol) then
                    table.insert(blockoutlist,packet["check"])
                    return packet["source"], packet["data"], packet["protocol"]
                end
            elseif channel==os.getComputerID() and rednetCompat then
                if validateRednet(packet,protocol) then
                    table.insert(blockoutlist,packet["nMessageID"])
                    return packet["nSender"], packet["message"], packet["sProtocol"]
                end
            elseif channel==65493 then
                if handshakeid==os.getComputerID() then
                    peripheral.wrap(timerid).transmit(65494,0,packet)
                end
            end
        end
    end
end

return library
