output = {}
blockoutlist={}

function output.openAll()
    peripheral.find("modem",function(name,modem)
        modem.open(65490)
        if modem.isWireless() then
            modem.open(65493)
        end
    end)
end
function output.open(modem)
    if modem then
        modem = peripheral.wrap(modem)
        modem.open(65490)
        if modem.isWireless() then
            modem.open(65493)
        end
    else
        output.openAll()
    end
end
function output.close(modem)
    if modem then
        modem = peripheral.wrap(modem)
        modem.close(65490)
        if modem.isWireless() then
            modem.close(65493)
        end
    else
        output.closeAll()
    end
end
function output.isOpen(modem)
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
        return output.isAnyOpen()
    end
end
function output.isAnyOpen()
    state = false
    peripheral.find("modem",function(name,modem)
        if output.isOpen(name) then
            state = true
        end
    end)
    return state
end
function output.closeAll()
    peripheral.find("modem",function(name,modem)
        modem.close(65490)
        if modem.isWireless() then
            modem.close(65493)
        end
    end)
end

function validatePacket(packet,protocol)--validates the incoming modem messages are uninet packets and ment for this machine to recieve
    if not pcall(function()
        buffer = textutils.serializeJSON(packet)
        textutils.unserializeJSON(buffer)
    end) then
        return false
    end
    required = {"age","source","destination","data","check"}
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
    if packet["destination"]~=os.getComputerID() and packet["destination"] ~= 0 then
        return false
    end
    if protocol~=nil and packet["protocol"] ~= protocol then
        return false
    end
    return true
end

function attemptDirect(id,message)--attempts to find the target computer before needing to forward it to a switch (same as attemptForward on a switch)
    peripheral.find("modem",function(name,modem)
        if message["destination"]==-1 then --broadcasting
            packetsSent = packetsSent + 1
            message["from"] = os.getComputerID()
            modem.transmit(65490,0,message)
        else
            if modem.isWireless() then
                handshakeid = os.startTimer(0.1)
                modem.transmit(65493,id,handshakeid)
                state = true
                while state do
                    event,timerid,channel,_,reply = os.pullEvent()
                    if event=="timer" and timerid==handshakeid then
                        state=false
                    elseif event=="modem_message" and channel==65494 then
                        if reply==handshakeid then
                            message["from"] = os.getComputerID()
                            modem.transmit(65490,0,message)
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
                            modem.transmit(65490,0,message)
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
        ["age"] = 10,
        ["type"] = "beta",
        ["data"] = data,
        ["protocol"] = protocol
    }
    packet["check"] = tostring(packet)

    if not attemptDirect(reciever,packet) then
        peripheral.find("modem",function(name,modem)
            modem.transmit(65491,0,packet)
        end)
    end

    return packet["check"]
end

function output.broadcast(data,protocol)--sends a message with a recipient id of -1, which functions as a broadcast
    check = unicast(-1,data,protocol)
    table.insert(blockoutlist,check)
end

function output.send(reciever,data,protocol)--sends a packet with encapsulated data
    if not output.isOpen() then return false end
    unicast(reciever,data,protocol)
    return true
end

function output.recieve(protocol,timeout)--recieves uninet packets and unencapsulate's them
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
                    return packet["source"],packet["data"]
                end
            elseif channel==65493 then
                if handshakeid==os.getComputerID() then
                    peripheral.wrap(timerid).transmit(65494,0,packet)
                end
            end
        end
    end
end

return output
