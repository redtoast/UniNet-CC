ports = table.pack( peripheral.find("modem") )
blockoutlist={}

--stats, cleanly dumped into global with no care or concern
wireless = false
wired = false
packetsRecieved=0
packetsForwarded=0
packetsSent=0
disregardedpackets=0
badPackets=0
garbageIngress=0
errors=0
FWIblocked=0
FWEblocked=0
FWmodified=0
FWerrors=0

function printConsole()
    --hooks up to switchGUI.lua to draw screen
    if not pcall(function()
        display = require("switchGUI")
    end) then
        errors = errors + 1
        return nil
    end
    if display~=false then
        display.switchDisplay({
            --i hate this as much as you do
            ["wireless"]=wireless,
            ["wired"]=wired,
            ["packetsRecieved"]=packetsRecieved,
            ["packetsForwarded"]=packetsForwarded,
            ["packetsSent"]=packetsSent,
            ["badPackets"]=badPackets,
            ["garbageIngress"]=garbageIngress,
            ["errors"]=errors,
            ["disregardedpackets"]=disregardedpackets,
            ["FWIblocked"]=FWIblocked,
            ["FWEblocked"]=FWEblocked,
            ["FWmodified"]=FWmodified,
            ["FWerrors"]=FWerrors,
            ["isFirewall"]=pcall(function() require("firewall") end)
        })
    end
end

function openPorts()
    for x=1,#ports do
        ports[x].open(65491)
        ports[x].open(65492)
        if ports[x].isWireless() then
            wireless = true
            ports[x].open(65498) --port open for wireless discovery handshake
        else
            wired = true
        end
    end
end

function _G.log(text)--jank ass log function to be used in firewall's
    if fs.exists("/log.txt") then
        fs.open("/log.txt","a").write("Firewall: "..tostring(text).."\n")
    end
end

function firewallInterface(packet,egress,port,flood)--hooks up to firewall files and marionette's them into working somehow
    if not pcall(function()
        require("firewall")
    end) then
        return nil
    end
    firewall = require("firewall")
    if firewall~=false then
        turnout = nil
        iserror, error = pcall(function()
            if egress then
                if firewall.egress then
                    data = {
                        ["port"] = port,
                        ["sender"] = packet["source"],
                        ["recipient"] = packet["destination"],
                        ["protocol"] = packet["protocol"],
                        ["from"] = packet["from"] or packet["source"],
                        ["wandering"] = flood
                    }
                    turnout = firewall.egress(data,packet["data"])
                    if turnout==false then
                        FWEblocked = FWEblocked + 1
                    end
                end
            else
                if firewall.ingress then
                    data = {
                        ["port"] = port,
                        ["sender"] = packet["source"],
                        ["recipient"] = packet["destination"],
                        ["protocol"] = packet["protocol"],
                        ["from"] = packet["from"] or packet["source"]
                    }
                    turnout = firewall.ingress(data,packet["data"])
                    if turnout==false then
                        FWIblocked = FWIblocked + 1
                    end
                end
            end
        end)
        if iserror then
            return turnout
        else
            if fs.exists("/log.txt") then
                fs.open("/log.txt","a").write("Firewall error: "..error.."\n")
            end
            FWerrors = FWerrors + 1
        end
    end
end

function validatePacket(packet,port)--filters incomming modem messages to ensure that their valid uninet packets
    if not pcall(function()
        buffer = textutils.serializeJSON(packet)
        textutils.unserializeJSON(buffer)
    end) then
        garbageIngress = garbageIngress + 1
        return false
    end
    required = {"age","source","destination","data","check"}
    for x=1,#required do
        if packet[required[x]]==nil then
            badPackets = badPackets + 1
            return false
        end
    end
    if packet["age"]==0 then
        disregardedpackets = disregardedpackets + 1
        return false
    end
    for x=1,#blockoutlist do
        if blockoutlist[x]==message["check"] then
            disregardedpackets = disregardedpackets + 1
            return false
        end
    end
    firewall = firewallInterface(message,false,port)
    if firewall==true or firewall==nil then
        return true, message
    elseif firewall ~= false then
        message["data"] = firewall
        FWmodified = FWmodified + 1
        return true, message
    else
        disregardedpackets = disregardedpackets + 1
        return false
    end
end

