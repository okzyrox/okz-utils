# ControllerBag

## Usage

### Example Controller
```lua
-- ExampleController.luau

local ControllerBag = require(path.to.ControllerBag)

local ExampleController = ControllerBag.CreateController({
    Name = "ExampleController",
    ---...
})

function ExampleController:Hello()
    return "Hi!"
end

function ExampleController:Start()
end

return ExampleController
```

## Initialising Controllers
```lua
-- Init.client.luau
local ControllerBag = require(path.to.ControllerBag)
-- require all controllers to initialise the controllers
-- and then:
ControllerBag.Start()
```

## Accessing Controllers
```lua
-- SomeFile.luau
local ControllerBag = require(path.to.ControllerBag)

local ExampleController1 = ControllerBag.GetController("ExampleController") -- Will error if not found, assumes already initialised
local ExampleController2 = ControllerBag.WaitForController("ExampleController") -- Will wait until the controller has started, and then will return it.

print(ExampleController1:Hello()) --> "Hi!"

```