firewall = {} --the table that will contain the firewall

-- THE FIREWALL WILL ONLY LOAD IF IT IS RENAMED 'firewall.lua'

function firewall.ingress(data, packet) -- the ingress is the function that filters in *INCOMING* traffic
    -- the data parameter contains a table of useful data about the packet
        -- .port : the name of the modem that the packet can in from
        -- .sender : the computer id that sent the packet
        -- .recipient : the id of the reciving computer
        -- .protocol : the 'protocol' of the packet
        -- .from : the last computer that interacted with this packet (sender/switch)
    -- the packet parameter is the data that the packet is carrying (the  contents of the packet)

    log("i just recieved a packet") -- the log function prints to the switch's log.txt (if it has one)

    return true
    -- a firewall function returning nothing or true will allow the packet to go through with no change
    -- returning false will block the packet
    -- returning anything else will overwrite the contents of the packet before sending it
end

function firewall.egress(data, packet) -- egress functon is what filters *OUTGOING* traffic
    -- the data parameter of the egress function also contains a .wandering
        -- wandering is true if the packet is being flooded out of all ports in a attempt to find other switchs to deliver the packet
        -- this only happens if the switch cant find the packets recipient
        -- wandering is false if the switch has found its recipient and is sending the packet to it
        -- a switch will both send a packet as if it has found a recipient and flood it to other switches if the packet is a broadcast

    log("i just vomited a packet into other computers")

    -- the function ending without returning anything counts as the packet being approved
end

return firewall
