--- Configuration
-- The max size of the output inventory
chestSize = 27
-- chest direction relative to apiary
chestDir = "up"
-- how long the computer will wait in seconds before checking the apiaries
delay = 2
--- End of Configuration

if os.version ~= nil then -- This is a ComputerCraft OS API method
  if os.version() == "CraftOS 1.8" then -- This is ComputerCraft for 1.9/1.10
    version = "ComputerCraft"
    print("AutoBee running.")
    print("Press W to terminate program. Press L to clear terminal.")
  end
else
  component = require("component")
  keyboard = require("keyboard")
  event = require("event")
  term = require("term")
  version = "OpenComputers"
  print("AutoBee running.")
  print("Hold Ctrl+W to stop. Hold Ctrl+L to clear terminal.")
end



local apiaryID = {}
local monitors = {}

function dependencyCheck(device)
  if device.suck == nil then
    print("AutoBee Error: This game server lacks the Forge mod: Plethora Peripherals.  It is required to run this program.")
    print("It can be found at: https://squiddev-cc.github.io/plethora/")
    if version == "OpenComputers" then
      os.exit()
    elseif version == "ComputerCraft" then
      shell.exit()
    end
  end
end

--------------------------------------------------------------------------------
-- Apiary class

function Apiary(device)
  local self = {}

  dependencyCheck(device)

  -- Checks to see if the princess/queen slot (1) is empty or full and modifies
  -- queen and princess accordingly
  function self.isPrincessSlotOccupied()
    return device.getItemMeta(1) ~= nil
  end

  -- Checks to see if the drone slot (2) is empty or full and modifies
  -- drone accordingly
  function self.isDroneSlotOccupied()
     return device.getItemMeta(2) ~= nil
  end

  -- Removes a princess from the output to it's proper chest slot
  function self.pushPrincess(slot)
    device.pushItems(chestDir,slot,1,chestSize)
  end

  -- Pulls princess or queen from appropriate chest slot
  function self.pullPrincess()
    device.pullItems(chestDir,chestSize,1,1)
  end

  -- Removes a drone from the output to it's proper chest slot
  function self.pushDrone(slot)
    device.pushItems(chestDir,slot,64,chestSize-1)
  end

  -- Pulls drone from appropriate chest slot
  function self.pullDrone()
    device.pullItems(chestDir,chestSize-1,64,2)
  end

  function self.isPrincessOrQueen(slot)
    local name = device.getItemMeta(slot).name
    return name == "beePrincessGE" or name == "beeQueenGE"
  end

  function self.isDrone(slot)
    return device.getItemMeta(slot).name == "beeDroneGE"
  end

  function self.emptyOutput()
    for slot=3,9 do
      -- print(slot)
      if device.getItemMeta(slot) ~= nil then
        if self.isPrincessOrQueen(slot) then
          self.pushPrincess(slot)
        elseif self.isDrone(slot) then
          self.pushDrone(slot)
        else
          device.pushItems(chestDir,slot)
        end
      end
    end
  end

  function self.populatePrincessSlot()
    if self.isPrincessSlotOccupied() == false then
      self.pullPrincess()
      -- If we didn't get a princess from our chest check the output
      if self.isPrincessSlotOccupied() == false then
        for slot=3,9 do
          -- We will only get princesses in the output, never a queen
          if device.getItemMeta(slot) ~= nil and self.isPrincessOrQueen(slot) then
            self.pushPrincess(slot)
            self.pullPrincess()
          end
        end
      end
    end
  end

  function self.populateDroneSlot()
    if self.isDroneSlotOccupied() == false then
      self.pullDrone()
      -- If we didn't get a drone from our chest check the output
      if self.isDroneSlotOccupied() == false then
        for slot=3,9 do
          if device.getItemMeta(slot) ~= nil and self.isDrone(slot) then
            self.pushDrone(slot)
            self.pullDrone()
          end
        end
      end
    else -- drone is occupied
      for slot=3,9 do
        if device.getItemMeta(slot) ~= nil and self.isDrone(slot) then
            self.pushDrone(slot)
        end
      end
    end
  end

  return self
