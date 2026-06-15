--// okzyrox utils

local ModuleFolder = script:WaitForChild("Modules")
local Modules = {
    AnimationController = ModuleFolder:WaitForChild("AnimationController"),
    PlayerState = ModuleFolder:WaitForChild("PlayerState"),
    TagTasker = ModuleFolder:WaitForChild("TagTasker"),
    Logger = ModuleFolder:WaitForChild("Logger"),
    Mouse = ModuleFolder:WaitForChild("Mouse"),
}

local Utils = {}
Utils.__index = Utils
Utils.Modules = table.freeze(Modules)

return Utils