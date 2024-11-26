output = {}
blockoutlist={}

function openAll()
    peripheral.find("modem",function(name,modem)
        modem.open(65490)
        if modem.isWireless() then
            modem.open(65493)
        end
    end)
end
function open(modem)
    modem = peripheral.wrap(modem)
    modem.open(65490)
    if modem.isWireless() then
        modem.open(65493)
    end
end
function close(modem)
    modem = peripheral.wrap(modem)
    modem.close(65490)
    if modem.isWireless() then
        modem.close(65493)
    end
end
function closeAll()
    peripheral.find("modem",function(name,modem)
        modem.close(65490)
        if modem.isWireless() then
            modem.close(65493)
        end
    end)
end

function validatePacket(packet,protocol)--validates the incoming modem messages are uninet packets and ment for this machine to recive
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

function output.broadcast(data,protocol)--sends a message with a recipient id of -1, which functions as a broadcast
    packet = {
        ["destination"] = -1,
        ["source"] = os.getComputerID(),
        ["age"] = 10,
        ["data"] = data,
        ["protocol"] = protocol
    }
    
    packet["check"] = tostring(packet)
    table.insert(blockoutlist,packet["check"])

    peripheral.find("modem",function(name,modem)
        modem.transmit(65491,0,packet)
    end)
end

function output.send(reciver,data,protocol)--sends a packet with encapsulated data
    packet = {
        ["destination"] = reciver,
        ["source"] = os.getComputerID(),
        ["age"] = 10,
        ["type"] = "beta",
        ["data"] = data,
        ["protocol"] = protocol
    }
    
    packet["check"] = tostring(packet)

    peripheral.find("modem",function(name,modem)
        modem.transmit(65491,0,packet)
    end)
end

function output.recive(protocol,timeout)--recives uninet packets and unencapsulate's them
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

openAll()
return output