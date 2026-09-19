# TagTasker

## Usage

### Assigning Class to Tagged Instance
```lua
local TagTasker = require(path.to.TagTasker)

local ExampleClass = {}
ExampleClass.__index = ExampleClass

function ExampleClass.new(part: BasePart)
    local instance = {}
    setmetatable(instance, ExampleClass)

    instance.part = part
    instance:Hello()

    return instance
end

function ExampleClass:Hello()
    print(`I am {self.part:GetFullName()}!`)
end

function ExampleClass:Destroy()
    print(`Bye!`)
end

local TARGET_INSTANCE_TAG = "SomePart"

local CreatedObjects = {} -- Utility for keeping track for the sake of cleanup.

TagTasker.Bind(
    TARGET_INSTANCE_TAG,
    function(instance: Instance) -- Construction function
        -- ExampleClass.new
        CreatedObjects[instance] = ExampleClass.new(instance)
    end,
    function(instance: Instance) -- Destruction function
        if CreatedObjects[instance] then
            CreatedObjects[instance]:Destroy()
            CreatedObjects[instance] = nil
        end
    end
)
```