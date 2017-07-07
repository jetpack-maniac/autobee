---- AutoBee for ComputerCraft ----

-- debug

local printTimers = true
local outputDebug = true

-- end debug

local running = true
dofile("autobeeCore.lua")

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
    if isApiary(address) ~= nil then
      return peripheral.wrap(address)
    end
  end
  return nil
end

-- Peripheral check

function peripheralCheck()
  local apiary = findApiary()
  if apiary ~= nil then
    if dependencyCheck(apiary) then
      print("AutoBee running.")
      print("Press W to terminate program. Press L to clear terminal.")
    end
  else
    error("No apiaries detected.")
  end
end

-- Version check
if os.version ~= nil then -- This is a ComputerCraft OS API method
  -- if string.find(os.version(), "CraftOS") == true then
  if os.version() == "CraftOS 1.7" then -- This is ComputerCraft for 1.9/1.10
    version = "ComputerCraft"
    peripheralCheck()
  else
    error("This version is for ComputerCraft.  See https://github.com/jetpack-maniac/autobee for more details.")
  end
end

local apiaryTimerIDs = {}

-- Device Management

function removeDevices()
  for timerID, address in pairs(apiaryTimerIDs) do
    os.cancelTimer(timerID)
  end
  apiaryTimerIDs = {}
end

function addDevice(address)
  if isApiary(address) ~= false then
    apiaryTimerIDs[os.startTimer(delay)] = Apiary(peripheral.wrap(address), address)
    print(size(apiaryTimerIDs).." apiaries connected.")
    return true
  end
  return false
end

function initDevices()
  local devices = peripheral.getNames()
  for _, device in ipairs(devices) do
    addDevice(device)
  end
end

-- ComputerCraft Event-based Functions

function deleteTimer(timerID)
  apiaryTimerIDs[timerID] = nil
end

function handleTimer()
  local _, data = os.pullEvent("timer")
  apiaryTimerIDs[os.startTimer(delay)] = apiaryTimerIDs[data]
  if printTimers == true then 
    print("Timer: "..apiaryTimerIDs[data].getID())
  end
  if outputDebug == true then
    if pcall(function() apiaryTimerIDs[data].checkOutput() end) == false then
      print("Pcall failed checkOutput on "..apiaryTimerIDs[data].getID())
    end
  end
  deleteTimer(data)
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
    print(size(apiaryTimerIDs).." apiaries connected.")
  elseif data == keys.w then
    print("AutoBee: Interrupt detected. Closing program.")
    for timerID, _ in pairs(apiaryTimerIDs) do
      os.cancelTimer(timerID)
    end
    running = false
  elseif data == keys.t then
    if printTimers == false then
      print("Timers printing.")
      printTimers = true
    else
      print("Stopping timers print.")
      printTimers = false
    end
  elseif data == keys.o then
    if outputDebug == false then
      print("Output on.")
      outputDebug = true
    else
      print("Output off.")
      outputDebug = false
    end
  elseif data == keys.a then
    print("Rebuilding apiary map.")
    removeDevices()
  elseif data == keys.m then
    print("Printing apiary map:")
    for timerID, apiary in pairs(apiaryTimerIDs) do
      print(timerID..": "..apiary.getID())
    end
  end
end

----------------------
-- The main loop
----------------------

if running == true then initDevices() end -- inits devices upon first run

while running do
  parallel.waitForAny(handleTimer, handlePeripheralAttach, handlePeripheralDetach, humanInteraction)
end