--[[
      DvgMail server
      by DvgCraft
      Wireless Modem required
      
      DATE  16-07-2015
]]--

-- Variables
local version = "1.0.1"
local mail = {}
local inbox = {}
local msg = nil
local suffixing = false
local suffix = 1

-- Functions
function writeToFile(location, doSuffix)
  if doSuffix then
    file = fs.open(location.."_"..tostring(suffix), "w")
  else
    file = fs.open(location, "w")
  end
  file.writeLine(msg.subject)
  file.writeLine(id)
  for i = 1, #msg do
    file.writeLine(msg[i])
  end
  file.close()
end

-- Run
print("-[[ DVGMAIL SERVER LOG ]]--------------------------")
while true do
  mail = {}
  inbox = {}
  id, msg, code = rednet.receive()
  if code then
  print("LOG   Received "..code)
  if code:sub(1,8) == "DVG_MAIL" then --DvgMail
    
    if code == "DVG_MAIL_SEND" then --Send mail
      msg = textutils.unserialize(msg)
      if not fs.isDir("/disk/users/"..msg.receiver) then
        print("LOG   Making folder for new user "..msg.receiver)
        fs.makeDir("/disk/users/"..msg.receiver)
      end
      if not fs.exists("/disk/users/"..msg.receiver.."/"..msg.subject) then
        writeToFile("/disk/users/"..msg.receiver.."/"..msg.subject, false)
      else
        
        suffixing = true
        while suffixing do --Start suffixing
          print("LOG   Starting suffix")
          if not fs.exists("/disk/users/"..msg.receiver.."/"..msg.subject.."_"..tostring(suffix)) then
            suffixing = false
            writeToFile("/disk/users/"..msg.receiver.."/"..msg.subject, true)
          else
            suffix = suffix + 1
          end
        end
        suffix = 1
        
      end
      print("LOG   Writing mail to file")
      
    elseif code == "DVG_MAIL_INBOX_REQUEST" then --Receive inbox
      if fs.isDir("/disk/users/"..id) then
        inbox = textutils.serialize(fs.list("/disk/users/"..id))
        rednet.send(id, inbox, "DVG_MAIL_INBOX_ANSWER")
        print("LOG   Sent inbox to "..id)
      else
        print("ERROR User "..id.." doesn't exist")
        rednet.send(id, "DVG_FAIL_USER-NOT-EXISTS", "DVG_MAIL_INBOX_ANSWER")
      end
    
    elseif code == "DVG_MAIL_MAIL_REQUEST" then
      if fs.isDir("/disk/users/"..id) then
        if fs.exists("/disk/users/"..id.."/"..msg) then
          file = fs.open("/disk/users/"..id.."/"..msg, "r")
          line = file.readLine()
          while line do
            table.insert(mail, line)
            line = file.readLine()
          end
          mail = textutils.serialize(mail)
          rednet.send(id, mail, "DVG_MAIL_MAIL_ANSWER")
        else
          print("ERROR Mail \""..msg.."\" from user "..id.." doesn't exist")
          rednet.send(id, "DVG_FAIL_MAIL-NOT-EXISTS", "DVG_MAIL_MAIL_ANSWER")
        end
      else
        print("ERROR User "..id.." doesn't exist")
        rednet.send(id, "Dvg_FAIL_USER-NOT-EXISTS", "DVG_MAIL_MAIL_ANSWER")
      end
    end
    
  end
  mail = nil
  inbox = nil
  end
end
