--// Player State Manager
--// CC: okzyrox

--/ Services
local Players = game:GetService("Players")

--/ Module
--- @class PlayerState
--- The Class for manipulating and retrieving player state values.
--- Player state values are internally [ValueBase] objects (Including [StringValue], [BoolValue], etc)
local PlayerState = {}

local ValueTypeMap = {
	BoolValue = "boolean",
	IntValue = "number",
	NumberValue = "number",
	StringValue = "string",
}

local function findNamespace(player: Player, containerName: string?): Instance?
	if not containerName or containerName == "" then
		return player
	end

	local container = player:FindFirstChild(containerName)
	if not container then
		return nil
	end

	return container
end

local function isValueObject(instance: Instance): boolean
	return instance:IsA("BoolValue")
		or instance:IsA("IntValue")
		or instance:IsA("NumberValue")
		or instance:IsA("StringValue")
end

--- Get's the value object for a specific key in namespace.
--- @param player -- The player to look in.
--- @param key -- The key of the value object to get (name).
--- @param containerName -- The namespace to look in. (Optional)
--- @return ValueBase? -- The value object if found, else nil.
function PlayerState:GetObject(player: Player, key: string, containerName: string?): ValueBase?
	local container = findNamespace(player, containerName)
	if not container then
		return nil
	end
	return container:FindFirstChild(key)
end

--- Waits for the value object for a specific key in namespace.
--- @param player -- The player to look in.
--- @param key -- The key of the value object to get (name).
--- @param containerName -- The namespace to look in. (Optional)
--- @param timeout -- Time in seconds to wait before giving up. (Optional, will Yield if not provided)
--- @return ValueBase? -- The value object if found, else nil.
--- @yields
function PlayerState:WaitForObject(player: Player, key: string, containerName: string?, timeout: number?): ValueBase?
	local container = findNamespace(player, containerName)
	if not container then
		if not containerName or containerName == "" then
			if timeout ~= nil then
				return player:WaitForChild(key, timeout) :: ValueBase?
			end
			return player:WaitForChild(key) :: ValueBase
		end
		local waitedContainer = nil
		if timeout ~= nil then
			waitedContainer = player:WaitForChild(containerName, timeout)
		else
			waitedContainer = player:WaitForChild(containerName)
		end
		if not waitedContainer then
			return nil
		end
		if timeout ~= nil then
			return waitedContainer:WaitForChild(key, timeout)
		end
		return waitedContainer:WaitForChild(key)
	end

	if timeout ~= nil then
		return container:WaitForChild(key, timeout)
	end

	return container:WaitForChild(key)
end

--- Get's the value of a specific key in namespace.
--- @param player -- The player to look in.
--- @param key -- The key of the value object to get (name).
--- @param containerName -- The namespace to look in. (Optional)
--- @return any? -- The value of the value object if found, else nil.
function PlayerState:Get(player: Player, key: string, containerName: string?): any
	local valueObject = self:GetObject(player, key, containerName)
	if not valueObject or not isValueObject(valueObject) then
		return nil
	end
	return (valueObject :: any).Value
end

--- Get's the value of a specific key in namespace for the LocalPlayer.
--- Alias of [PlayerState:Get]
--- @param key -- The key of the value object to get (name).
--- @param containerName -- The namespace to look in. (Optional)
--- @return any? -- The value of the value object if found, else nil.
function PlayerState:GetLocal(key: string, containerName: string?): any
	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		return nil
	end
	return self:Get(localPlayer, key, containerName)
end

--- Waits for the value of a specific key in namespace for the LocalPlayer.
--- Alias of [PlayerState:WaitForObject]
--- @param key -- The key of the value object to get (name).
--- @param containerName -- The namespace to look in. (Optional)
--- @param timeout -- Time in seconds to wait before giving up. (Optional, will Yield if not provided)
--- @return any? -- The value of the value object if found, else nil.
--- @yields
function PlayerState:WaitForLocal(key: string, containerName: string?, timeout: number?): any
	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		return nil
	end
	return self:WaitForObject(localPlayer, key, containerName, timeout)
end

--- Sets the value of a specific key in namespace.
--- @param player -- The player to look in.
--- @param key -- The key of the value object to set (name).
--- @param newValue -- The new value to set.
--- @param containerName -- The namespace to look in. (Optional)
--- @return boolean -- Whether the value was successfully set.
--- :::info 
--- [IntValue] objects will have the `number` type `newValue` rounded down to the nearest whole number. 
--- :::
--- If it cannot find the Value Object, or if the `newValue` is of the wrong type, it will return `false` and not set the value.
function PlayerState:Set(player: Player, key: string, newValue: any, containerName: string?): boolean
	local valueObject = self:GetObject(player, key, containerName)
	if not valueObject or not isValueObject(valueObject) then
		return false
	end

	local expectedType = ValueTypeMap[valueObject.ClassName]
	if expectedType and typeof(newValue) ~= expectedType then
		return false
	end

	if valueObject:IsA("IntValue") then
		(valueObject :: IntValue).Value = math.floor(newValue)
	else
		(valueObject :: any).Value = newValue
	end

	return true
end

--- Get's all key-value pairs in a namespace for a player.
--- @param player -- The player to look in.
--- @param containerName -- The namespace to look in. (Optional)
--- @return {[string]: any} -- A table of key-value pairs found in the namespace. Key is the name of the object.
function PlayerState:GetAll(player: Player, containerName: string?): {[string]: any}
	local out = {}
	local container = findNamespace(player, containerName)
	if not container then
		return out
	end

	for _, child in container:GetChildren() do
		if isValueObject(child) then
			out[child.Name] = (child :: any).Value
		end
	end

	return out
end

--- Get's all key-value pairs in a namespace for the LocalPlayer.
--- Alias of [PlayerState:GetAll]
--- @param containerName -- The namespace to look in. (Optional)
--- @return {[string]: any} -- A table of key-value pairs found in the namespace. Key is the name of the object.
function PlayerState:GetAllLocal(containerName: string?): {[string]: any}
	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		return {}
	end
	return self:GetAll(localPlayer, containerName)
end

return PlayerState