# UniNet-Computer Craft
A lightweight networking solution for computer craft.

UniNet is a very flexible, versatile, and reliable alternative to rednet. generally it allows you to control the flow of data, connect networks, and monitor traffic.

## Installation
To download the client use `wget https://raw.githubusercontent.com/redtoast/UniNet-CC/refs/heads/main/uninet.lua`

To download switch software use `wget run https://pinestore.cc/d/125`

## Client
The UniNet client is very similar to rednet from an API perspective.

Uninet has the exact same sweet of functions as rednet **EXEPT** for host(), unhost(), lookup(), and run().
Uninet also includes openAll() and closeAll() for QOL

## Switch
A switch in networks refers to a machine that forwards data between networks and form bigger networks, in Uni that means connecting wired and wireless networks to other wired or wireless networks.

simply attach modems to the switch to add that network to switch, connecting multible switches can make your networks even bigger.

## Firewall

you can code your own firewalls to filter, modify, or just block packets of traffic traveling through switches.

the firewalls can be made with ease, you can use specific criteria provided by the switch to filter through traffic, or even overwrite it.
a all encompassing example for learning how to make firewalls is `firewall_examples/default_firewall_example.lua`
