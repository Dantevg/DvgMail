--[[
      DvgMail client
      by DvgCraft
      Mail server, dvg API, cctf API and
      advanced computer required
      
      DATE  16-07-2015
]]--

-- Variables
local version = "1.0.1"
local inMain = true
local inInbox = false
local composing = false
local settings = {}
local mail = {}
local selected = 1

sides = {"right", "left", "top", "bottom", "back", "front"}

-- Menu functions
function stop()
  term.setTextColor(colors.white)
  term.setBackgroundColor(colors.black)
  inMain = false
  inInbox = false
  shell.run("clear")
end
function toMain()
  inInbox = false
  inMain = true
  main()
end

local inboxMenu = {
  [1] = {txt = "  X ",    func = toMain},
}

function readMail()
  inInbox = false
  mail = {}
  rednet.send(tonumber(settings.serverID), inboxMenu[selected].txt, "DVG_MAIL_MAIL_REQUEST")
  id, msg, code = rednet.receive("DVG_MAIL_MAIL_ANSWER", 10)
  if type(msg) == "string" and msg:sub(1,8) == "DVG_FAIL" then
    mail[1] = "ERROR CODE: "..msg
  else
    mail = textutils.unserialize(msg)
    os.sleep(0.5)
    header(true)
    term.setCursorPos(1,3)
    print(" < PRESS ANY KEY TO EXIT")
    print("Subject: "..mail[1])
    print("From:    "..mail[2])
    print("")
    for i = 3, #mail do
      print(mail[i])
    end
    local event, key = os.pullEvent("key")
    inbox()
  end
end
function compose()
  header(true)
  term.setCursorPos(1,3)
  
  write("Receiver: ")
  mail = {}
  mail.receiver = read()
  
  write("Subject: ")
  mail.subject = read()
  
  print("Message:")
  composing = true
  while composing do
    input = read()
    if input == "/send" then
      composing = false
    else
      table.insert(mail, input)
    end
  end
  
  serializedMail = textutils.serialize(mail)
  rednet.open(settings.mside)
  rednet.send(tonumber(settings.serverID), serializedMail, "DVG_MAIL_SEND")
  mail = {}
end

function inbox()
  inMain = false
  inInbox = true
  selected = 1
  inboxMenu = {[1] = {txt = "  X ",    func = toMain}}
  rednet.send(tonumber(settings.serverID), "inbox", "DVG_MAIL_INBOX_REQUEST")
  id, msg, code = rednet.receive("DVG_MAIL_INBOX_ANSWER", 10)
  if not msg then
    inboxMenu[2] = {txt = "No mail.", func = nil}
  elseif type(msg) == "string" and msg:sub(1,8) == "DVG_FAIL" then
    inboxMenu[2] = {txt = "CODE: "..msg, func = nil}
  else
    unserializedMsg = textutils.unserialize(msg)
    msg = unserializedMsg
    for i = 1, #msg do
      inboxPart = {txt = msg[i], func = readMail}
      table.insert(inboxMenu, inboxPart)
    end
  end
  
  while inInbox do
    term.setCursorPos(1,3)
    header(true)
    printMenu(inboxMenu)
    local event, key = os.pullEvent("key")
    keyPressed(key, inboxMenu)
    if not inInbox then break end
  end
end

-- Menu
local mainMenu = {
  [1] = {txt = "  X ",    func = stop},
  [2] = {txt = "COMPOSE", func = compose},
  [3] = {txt = "INBOX",   func = inbox}
}

-- Functions
function header(clear)
  if clear then term.clear() end
  term.setCursorPos(1,1)
  term.setBackgroundColor(colors.blue)
  term.setTextColor(colors.white)
  write("                                               ")
  term.setBackgroundColor(colors.red)
  print("  X ")
  term.setBackgroundColor(colors.blue)
  term.setCursorPos(1,1)
  print("DvgMail v"..version)
  term.setBackgroundColor(colors.white)
  term.setTextColor(colors.black)
end

function printMenu(menu)
  term.setCursorPos(1,3)
  for i = 1, #menu do
    if i == 1 then
      term.setCursorPos(46,1)
      term.setBackgroundColor(colors.blue)
      term.setTextColor(colors.white)
      if i == selected then
        print(" >")
      else
        print("  ")
      end
      term.setCursorPos(1,3)
      term.setBackgroundColor(colors.white)
      term.setTextColor(colors.black)
    else
      if i == selected then
        print(" > "..menu[i].txt)
      else
        print("   "..menu[i].txt)
      end
    end
  end
end
function keyPressed(key, menu)
  if key == keys.enter then
    menu[selected].func()
  elseif key == keys.up and selected > 1 then
    selected = selected - 1
  elseif key == keys.down and selected < #menu then
    selected = selected + 1
  end
end
function main()
  inInbox = false
  inMain = true
  selected = 1
  while inMain do
    term.setCursorPos(1,3)
    header(true)
    printMenu(mainMenu)
    local event, key = os.pullEvent("key")
    keyPressed(key, mainMenu)
    if not inMain then break end
  end
end

function install()
  fs.makeDir("/.DvgFiles/data/DvgMail")
  local settings = fs.open("/.DvgFiles/data/DvgMail/settings.cctf", "w")
  
  write("Modem side (use ^/v keys): ")
  input = read(nil, sides)
  if input ~= nil then
    settings.writeLine("mside = "..input)
  else
    error("Empty input!")
  end
  
  write("Server ID: ")
  input = read()
  if input ~= nil then
    settings.writeLine("serverid = "..input)
  else
    error("Empty input!")
  end
  settings.close()
end

-- Run
term.setBackgroundColor(colors.white)
term.setTextColor(colors.black)
term.clear()
term.setCursorPos(1,1)
if not fs.exists("/.DvgFiles") then
  error("You need to install DvgFiles first. (pastebin: Ds8VVrG6)")
end
header(true)
if not fs.exists("/.DvgFiles/data/dvgMail") then
  print("Preparing first startup.")
  install()
  header(true)
end
if not cctf.getFile then
  if not fs.exists("/.DvgFiles/APIs/cctf") then
    error("You need to install cctf interpreter first. (via pastebin: Ds8VVrG6)")
  else
    os.loadAPI("/.DvgFiles/APIs/cctf")
  end
end
settings = cctf.getFile("/.DvgFiles/data/DvgMail/settings.cctf")
main()