function attemptForward(id,message)--attemps to find destination computer for packets, returns false if cant
    for x=1, #ports do
        if message["destination"]==-1 then --broadcasting
            packetsSent = packetsSent + 1
            firewall = firewallInterface(message,true,peripheral.getName(ports[x]),false)
            if firewall==true or firewall==nil then
                message["from"] = os.getComputerID()
                ports[x].transmit(65490,0,message)
            elseif firewall ~= false then
                message["data"] = firewall
                FWmodified = FWmodified + 1
                message["from"] = os.getComputerID()
                ports[x].transmit(65490,0,message)
            end
        else
            if ports[x].isWireless() then
                --handshakeid = os.startTimer(0.5)
                --print(handshakeid)
                --ports[x].transmit(65493,id,handshakeid)
                --state = true
                --while state do
                --    event,timerid,channel,_,reply = os.pullEvent()
                --    if event=="timer" and timerid==handshakeid then
                --        state=false
                --    elseif event=="modem_message" and channel==65494 then
                --        if reply==handshakeid then
                --            firewall = firewallInterface(message,true,peripheral.getName(ports[x]),false)
                --            if firewall==true or firewall==nil then
                --                message["from"] = os.getComputerID()
                --                ports[x].transmit(65490,0,message)
                --            elseif firewall ~= false then
                --                message["data"] = firewall
                --                FWmodified = FWmodified + 1
                --                message["from"] = os.getComputerID()
                --                ports[x].transmit(65490,0,message)
                --            end
                --            return true
                --        end
                --    end
                --end
                --this is a terrible patch half ass bitch fuck solution to a problem i can fix LATER
                firewall = firewallInterface(message,true,peripheral.getName(ports[x]),false)
                if firewall==true or firewall==nil then
                    message["from"] = os.getComputerID()
                    ports[x].transmit(65490,0,message)
                elseif firewall ~= false then
                    message["data"] = firewall
                    FWmodified = FWmodified + 1
                    message["from"] = os.getComputerID()
                    ports[x].transmit(65490,0,message)
                end
            else
                terminals = ports[x].getNamesRemote()
                for y=1,#terminals do
                    if peripheral.hasType(terminals[y],"computer") then
                        if peripheral.wrap(terminals[y]).getID()==id then
                            firewall = firewallInterface(message,true,peripheral.getName(ports[x]),false)
                            if firewall==true or firewall==nil then
                                message["from"] = os.getComputerID()
                                ports[x].transmit(65490,0,message)
                            elseif firewall ~= false then
                                message["data"] = firewall
                                FWmodified = FWmodified + 1
                                message["from"] = os.getComputerID()
                                ports[x].transmit(65490,0,message)
                            end
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

function floodPorts(message,ageing)--if attemptForward fails just shoot the packet at other switchs and hope for the best
    if message["age"]<=1 then
        return nil
    end
    if ageing then
        message["age"]=-1
    end
    for x=1,#ports do
        if not ports[x].isWireless() then
            firewall = firewallInterface(message,true,peripheral.getName(ports[x]),true)
            if firewall==true or firewall==nil then
                message["from"] = os.getComputerID()
                ports[x].transmit(65490,0,message)
            elseif firewall ~= false then
                message["data"] = firewall
                FWmodified = FWmodified + 1
                message["from"] = os.getComputerID()
                ports[x].transmit(65490,0,message)
            end
        end
    end
end

function main()--main loop for reciving and processing
    while true do
        printConsole()
        _,ingress,channel,_,message = os.pullEvent("modem_message")
        valid, packet = validatePacket(message, ingress)
        if valid then
            if channel == 65491 then
                table.insert(blockoutlist,packet["check"])
                packetsRecieved = packetsRecieved + 1
                if attemptForward(packet["destination"],packet) then
                    packetsSent = packetsSent + 1
                else
                    packetsForwarded = packetsForwarded + 1
                    floodPorts(packet,false)
                end
            elseif channel == 65492 then
                table.insert(blockoutlist,packet["check"])
                packetsRecieved = packetsRecieved + 1
                if attemptForward(packet["destination"],packet) then
                    packetsSent = packetsSent + 1
                else
                    packetsForwarded = packetsForwarded + 1
                    floodPorts(packet,true)
                end
            end
        end
    end
end

openPorts()
printConsole()
while true do --switch wide error handling
    isnterror, error = pcall(main)
    if  isnterror then
        break
    else
        if error ~= "Terminated" then
            if fs.exists("/log.txt") then
                fs.open("/log.txt","a").write("Switch error: "..error.."\n")
            end
            errors = errors + 1
        else
            if pcall(function()
                display = require("diviceDisplay")
            end) then
                term.setBackgroundColor(colors.black)
                term.setTextColour(colors.white)
                term.clear()
                term.setCursorPos(1,1)
                print("Switch closed!")
            end
            break
        end
    end
end
