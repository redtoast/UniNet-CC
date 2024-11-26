print("Please select software to download")
print("    1:UniNet client")
print("    2:Switch base")
print("    3:Switch + display")
term.write("> :")
term.setCursorBlink(true)
_,key = os.pullEvent("char")
term.setCursorBlink(false)
if key == "1" then
    print("1")
    shell.run("wget https://raw.githubusercontent.com/redtoast/UniNet-CC/refs/heads/main/uninet.lua")
elseif key == "2" then
    print("2")
    if not fs.exists("startup.lua") then
        print("Create startup file [Y/N]")
        while true do
            _,key = os.pullEvent("char")
            if key=="y" then
                print("startup created!")
                fs.open("startup.lua","w").write("shell.run(\"switch.lua\")")
                break
            elseif key=="n" then
                break
            end
        end
    end
    fs.open("log.txt","w").write("<epic log>")
    shell.run("wget https://raw.githubusercontent.com/redtoast/UniNet-CC/refs/heads/main/switch.lua")
elseif key == "3" then
    print("3")
    if not fs.exists("startup.lua") then
        print("Create startup file [Y/N]")
        while true do
            _,key = os.pullEvent("char")
            if key=="y" then
                print("startup created!")
                fs.open("startup.lua","w").write("shell.run(\"switch.lua\")")
                break
            elseif key=="n" then
                break
            end
        end
    end
    fs.open("log.txt","w").write("<epic log>")
    shell.run("wget https://raw.githubusercontent.com/redtoast/UniNet-CC/refs/heads/main/switch.lua")
    shell.run("wget https://raw.githubusercontent.com/redtoast/UniNet-CC/refs/heads/main/switchGUI.lua")
else
    print("skipped download")
end
