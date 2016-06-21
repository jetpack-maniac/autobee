--- Configuration
-- The max size of the output inventory
chestSize = 27
-- chest direction relative to apiary
chestDir = "up"
-- how long the computer will wait before checking the apiaries
delay = 2
--- End of Configuration

if require ~= nil then
  component = require("component")
  keyboard = require("keyboard")
  event = require("event")
  term = require("term")
  version = "OpenComputers"
  print("AutoBee running.")
  print("Hold Ctrl+W to stop. Hold Ctrl+L to clear terminal.")
else
  version = "ComputerCraft"
  print("AutoBee running.")
  print("Press W to terminate program. Press L to clear terminal.")
end

local timerID = {}
local monitors = {}

--------------------------------------------------------------------------------
-- Apiary class

function Apiary(apiary)
  local self = {}

  -- Checks to see if the princess/queen slot (1) is empty or full and modifies
  -- queen and princess accordingly
  function self.isPrincessSlotOccupied()
    return apiary.getStackInSlot(1) ~= nil
  end

  -- Checks to see if the drone slot (2) is empty or full and modifies
  -- drone accordingly
  function self.isDroneSlotOccupied()
     return apiary.getStackInSlot(2) ~= nil
  end

  -- Removes a princess from the output to it's proper chest slot
  function self.pushPrincess(slot)
    apiary.pushItemIntoSlot(chestDir,slot,1,chestSize)
  end

  -- Pulls princess or queen from appropriate chest slot
  function self.pullPrincess()
    apiary.pullItemIntoSlot(chestDir,chestSize,1,1)
  end

  -- Removes a drone from the output to it's proper chest slot
  function self.pushDrone(slot)
    apiary.pushItemIntoSlot(chestDir,slot,64,chestSize-1)
  end

  -- Pulls drone from appropriate chest slot
  function self.pullDrone()
    apiary.pullItemIntoSlot(chestDir,chestSize-1,64,2)
  end

  function self.isPrincessOrQueen(slot)
    local name = apiary.getStackInSlot(slot).name
    return name == "beePrincessGE" or name == "beeQueenGE"
  end

  function self.isDrone(slot)
    return apiary.getStackInSlot(slot).name == "beeDroneGE"
  end

  function self.emptyOutput()
    for slot=3,9 do
      -- print(slot)
      if apiary.getStackInSlot(slot) ~= nil then
        if self.isPrincessOrQueen(slot) then
          self.pushPrincess(slot)
        elseif self.isDrone(slot) then
          self.pushDrone(slot)
        else
          apiary.pushItemIntoSlot(chestDir,slot)
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
          if apiary.getStackInSlot(slot) ~= nil and self.isPrincessOrQueen(slot) then
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
          if apiary.getStackInSlot(slot) ~= nil and self.isDrone(slot) then
            self.pushDrone(slot)
            self.pullDrone()
          end
        end
      end
    else -- drone is occupied
      for slot=3,9 do
        if apiary.getStackInSlot(slot) ~= nil and self.isDrone(slot) then
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

function errorHandling()
  if getStackInSlot == nil then
    print("AutoBee Error: This game server lacks OpenPeripherals.")
    print("It can be found at: https://openmods.info/")
    return true
  end
end

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
    event.cancel(timerID[device])
  end
  timerID[device] = nil
  print(size(timerID).." apiaries connected.")
end

function addDevice(address)
  if address == nil then return false end
  if version == "ComputerCraft" then -- address is the 'side'
    if string.find(peripheral.getType(address), "apiculture") and peripheral.getType(address):sub(21,21) == "0" then
      timerID[os.startTimer(delay)] = Apiary(peripheral.wrap(address))
      print(size(timerID).." apiaries connected.")
      return true
    end
  elseif version == "OpenComputers" then
    local type = component.type(address) -- address is the address
    if string.find(type, "apiculture") and type:sub(21,21) == "0" then
      local apiary = Apiary(component.proxy(address))
      timerID[address] = event.timer(delay, function() checkApiary(apiary) end, math.huge)
      print(size(timerID).." apiaries connected.")
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

if errorHandling() == true then
  if version == "OpenComputers" then
    os.exit()
  else
    shell.exit()
  end
end

while true do
  if version == "OpenComputers" then
    if keyboard.isKeyDown(keyboard.keys.w) and keyboard.isControlDown() then
      event.ignore("component_available",deviceConnect)
      event.ignore("component_removed",deviceDisconnect)
      for address, _ in pairs(timerID) do
        removeDevice(address)
      end
      break
    end
    if keyboard.isKeyDown(keyboard.keys.l) and keyboard.isControlDown() then
      term.clear()
      print("AutoBee running.")
      print("Hold Ctrl+W to stop. Hold Ctrl+L to clear terminal.")
      print(size(timerID).." apiaries connected.")
    end
    os.sleep(delay)
  end

  if version == "ComputerCraft" then
    event, data = os.pullEvent()
    if event == "timer" then
      checkApiary(timerID[data])
      timerID[os.startTimer(delay)] = timerID[data]
      timerID[data] = nil
    elseif event == "peripheral" then
      addDevice(data)
    elseif event == "peripheral_detach" then
      removeDevice(data)
    elseif event == "key_up" and data == keys.l then
      term.clear()
      term.setCursorPos(1,1)
      print("AutoBee running.")
      print("Press W to terminate program. Press L to clear terminal.")
      print(size(timerID).." apiaries connected.")
    elseif event == "key_up" and data == keys.w then
      print()
      if timer > 0 then
        os.cancelTimer(timer)
      end
      break
    end
  end
end

print("Program terminated.")
