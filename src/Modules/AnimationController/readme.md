# AnimationController

## Usage

### Auto-refreshing Animations from Configuration

```lua

local AnimationController = require(path.to.AnimationController)

local Animations = {
    Wave = "rbxassetid://0" --...
}

local AnimatorControllerInstance = AnimationController.new(Animations)

--- Somewhere else in the code

AnimatorControllerInstance:Play("Wave", { Looped = true }, --[[speed: number?, fadeTime: number?]])
AnimatorControllerInstance:Stop("Wave", --[[fadeTime: number?]])

local WaveTrack: AnimationTrack? = AnimatorControllerInstance:GetTrack("Wave")

-- The tracks will automatically be updated to the current working set for the current character model, 
-- so when the character respawns the animations are always going to be available to access 
-- without the need to clear up or reload them manually.
```