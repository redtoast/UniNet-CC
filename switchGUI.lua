o={}

function o.switchDisplay(data)
    colored = multishell~=nil
    if colored then
        term.setBackgroundColor(colors.lightGray)
    else
        term.setBackgroundColor(colors.white)
    end
    term.clear()
    term.setCursorPos(1,1)
    if not colored then
        term.blit("UniSwitch:","0008888888","ffffffffff")
        term.setBackgroundColor(colors.black)
        term.setTextColour(colors.lightGray)
        term.write(os.getComputerID())
        term.setBackgroundColor(colors.gray)
        term.setTextColour(colors.white)
    else
        term.blit("UniSwitch:","777fffffff","1111111111")
        term.setBackgroundColor(colors.orange)
        term.setTextColour(colors.black)
        term.write(os.getComputerID())
        term.setBackgroundColor(colors.lightBlue)
    end
    print()
    --connection type text (uteraly useless but cool)
    if data["wired"] and data["wireless"] then
        print("Wired & Wireless connection")
    elseif data["wired"] then
        print("Wired connection")
    elseif data["wireless"] then
        print("Wireless connection")
    else
        print("No connection")
    end
    --number stats
    if colored then
        term.setBackgroundColor(colors.green)
        print("Traffic Data:")
        term.setBackgroundColor(colors.lime)
    else
        term.setBackgroundColor(colors.black)
        print("Traffic Data:")
        term.setBackgroundColor(colors.gray)
    end
    print("Packets recieved by switch: "..data["packetsRecieved"])
    print("Packets sent to clients: "..data["packetsSent"])
    print("Packets forwarded to other switches: "..data["packetsForwarded"])
    if colored then
        term.setBackgroundColor(colors.red)
        print("Issue/error statistics:")
        term.setBackgroundColor(colors.yellow)
    else
        term.setBackgroundColor(colors.black)
        print("Issue/error statistics:")
        term.setBackgroundColor(colors.gray)
    end
    print("Disregarded packets: "..data["disregardedpackets"])
    print("Garbage packets: "..data["garbageIngress"])
    print("Malformed packets: "..data["badPackets"])
    print("System errors caught: "..data["errors"])
    --firewall stats
    if data.isFirewall then
        if colored then
            term.setBackgroundColor(colors.purple)
            print("Firewall statistics:")
            term.setBackgroundColor(colors.pink)
        else
            term.setBackgroundColor(colors.black)
            print("Firewall statistics:")
            term.setBackgroundColor(colors.gray)
        end
        print("Ingress blocked: "..data["FWIblocked"])
        print("Egress blocked: "..data["FWEblocked"])
        print("Packets modified: "..data["FWmodified"])
        print("Firewall errors: "..data["FWerrors"])
    else
        if colored then
            term.setBackgroundColor(colors.purple)
            print("NO FIREWALL LOADED")
        else
            term.setBackgroundColor(colors.black)
            print("NO FIREWALL LOADED")
        end
    end
end

return o