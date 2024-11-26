firewall = {} --the table that will contain the firewall

blockedPorts = {--these are the ports we will block broadcasts from leaving
    "bottom",
    "back"
}

function firewall.egress(data)--we use the egress function to catch the packet on its way out of the switch
    if data["recipient"]==-1 then--broadcast packets always have their recipient set to -1
        for x=1, #blockedPorts do
            if data.port == blockedPorts[x] then--we use the port info stored in the first argument to determine the port the packet is trying to leave
                return false --returning false will stop the packet from forwarding
            end
        end
    end
    --not returning anything counts as the packet passing the firewall so we can just let the function end on its own
end

return firewall
