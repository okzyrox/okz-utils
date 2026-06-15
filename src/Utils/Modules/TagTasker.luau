--// TagTasker
--// CC: okzyrox
--/ To automatically link and unlink functions to instances

local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")

--- @class TagTasker
--- A class used to bind Creation and Destruction functions to specific instances that have a certain tag.
local TagTasker = {}
TagTasker.__index = TagTasker

--/ Internal

local bindings: {
	[string]: {
		callback: (Instance) -> (),
		destroyCallback: (Instance) -> ()?,
		tasks: { [Instance]: thread }
	}
} = {}

local function stopTask(tag: string, obj: Instance)
	local binding = bindings[tag]
	if not binding then return end

	local runningTask = binding.tasks[obj]
	if runningTask then
		task.cancel(runningTask)
		binding.tasks[obj] = nil
	end
end

local function startTask(tag: string, obj: Instance)
	local binding = bindings[tag]
	if not binding then return end

	stopTask(tag, obj)

	local activeThread = task.spawn(binding.callback, obj)
	binding.tasks[obj] = activeThread

	obj.Destroying:Once(function()
		stopTask(tag, obj)
		if binding.destroyCallback then
			binding.destroyCallback(obj)
		end
	end)
end

--/ Public

--- Bind a tag to a callback function.
--- @param tag -- The tag to bind the function to. Whenever an instance with this tag is added, the callback will be fired with the instance as the argument.
--- @param callback -- The function to fire when an instance with the tag is added. The function will receive the instance as an argument.
--- @param destroyCallback -- The function to fire when an instance with the tag is removed. The function will receive the instance as an argument. (Optional)
function TagTasker.Bind(tag: string, callback: (Instance) -> (), destroyCallback: (Instance) -> ()?)
	if not bindings[tag] then
		bindings[tag] = {
			callback = callback,
			destroyCallback = destroyCallback,
			tasks = {}
		}

		CollectionService:GetInstanceAddedSignal(tag):Connect(function(obj)
			if obj:IsDescendantOf(ServerStorage) then
				return
			end
			startTask(tag, obj)
		end)

		CollectionService:GetInstanceRemovedSignal(tag):Connect(function(obj)
			stopTask(tag, obj)
		end)
	end

	for _, obj in CollectionService:GetTagged(tag) do
		if obj:IsDescendantOf(ServerStorage) then
			continue
		end
		startTask(tag, obj)
	end
end

--- Unbind a tag from the TagTasker. This will stop all currently running tasks for instances with this tag, and prevent any new tasks from starting for this tag.
--- @param tag -- The tag to unbind.
--- :::warning
--- This will not call any destructor callbacks on currently tagged instances, you must handle that yourself. This is to prevent accidentally cleaning up instances that don't need to be cleaned up.
--- :::
function TagTasker.Unbind(tag: string)
	local binding = bindings[tag]
	if not binding then return end

	for obj, activeThread in binding.tasks do
		task.cancel(activeThread)
	end

	bindings[tag] = nil
end

return TagTasker