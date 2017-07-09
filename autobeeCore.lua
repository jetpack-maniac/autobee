--- Configuration

-- These config options tell the apiaries to drop items into the world
-- WARNING: unless you're using some kind of system to pick them up,
-- this will cause lag due to floating items piling up in the world
-- **Currently unused, WIP
-- dropProducts = "false"
-- dropDrones = "false"

-- The max size of the output inventory
chestSize = 27

-- chest direction relative to apiary
chestDir = "up"

-- how long the computer will wait in seconds before checking the apiaries
delay = 2

-- debug printing for functions
debugPrints = false
--- End of Configuration

local queenNames = {"beeQueenGE", "forestry:beeQueenGE"}
local princessNames = {"beePrincessGE", "forestry:beePrincessGE"}
local droneNames = {"beeDroneGE", "forestry:beeDroneGE"}

--------------------------------------------------------------------------------
-- Misc Functions

-- returns the size of a data structure
function size(input)
  local count = 0
  for _, _ in pairs(input) do
    count = count + 1
  end
  return count
end

-- searches a sample table and returns true if any element matches the criterion
function matchAny(criterion, sample)
  for i=1, #sample do
    if criterion == sample[i] then
      return true
    end
  end
  return false
end

-- Dependency Check for required item APIs
function dependencyCheck(device)
  if device == nil then return nil end
  if device.getTransferLocations ~= nil then
    peripheralVersion = "Plethora"
  elseif device.canBreed ~= nil then
    peripheralVersion = "OpenPeripherals"
  end
  if peripheralVersion == nil then
    error("This game server lacks a required game mod. 1.7.10 requires OpePeripherals and 1.10.2 requires Plethora Peripherals.")
  end
  return true
end

-- Peripheral Interfaces

function getItemData(container, slot)
  local itemMeta = nil
  if peripheralVersion == "Plethora" then
    if pcall(function() itemMeta = container.getItemMeta(slot) end) then
      return itemMeta
    elseif debugPrints == true then
      print("AutoBee Error: PCall failed on plethora check slot")
    end
  elseif peripheralVersion == "OpenPeripherals" then
    if pcall(function() itemMeta = container.getStackInSlot(slot) end) then
      return itemMeta
    elseif debugPrints == true then
      print("AutoBee Error: PCall failed on openp check slot")
    end    
  end
end

-- Interface for item pushing, follows the OpenPeripherals/Plethora format directly
function pushItem(container, destinationDirection, fromSlot, amount, destinationSlot)
  if peripheralVersion == "Plethora" then
    if pcall(function() container.pushItems(destinationDirection, fromSlot, amount, destinationSlot) end) then
      return true
    elseif debugPrints == true then
      print("AutoBee Error: PCall failed on plethora push")
    end
  elseif peripheralVersion == "OpenPeripherals" then
    if pcall(function() container.pushItemIntoSlot(destinationDirection, fromSlot, amount, destinationSlot) end) then
      return true
    elseif debugPrints == true then
      print("AutoBee Error: PCall failed on openp push")
    end
  end
end

-- Interface for item pulling,  follows the OpenPeripherals/Plethora format directly
function pullItem(container, sourceDirection, fromSlot, amount, destinationSlot)
  if peripheralVersion == "Plethora" then
    if pcall(function() container.pullItems(sourceDirection, fromSlot, amount, destinationSlot) end) then
      return true
    elseif debugPrints == true then
      print("AutoBee Error: PCall failed on plethora pull")
    end
  elseif peripheralVersion == "OpenPeripherals" then
    if pcall(function() container.pullItemIntoSlot(sourceDirection, fromSlot, amount, destinationSlot) end) then
      return true
    elseif debugPrints == true then
      print("AutoBee Error: PCall failed on openp pull")
    end
  end 
end

-- End of Misc Functions
--------------------------------------------------------------------------------
-- Container class

function Container(tileEntity)
  local self = {}

  function self.getItemData(slot)
    return getItemData(tileEntity, slot)
  end

  -- Interface for item pushing, follows the OpenPeripherals/Plethora format directly
  function self.push(destinationDirection, fromSlot, amount, destinationSlot)
    return pushItem(tileEntity, destinationDirection, fromSlot, amount, destinationSlot)
  end

  -- Interface for item pulling,  follows the OpenPeripherals/Plethora format directly
  function self.pull(sourceDirection, fromSlot, amount, destinationSlot)
    return pullItem(tileEntity, sourceDirection, fromSlot, amount, destinationSlot)
  end

  return self
end

--------------------------------------------------------------------------------
-- Apiary class

function Apiary(device, address)
  local self = Container(device)

  function self.getID()
    return address
  end

  -- Checks to see if the princess/queen slot (1) is empty or full
  function self.isPrincessSlotOccupied()
    return self.getItemData(1) ~= nil
  end

  -- Checks to see if the drone slot (2) is empty or full
  function self.isDroneSlotOccupied()
     return self.getItemData(2) ~= nil
  end

  -- Removes a princess from the output to it's proper chest slot
  function self.pushPrincess(slot)
    self.push(chestDir,slot,1,chestSize)
  end

  -- Pulls princess or queen from appropriate chest slot
  function self.pullPrincess()
    self.pull(chestDir,chestSize,1,1)
  end

  -- Removes a drone from the output to it's proper chest slot
  function self.pushDrone(slot)
    self.push(chestDir,slot,64,chestSize-1)
  end

  -- Pulls drone from appropriate chest slot
  function self.pullDrone()
    self.pull(chestDir,chestSize-1,64,2)
  end

  -- Moves drone from output into input
  function self.moveDrone(slot)
    if peripheralVersion == "Plethora" then
      self.push("self", slot, 64, 2)
      return true
    elseif peripheralVersion == "OpenPeripherals" then
      self.pushDrone(slot)
      self.pullDrone()
    end
    return false
  end

  -- Moves princess from output into input
  function self.movePrincess(slot)
    if peripheralVersion == "Plethora" then
      self.push("self", slot, 1, 1)
      return true
    elseif peripheralVersion == "OpenPeripherals" then
      self.pushPrincess(slot)
      self.pullPrincess()
      return true
    end
  end

  function self.isPrincessOrQueen(slot)
    local type = self.itemType(slot)
    if type == "queen" or type == "princess" then
      return true
    else
      return false
    end
  end

  function self.itemType(slot)
    if self.getItemData(slot) ~= nil then
      local name = self.getItemData(slot).name
      if matchAny(name, queenNames) then return "queen" end
      if matchAny(name, princessNames) then return "princess" end
      if matchAny(name, droneNames) then return "drone" end
      return false
    else
      return nil
    end
  end

  function self.isDrone(slot)
    if self.itemType(slot) == "drone" then
      return true
    else
      return false
    end
  end

  function self.checkInput()
    for slot=1,2 do
      if self.isPrincessSlotOccupied() == false then
        self.pullPrincess()
      end
      if self.isDroneSlotOccupied() == false then
        self.pullDrone()
      end
    end
  end

  function self.checkOutput()
    for slot=3,9 do
      local type = self.itemType(slot)
      if type ~= nil then
        if type == "princess" then
          if self.isPrincessSlotOccupied() == true then
            self.push(chestDir, slot)
          else
            self.movePrincess(slot)
          end
        elseif type == "drone" then
          if self.isDroneSlotOccupied() == true then
            self.push(chestDir, slot)
          else
            self.moveDrone(slot)
          end
        else
          self.push(chestDir, slot)
        end
      end
    end
  end

  function self.checkApiary()
    self.checkOutput()
    self.checkInput()
  end

  return self
end

-- End Apiary class
--------------------------------------------------------------------------------