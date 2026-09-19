--// ControllerBag
--// Bag for storing initialised controllers on the client.

--/ ControllerBag
local ControllerBag = {}

local Controllers = {} :: { [string]: ControllerDef }

type ControllerDef = {
    Start: (self: ControllerDef) -> ()?,
	Started: boolean?,
    Name: string,
    FromBag: boolean?,
    [any]: any
}

export type Controller = {
	Name: string,
	Started: boolean?
}

local function DoesControllerExist(controllerName: string): boolean
	local controller: Controller? = Controllers[controllerName]

	return controller ~= nil
end

function ControllerBag.CreateController(controllerDef: ControllerDef): ControllerDef
	assert(type(controllerDef) == "table", `Controller must be a table; got {type(controllerDef)}`)
	assert(type(controllerDef.Name) == "string", `Controller.Name must be a string; got {type(controllerDef.Name)}`)
	assert(#controllerDef.Name > 0, "Controller.Name must be a non-empty string")
	assert(not DoesControllerExist(controllerDef.Name), `Controller {controllerDef.Name} already exists`)

	local controller = controllerDef
    controllerDef.FromBag = true
	controllerDef.Started = false
	Controllers[controller.Name] = controller

	return controller
end

function ControllerBag.GetController(controllerName: string): ControllerDef
	local controller = Controllers[controllerName]
	if controller then
		return controller
	end

	assert(type(controllerName) == "string", `ControllerName must be a string; got {type(controllerName)}`)
	error(`Could not find controller "{controllerName}". Check to verify a controller with this name exists.`, 2)
end

function ControllerBag.WaitForController(controllerName: string): ControllerDef
	local controller = Controllers[controllerName]
	if controller and controller.Started then
		return controller
	end

	local loadedController: ControllerDef = nil
	local startedWatchingTime = os.clock()
	local watcher = task.spawn(function()
		task.wait(10)
		if not loadedController then
			local theTimeSince = os.clock() - startedWatchingTime
			if theTimeSince < 300 then
				warn(`[ControllerBag] - Infinite yield possible on 'ControllerBag.WaitForController(\"{controllerName}\")'. Not found after {math.floor(theTimeSince)}s.`)
			elseif math.floor(theTimeSince) == 300 then
				warn(`[ControllerBag] - Infinite yield on 'ControllerBag.WaitForController(\"{controllerName}\")'. Not found after 5 minutes.`)
			end
		end
	end)

	repeat 
		task.wait(0.5)
		if not loadedController then
			loadedController = Controllers[controllerName]
		end
	until loadedController and loadedController.Started == true
	if watcher then
		pcall(function()
			task.cancel(watcher)
		end)
	end

	return loadedController
end

function ControllerBag.Start()
    for _, controller in Controllers do
        if controller.Start and controller.FromBag then
            print(`[ControllerBag] - Starting controller: {controller.Name}`)
			task.spawn(function()
				controller:Start()
				controller.Started = true
			end)
        end
    end
end

return ControllerBag