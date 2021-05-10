---- AutoBee for ComputerCraft ----


-- Global variables
local running = true
local apiaryTimer = nil
local apiaries = {}

-- Version check
if os.version ~= nil then -- This is a ComputerCraft OS API method
  -- if string.find(os.version(), "CraftOS") == true then
  if os.version() == "CraftOS 1.8" or os.version() == "CraftOS 1.7" then -- This is ComputerCraft for 1.9/1.10
    version = "ComputerCraft"
  else
    error("This version is for ComputerCraft.  See https://github.com/jetpack-maniac/autobee for more details.")
  end
end

-- Loads the core library, fetches if missing
if pcall(function() dofile("autobeeCore.lua") end) == false then
  if pcall(function() dofile("autobee/autobeeCore.lua") end) == false then
    print("Core Autobee library not found.  Fetching via Github.")
    local file = nil
    local response = http.get("https://raw.githubusercontent.com/jetpack-maniac/autobee/master/autobeeCore.lua")
    if response == nil then
      error("Could not reach Github.com")
    else
      if pcall(function() file = fs.open("autobeeCore.lua", "w") file.write(response.readAll()) file.close() end) then
        print("Fetched AutoBee Core.")
      else
        error("Could not create "..filename..", the disk is full or read-only.")
      end
    end
  end
end

-- Peripheral check
function peripheralCheck()
  local apiary = findApiary()
  if apiary ~= nil then
    dependencyCheck(apiary)
  else
    print("AutoBee Warning: No compatible apiaries detected.")
  end
end

-- looks at a device and determines if it's a valid apiary, returns true or false
function isApiary(address)
  if address == nil then return false end
  -- 1.12.2 Apiary
  if string.find(peripheral.getType(address), "forestry:apiary") then
    return "apiary"
  -- Gendustry Industrial Apiary
  elseif string.find(peripheral.getType(address), "gendustry:industrial_apiary") then
    return "gendustry"
  -- 1.10.2/1.11.2 Apiary
  elseif string.find(peripheral.getType(address), "forestry_apiary") then
    return "apiary"
  -- 1.7.10 Apiary
  elseif string.find(peripheral.getType(address), "apiculture") and peripheral.getType(address):sub(21,21) == "0" == true then
    return "apiary"
  else
    return false
  end
end

-- examines peripherals and returns a valid apiary or nil
function findApiary()
  local devices = peripheral.getNames()
  for _, address in pairs(devices) do
    if isApiary(address) == "apiary" or "gendustry" then
      return peripheral.wrap(address)
    end
  end
  return nil
end

-- Device Management
function removeDevices()
  os.cancelTimer(apiaryTimer)
  apiaries = {}
end

function addDevice(address, type)
  if isApiary(address) == true then
    table.insert(apiaries, Apiary(peripheral.wrap(address), type))
  end
end

function initDevices()
  local devices = peripheral.getNames()  
  for _, device in ipairs(devices) do
--    addDevice(device)
    local apiaryType = isApiary(device)
    local apiary = Apiary(peripheral.wrap(device))
    if apiaryType == "apiary" then
      apiary.checkApiary(3, 9)
    elseif apiaryType == "gendustry" then
      print(apiary)
      apiary.checkApiary(7, 15)
    end
  end
  os.startTimer(delay)
end

-- ComputerCraft Event-based Functions
function handleTimer()
  local _, data = os.pullEvent("timer")
  for apiary, address in pairs(apiaries) do
    print(address)
    -- Forestry apiary
    if true then
      apiaries[apiary].checkApiary(3, 9)
    -- Gendustry industrial apiary
    elseif false then
      apiaries[apiary].checkApiary(7, 15)
    end
  end
  apiaryTimer = os.startTimer(delay)
end

function handlePeripheralAttach()
  local _, data = os.pullEvent("peripheral")
--  addDevice(data)
  initDevices()
end

function handlePeripheralDetach()
  local _, data = os.pullEvent("peripheral_detach")
--  removeDevices()
  initDevices()
end

function humanInteraction()
  local _, data = os.pullEvent("key_up")
  if data == keys.l then
    term.setCursorPos(1,1)
    term.clear()
    printInfo()
  elseif data == keys.w then
    print("AutoBee: Interrupt detected. Closing program.")
    if apiaryTimer ~= nil then 
      os.cancelTimer(apiaryTimer)
    end
    running = false
  end
end

function printInfo()
    print("AutoBee running.")
    print("Press W to stop program. Press L to clear terminal.")
    print(size(apiaries).." apiaries connected.")
end

----------------------
-- The main loop
----------------------

peripheralCheck()
if running == true then 
  initDevices()
  printInfo()
end

while running do
  local event, data = os.pullEvent()
  if event == "peripheral" or "peripheral_detach" or "timer" then
    initDevices()
  elseif event == "key_up" then
    if data == keys.l then
      term.setCursorPos(1,1)
      term.clear()
      printInfo()
    elseif data == keys.w then
      print("AutoBee: Interrupt detected. Closing program.")
      if apiaryTimer ~= nil then 
        os.cancelTimer(apiaryTimer)
      end
      running = false
    end
  end
end