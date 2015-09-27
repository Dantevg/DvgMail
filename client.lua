--[[
      DvgMail client
      by DvgCraft
      Mail server, DvgAPI and
      advanced computer required
      
      DATE  22-09-2015
]]--

-- Variables
local version = "2.0 beta"
local basePath = "/.DvgFiles/data/DvgMail"
local running = true

local settings = {}
local mail = {}
local mails = {}

local offset = 0

-- Functions
function Exit()
  term.setTextColor( colors.white )
  term.setBackgroundColor( colors.black )
  running = false
  shell.run( "clear" )
end

function header(clear, ...)
  term.setBackgroundColor( colors.white )
  if clear then term.clear() end
  term.setCursorPos( 1,1 )
  term.setBackgroundColor( colors.blue )
  term.setTextColor( colors.white )
  if #arg == 1 and arg[1] then
    write( " < " )
  else
    write( " x " )
  end
  write( "DvgMail                              " )
  if #arg == 2 and arg[2] then
    write( "    > Send " )
  else
    write( "+ New Mail " )
  end
  term.setBackgroundColor( colors.white )
  term.setTextColor( colors.black )
  term.setCursorPos( 1,3 )
end

function install()
  fs.makeDir(basePath)
  
  write( "Modem side (use ^/v keys): " )
  input = read( nil, dvg.sides )
  if input ~= nil then
    settings.mside = input
  else
    error( "Empty input!" )
    fs.delete( basePath )
  end
  
  write( "Server ID: " )
  input = read()
  if input ~= nil then
    settings.serverID = tonumber( input )
  else
    error( "Empty input!" )
    fs.delete( basePath )
  end
  
  local file = fs.open( basePath.."/settings.cfg", "w" )
  file.write( textutils.serialize(settings) )
  settings.close()
end

function updateMails()
  mails = {}
  rednet.send( tonumber(settings.serverID), "inbox", "DVG_MAIL_INBOX_REQUEST" )
  id, msg, code = rednet.receive( "DVG_MAIL_INBOX_ANSWER", 3 )
  if not msg or ( #textutils.unserialize( msg ) == 0 ) then
    mails = { [1] = "No mail" }
  elseif type( msg ) == "string" and msg:sub( 1,8 ) == "DVG_FAIL" then
    mails = { [1] = "Failed. Code: "..msg }
  else
    msg = textutils.unserialize( msg )
    for i = 1, #msg do
      table.insert( mails, msg[i] )
    end
  end
end

function readMail(num)
  header( true, true )
  mail = {}
  rednet.send( tonumber(settings.serverID), mails[num], "DVG_MAIL_MAIL_REQUEST" )
  id, msg, code = rednet.receive( "DVG_MAIL_MAIL_ANSWER", 3 )
  if msg:sub( 1,8 ) == "DVG_FAIL" then
    mail[1] = "ERROR CODE: "..msg
    mail[2] = "00"
  end
  mail = textutils.unserialize( msg )
  term.setCursorPos( 1,3 )
  term.setTextColor(colors.lightGray)
  write( " "..tonumber(mail[2]) )
  term.setTextColor(colors.black)
  print( "  "..mail[1] )
  print( "" )
  for i = 3, #mail do
    print( " "..mail[i] )
  end
  
  while true do
    local event, button, x, y = os.pullEvent( "mouse_click" )
    if y == 1 then
      if x >= 41 and x <= 51 then
        compose()
        updateMails()
      elseif x >= 1 and x <= 3 then
        break
      end
    end
  end
end
function compose()
  header( true, true, true )
  term.setCursorPos( 1,3 )
  write( " Receiver: " )
  term.setBackgroundColor( colors.lightGray )
  print( "               " )
  print()
  term.setBackgroundColor( colors.white )
  write( " Subject:  " )
  term.setBackgroundColor( colors.lightGray )
  print( "               " )
  print()
  term.setBackgroundColor( colors.white )
  print(" Message:" )
  
  mail = {}
  local send = false
  while true do
    local event, button, x, y = os.pullEvent( "mouse_click" )
    if y == 1 then
      
      if x >= 1 and x <= 3 then
        break
      elseif x >= 46 and x <= 51 then
        if mail.receiver and mail.subject and #mail > 3 then
          send = true
          break
        end
      end
      
    elseif y == 3 then
      term.setBackgroundColor( colors.lightGray )
      term.setCursorPos( 12,3 )
      mail.receiver = read()
    elseif y == 5 then
      term.setBackgroundColor( colors.lightGray )
      term.setCursorPos( 12,5 )
      mail.subject = read()
    elseif y >= 7 then
      
      term.setBackgroundColor( colors.white )
      term.setCursorPos( 1,8 )
      while true do
        write( " " )
        input = read()
        if input == "/send" then
          break
        else
          table.insert( mail, input )
        end
      end
      
    end
  end
  
  if send then
    rednet.send( tonumber(settings.serverID), textutils.serialize(mail), "DVG_MAIL_SEND" )
  end
  mail = {}
end
function inbox()
  updateMails()
  
  while running do
    header( true )
    local offsetMails = dvg.scroll( mails, height-3, offset )
    for i = 1, #offsetMails do
      print( " "..offsetMails[i] )
    end
    
    local event, button, x, y = os.pullEvent( "mouse_click" )
    if y == 1 then
      if x >= 1 and x <= 3 then
        Exit()
      elseif x >= 41 and x <= 51 then
        compose()
        updateMails()
      end
    elseif y >= 3 then
      readMail( y-2 )
    end
  end
end

-- Run
term.setBackgroundColor( colors.white )
term.setTextColor( colors.black )
term.clear()
local logo = paintutils.loadImage( basePath.."/logo" )
paintutils.drawImage( logo, 19, 4 )
term.setBackgroundColor( colors.white )

if not dvg then assert( os.loadAPI("/.DvgFiles/APIs/dvg") ) end

dvg.center( "Dvg Mail", 16 )
os.sleep( 1.5 )
header( true )
if not fs.exists( "/.DvgFiles" ) then
  error( "You need to install DvgFiles first. (pastebin: Ds8VVrG6)" )
end
if not fs.exists( basePath ) then
  print( "Preparing first startup." )
  install()
  header( true )
end

local file = fs.open( basePath.."/settings.cfg", "r" )
settings = textutils.unserialize( file.readAll() )
file.close()
width, height = term.getSize()
if not rednet.isOpen( settings.mside ) then
  rednet.open( settings.mside )
end
inbox()
