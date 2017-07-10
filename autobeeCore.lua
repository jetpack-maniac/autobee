--- Configuration

-- Whether or not apiary space will be checked, this allows basic overflow protection
-- This can cause lag on computers that have lots of apiaries, it can be safely turned off
-- if you regularly extract from your apiary and dump chest
checkSpace = true

-- Overflow protection (Requries checkSpace = true else does not function)
-- How many apiary slots need to be free before starting a new generation, if less is available
-- then AutoBee will not restart that apiary until space becomes available
requiredSpace = 3

-- The max size of the output inventory
chestSize = 27

-- chest direction relative to apiary
chestDir = "up"

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
  local status = {
    queen = nil,
    princess = nil,
    drones = 0,
    space = 0
  }
  local mode = "standard"

  function self.getID()
    return address
  end

  function self.isFull()
    if status.space == nil then return false end
    if status.space < requiredSpace then return true
    else return false end
  end

  function self.mode()
    return mode
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

  function self.emptySlot(slot)
    local type = self.itemType(slot)
    if type ~= nil then
      if type == "princess" then
        if self.queen == true or self.princess == true then
          self.push(chestDir, slot)
        elseif checkSpace == true and status.space >= requiredSpace then
          self.movePrincess(slot)
        end
      elseif type == "drone" then
        if status.drones == 64 then
          self.push(chestDir, slot)
        elseif checkSpace == true and status.space >= requiredSpace then
          self.moveDrone(slot)
          self.push(chestDir, slot)
        end
      else
        self.push(chestDir, slot)
      end
    end
  end

  function self.checkInput()
    if checkSpace == true and status.space >= requiredSpace then return end
    for slot=1,2 do
      if status.queen == false and status.princess == false then
        self.pullPrincess()
      end
      if status.drones < 64 then
        self.pullDrone()
      end
    end
  end

  function self.checkOutput()
    for slot=3,9 do
      self.emptySlot(slot)
    end
  end

  function self.apiarySpaceCheck()
  local freeSlots = 0
    for slot=3,9 do
      local stack = self.getItemData(slot)
      if stack == nil then
        freeSlots = freeSlots+1
      end
    end
    return freeSlots
  end

  function self.checkApiary()
    self.getStatus()
    self.checkOutput()
    self.checkInput()
  end

  function self.getStatus()
    local queenStatus, princessStatus, apiarySpace
    local droneCount = self.getItemData(2)
    if self.itemType(1) == "queen" then queenStatus = true else queenStatus = false end
    if self.itemType(1) == "princess" then princessStatus = true else princessStatus = false end
    if droneCount == nil then droneCount = 0 else droneCount = droneCount.count end
    if checkSpace == true then
      apiarySpace = self.apiarySpaceCheck()
    else
      apiarySpace = nil
    end
    status = {queen = queenStatus, princess = princessStatus, drones = droneCount, space = apiarySpace }
    return status
  end

  return self
end

-- End Apiary class
--------------------------------------------------------------------------------