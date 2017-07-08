---- AutoBee for ComputerCraft ----

-- debug
local printTimers = false
local outputDebug = true
-- end debug

local running = true
local apiaryTimer = nil
local apiaries = {}

if pcall(function() dofile("autobeeCore.lua") end) == false then
  if pcall(function() dofile("autobee/autobeeCore.lua") end) == false then
    print("Core Autobee library not found.  Fetching via pastebin.com/Vvckgdst")
    shell.run("pastebin get Vvckgdst autobeeCore.lua")
    if pcall(function() dofile("autobeeCore.lua") end) == false then
      error("Failed to fetch library.")
    end
  end
end

-- looks at a device and determines if it's a valid apiary, returns true or false
function isApiary(address)
  if address == nil then return false end
  -- 1.10.2 Apiary
  if string.find(peripheral.getType(address), "forestry_apiary") then
    return true
  -- 1.7.10 Apiary
  elseif string.find(peripheral.getType(address), "apiculture") and peripheral.getType(address):sub(21,21) == "0" == true then
    return true
  else
    return false
  end
end

-- examines peripherals and returns a valid apiary or nil
function findApiary()
  local devices = peripheral.getNames()
  for _, address in pairs(devices) do
    if isApiary(address) == true then
      return peripheral.wrap(address)
    end
  end
  return nil
end

-- Peripheral check
function peripheralCheck()
  local apiary = findApiary()
  if apiary ~= nil then
    if dependencyCheck(apiary) == true then
      print("AutoBee running.")
      print("Press W to terminate program. Press L to clear terminal.")
    end
  else
    print("AutoBee Warning: No apiaries detected.")
  end
end

-- Version check
if os.version ~= nil then -- This is a ComputerCraft OS API method
  -- if string.find(os.version(), "CraftOS") == true then
  if os.version() == "CraftOS 1.8" or os.version() == "CraftOS 1.7" then -- This is ComputerCraft for 1.9/1.10
    version = "ComputerCraft"
    peripheralCheck()
  else
    error("This version is for ComputerCraft.  See https://github.com/jetpack-maniac/autobee for more details.")
  end
end

-- Device Management
function removeDevices()
  os.cancelTimer(apiaryTimer)
  apiaries = {}
end

-- work around for CraftOS dropping timers
function addDevice(address)
  if isApiary(address) == true then
    table.insert(apiaries, Apiary(peripheral.wrap(address)))
  end
end

function initDevices()
  local devices = peripheral.getNames()
  for _, device in ipairs(devices) do
    addDevice(device)
  end
  os.startTimer(delay)
end

-- ComputerCraft Event-based Functions
function handleTimer()
  local _, data = os.pullEvent("timer")
  for apiary, address in pairs(apiaries) do
    apiaries[apiary].checkApiary()
  end
  apiaryTimer = os.startTimer(delay)
end

function handlePeripheralAttach()
  local _, data = os.pullEvent("peripheral")
  addDevice(data) 
end

function handlePeripheralDetach()
  local _, data = os.pullEvent("peripheral_detach")
  removeDevices()
  initDevices()
end

function humanInteraction()
  local _, data = os.pullEvent("key_up")
  if data == keys.l then
    term.clear()
    term.setCursorPos(1,1)
    print("AutoBee running.")
    print("Press W to stop program. Press L to clear terminal.")
    print(size(apiaries).." apiaries connected.")
  elseif data == keys.w then
    print("AutoBee: Interrupt detected. Closing program.")
    if apiaryTimer ~= nil then 
      os.cancelTimer(apiaryTimer)
    end
    running = false
  end
end

----------------------
-- The main loop
----------------------

if running == true then initDevices() end -- inits devices upon first run

while running do
  parallel.waitForAny(handleTimer, handlePeripheralAttach, handlePeripheralDetach, humanInteraction)
end