end

-- End Apiary class
--------------------------------------------------------------------------------
-- Misc Functions

function checkApiary(apiary)
  apiary.populatePrincessSlot()
  apiary.populateDroneSlot()
  apiary.emptyOutput()
end

function size(input)
  local count = 0
  for _, _ in pairs(input) do
    count = count + 1
  end
  return count
end

--These next two functions are callbacks to enable OC events to work properly
function deviceConnect(event, address)
  addDevice(address)
end

function deviceDisconnect(event, address)
  removeDevice(address)
end

function removeDevice(device)
  if version == "OpenComputers" then
    event.cancel(apiaryID[device])
  end
  apiaryID[device] = nil
  print(size(apiaryID).." apiaries connected.")
end

function addDevice(address)
  if address == nil then return false end
  if version == "ComputerCraft" then -- address is the 'side' for ComputerCraft
    -- if string.find(peripheral.getType(address), "apiculture") and peripheral.getType(address):sub(21,21) == "0" then
    if string.find(peripheral.getType(address), "forestry_apiary") then
      apiaryID[os.startTimer(delay)] = Apiary(peripheral.wrap(address))
      print(size(apiaryID).." apiaries connected.")
      return true
    end
  elseif version == "OpenComputers" then
    local type = component.type(address) -- address is the address for OpenComputers
    -- if string.find(type, "apiculture") and type:sub(21,21) == "0" then
    if string.find(type, "bee_housing") then
      local apiary = Apiary(component.proxy(address))
      apiaryID[address] = event.timer(delay, function() checkApiary(apiary) end, math.huge)
      print(size(apiaryID).." apiaries connected.")
      return true
    end
  end

  return false
end

if version == "ComputerCraft" then
  local devices = peripheral.getNames()
  for _, device in ipairs(devices) do
    addDevice(device)
  end
elseif version == "OpenComputers" then
  --Aux ignore in case the program crashed and listeners are still active
  event.ignore("component_available",deviceConnect)
  event.ignore("component_removed",deviceDisconnect)
  local devices = component.list()
  for address, device in pairs(devices) do
    addDevice(address)
  end
  event.listen("component_added",deviceConnect)
  event.listen("component_removed",deviceDisconnect)
end

----------------------
-- The main loop
----------------------

while true do
  if version == "OpenComputers" then
    if keyboard.isKeyDown(keyboard.keys.w) and keyboard.isControlDown() then
      event.ignore("component_available",deviceConnect)
      event.ignore("component_removed",deviceDisconnect)
      for address, _ in pairs(apiaryID) do
        removeDevice(address)
      end
      break
    end
    if keyboard.isKeyDown(keyboard.keys.l) and keyboard.isControlDown() then
      term.clear()
      print("AutoBee running.")
      print("Hold Ctrl+W to stop. Hold Ctrl+L to clear terminal.")
      print(size(apiaryID).." apiaries connected.")
    end
    os.sleep(delay)
  end

  if version == "ComputerCraft" then
    event, data = os.pullEvent()
    if event == "timer" then
      checkApiary(apiaryID[data])
      apiaryID[os.startTimer(delay)] = apiaryID[data]
      apiaryID[data] = nil
    elseif event == "peripheral" then
      addDevice(data)
    elseif event == "peripheral_detach" then
      removeDevice(data)
    elseif event == "key_up" and data == keys.l then
      term.clear()
      term.setCursorPos(1,1)
      print("AutoBee running.")
      print("Press W to terminate program. Press L to clear terminal.")
      print(size(apiaryID).." apiaries connected.")
    elseif event == "key_up" and data == keys.w then
      print()
      if timer ~= nil and timer > 0 then
        os.cancelTimer(timer)
      end
      break
    end
  end
end

print("Program terminated.")
