--// AnimationController
--// CC: okzyrox & 2016porthope
--// Minimal animation manager with auto-reload

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--- @class AnimationController
--- A class for managing animations on a character or object, with automatic cleanup and auto-reloading on respawn for characters.
local AnimationController = {} :: AnimationController
AnimationController.__index = AnimationController

export type AnimationStore = Folder | ModuleScript | {[string]: string}

export type AnimationController = {
	--/ Constructors
	--[[
		Creates a new AnimationController for a player character
		@param animationFolder -- The folder or module containing animations. If ModuleScript, should return a table of `name`: `assetid` pairs

		@param isTool? -- Whether this AnimationController is being used for a tool. If true, will only clean up on death instead of character respawn, mainly to prevent memory leaks.
		@param player? -- The player to target for animations. Required if creating AnimationController on the Server; on Client, defaults to LocalPlayer.
	]]
	new: (animationFolder: AnimationStore, isTool: boolean?, player: Player?) -> AnimationController,
	--[[
		@deprecated Creates a new AnimationController for a tool. Use `new` with `isTool` parameter instead.

		@param animationFolder -- The folder containing animations.
		@param player? -- The player to target for animations.
		@param tool -- The tool to bind animations to. Must be equipped/unequipped to trigger animations.
	]]
	newTool: (animationFolder: Folder, player: Player?, tool: Tool) -> AnimationController,
	--[[
		Creates a new AnimationController for a non-character object with an Animator.
		@param animationFolder -- The folder or module containing animations. If ModuleScript, should return a table of `name`: `assetid` pairs
		@param target -- The instance to target for animations. Must have an Animator child.
	]]
	newObjectAnimator: (animationFolder: AnimationStore, target: Instance) -> AnimationController,
	--/ Methods
	--[[
		Play an animation by name.
		@param name -- The name of the animation to play. Must exist in the Animations table.
		@param properties? -- Optional properties to set on the AnimationTrack before playing, such as `Looped`.
		@param speed? -- Optional speed multiplier for the animation. Defaults to 1.
		@param weight? -- Optional weight for the animation when blending. Defaults to 0.
		@param fadeTime? -- Optional fade time for the animation
	]]
	Play: (self: AnimationController, name: string, properties: {[string]: any}?, speed: number?, weight: number?, fadeTime: number?) -> AnimationTrack?,
	--[[
		Stop an animation by name.
		@param name -- The name of the animation to stop.
		@param fadeTime -- Optional fade time
	]]
	Stop: (self: AnimationController, name: string, fadeTime: number?) -> (),
	--[[
		Stop all currently playing animations.
	]]
	StopAll: (self: AnimationController) -> (),
	--[[
		Clean up all resources used by this AnimationController. Should be called when no longer needed.
	]]
	Destroy: (self: AnimationController) -> (),
	--[[
		Get a loaded AnimationTrack
	]]
	GetTrack: (self: AnimationController, name: string) -> AnimationTrack?,

	--/ Player exclusive
	Player: Player?,
	Character: Model?,
	Humanoid: Humanoid?,
	--/ Model exclusive
	Object: Instance?, --/ optional target for non-character animations

	--/ Global
	Animator: Animator,

	Animations: {[string]: Animation},
	Tracks: {[string]: AnimationTrack},

	Connections: {RBXScriptConnection}
}

--- Creates a new AnimationController for a player character, with automatic cleanup on respawn.
--- @param animationFolder -- The folder or module containing animations. 
--- - If `animationFolder` is ModuleScript, should return a table of `name`: `assetid` pairs.
--- - If `animationFolder` is a Folder, should contain Animation objects as children.
--- @param isTool? -- Whether this AnimationController is being used for a tool. If true, will only clean up on death instead of character respawn, mainly to prevent memory leaks.
--- @param player? -- The player to target for animations. Required if creating AnimationController on the Server; on Client, defaults to LocalPlayer.
--- @return AnimationController -- The created AnimationController.
--- @yields
--- @error "No animation folder supplied for AnimationController!" --  If no animation folder is provided.
--- @error "No player supplied for AnimationController on Server-Side" -- If running on the server and no player is provided.
--- @error "Invalid animation folder type for AnimationController! Must be Folder or ModuleScript" -- If `animationFolder` is not a Folder, ModuleScript, or table of name-assetid pairs.
function AnimationController.new(animationFolder: Folder | ModuleScript, isTool: boolean?, player: Player?): AnimationController
	if not animationFolder then
		error("No animation folder supplied for AnimationController!")
	end

	if RunService:IsServer() and not player then
		error("No player supplied for AnimationController on Server-Side")
	end

	local self = setmetatable({}, AnimationController)

	if RunService:IsClient() then
		self.Player = Players.LocalPlayer
	elseif RunService:IsServer() then
		self.Player = player
	end

	self.Character = self.Player.Character or self.Player.CharacterAdded:Wait()
	self.Humanoid = self.Character:WaitForChild("Humanoid") :: Humanoid
	self.Animator = self.Humanoid:WaitForChild("Animator") :: Animator

	self.Animations = {}
	self.Tracks = {}
	self.Connections = {}
	if typeof(animationFolder) == "Instance" then
		if animationFolder:IsA("Folder") then
			for _, anim in ipairs(animationFolder:GetChildren()) do
				if anim:IsA("Animation") then
					self.Animations[anim.Name] = anim
				end
			end
		elseif animationFolder:IsA("ModuleScript") then
			local anims = require(animationFolder) :: {[string]: string} --/ name: assetid
			for name, animId in pairs(anims) do
				local anim = Instance.new("Animation")
				anim.Name = name
				anim.AnimationId = `{animId}`
				self.Animations[name] = anim
			end
		end
	elseif type(animationFolder) == "table" then
		for name, animId in pairs(animationFolder) do
			local anim = Instance.new("Animation")
			anim.Name = name
			anim.AnimationId = `{animId}`
			self.Animations[name] = anim
		end
	else
		error("Invalid animation folder type for AnimationController! Must be Folder or ModuleScript")
	end

	self:_PreLoadAnimations()

	--/ Only for if we have something like a script not in a tool;
	--/ otherwise it technically causes a memory leak
	if RunService:IsClient() and not isTool then
		table.insert(self.Connections, self.Player.CharacterAdded:Connect(function(char)
			self:_onCharacterAdded(char)
		end))
	else
		--/ destroy on death with tools
		table.insert(self.Connections, self.Humanoid.Died:Once(function()
			self:Destroy()
		end))
	end

	return self
end

--- Creates an animation controller for a non-character object containing an Animator.
--- @param animationFolder -- The folder or module containing animations. 
--- - If `animationFolder` is ModuleScript, should return a table of `name`: `assetid` pairs.
--- - If `animationFolder` is a Folder, should contain Animation objects as children.
--- @param target -- The instance to target for animations. Must have an Animator child.
--- @return AnimationController -- The created AnimationController.
--- @error "No animation folder supplied for AnimationController!" --  If no animation folder is provided.
--- @error "No target supplied for AnimationController object animator!" -- If no target instance is provided.
--- @error "No Animator found on target for AnimationController object animator! ..." -- If no Animator is found as a child of the target instance.

function AnimationController.newObjectAnimator(animationFolder: Folder | ModuleScript, target: Instance): AnimationController
	if not animationFolder then
		error("No animation folder supplied for AnimationController!")
	end

	if not target then
		error("No target supplied for AnimationController object animator!")
	end

	local self = setmetatable({}, AnimationController)

	self.Object = target
	self.Animator = target:FindFirstChildWhichIsA("Animator")
	if not self.Animator then
		error("No Animator found on target for AnimationController object animator! Animator must be a child of the target instance.")
	end

	self.Animations = {}
	self.Tracks = {}
	self.Connections = {}

	if animationFolder:IsA("Folder") then
		for _, anim in ipairs(animationFolder:GetChildren()) do
			if anim:IsA("Animation") then
				self.Animations[anim.Name] = anim
			end
		end
	elseif animationFolder:IsA("ModuleScript") then
		local anims = require(animationFolder) :: {[string]: string} --/ name: assetid
		for name, animId in pairs(anims) do
			local anim = Instance.new("Animation")
			anim.Name = name
			anim.AnimationId = `{animId}`
			self.Animations[name] = anim
		end
	elseif type(animationFolder) == "table" then
		for name, animId in pairs(animationFolder) do
			local anim = Instance.new("Animation")
			anim.Name = name
			anim.AnimationId = `{animId}`
			self.Animations[name] = anim
		end
	else
		error("Invalid animation folder type for AnimationController! Must be Folder, ModuleScript or name:assetid table")
	end

	return self 
end

--- @deprecated 0 -- Use `new` with `isTool` parameter instead.
--- Creates a new AnimationController for a tool, binding animations to the tool's Equipped and Unequipped events.
function AnimationController.newTool(animationFolder: Folder, player: Player?, tool: Tool): AnimationController
	local self = AnimationController.new(animationFolder, true, player)

	for animName, anim in pairs(self.Animations) do
		--/ equip/loop
		if animName == "OnEquip" then
			local onEq = tool.Equipped:Connect(function()
				self:Play("OnEquip", {}, nil, 1)
			end)
			local onUnEq = tool.Unequipped:Connect(function()
				self:Stop("OnEquip")
			end)

			table.insert(self.Connections, onEq)
			table.insert(self.Connections, onUnEq)
		end

		if animName == "OnLoop" then
			local onEq = tool.Equipped:Connect(function()
				self:Play("OnLoop", {Looped = true}, nil, 0)
			end)
			local onUnEq = tool.Unequipped:Connect(function()
				self:Stop("OnLoop")
			end)

			table.insert(self.Connections, onEq)
			table.insert(self.Connections, onUnEq)
		end
	end

	return self
end

--- @private
function AnimationController:_onCharacterAdded(char: Model)
	for name, track in pairs(self.Tracks) do
		pcall(function()
			track:Stop()
			track:Destroy()
		end)
	end

	self.Tracks = {}

	-- Reacquire
	self.Character = char
	self.Humanoid = char:WaitForChild("Humanoid")
	self.Animator = self.Humanoid:WaitForChild("Animator")
	self:_PreLoadAnimations()
end

--- @private
function AnimationController:_PreLoadAnimations()
	for AnimationName, Animation in self.Animations do
		if not self.Tracks[AnimationName] then
			local track = self.Animator:LoadAnimation(Animation)
			self.Tracks[AnimationName] = track
		end
	end
end

--- Play an animation by name, with optional customisatiion properties, speed, weight and fade time.
--- @param name -- The name of the animation to play. Must exist in the Animations table.
--- @param properties? -- Properties to set on the AnimationTrack before playing, such as `Looped`. (Optional)
--- @param speed? -- Speed multiplier for the animation. (Optional, Defaults to 1.)
--- @param weight? -- Weight for the animation when blending. (Optional, Defaults to 0.)
--- @param fadeTime? -- Fade time for the animation. (Optional, Defaults to 0 (no fade).)
--- @return AnimationTrack? -- The AnimationTrack that was played, or nil if the animation was not found.
function AnimationController:Play(name: string, properties: {[string]: any}?, speed: number?, weight: number?, fadeTime: number?): AnimationTrack?
	local anim = self.Animations[name]
	if not anim then
		warn("[AnimationController] Animation not found:", name)
		return
	end

	if not self.Tracks[name] then
		local track = self.Animator:LoadAnimation(anim)
		self.Tracks[name] = track
	end

	local track: AnimationTrack = self.Tracks[name]

	if properties then
		for key, val in pairs(properties) do
			pcall(function()
				track[key] = val
			end)
		end
	end

	track:Play(fadeTime, weight, speed)
	return track
end

--- Stop an animation by name, with optional fade time.
--- @param name -- The name of the animation to stop.
--- @param fadeTime -- Fade time for stopping the animation. (Optional, Defaults to 0 (no fade))
function AnimationController:Stop(name: string, fadeTime: number?)
	local track = self.Tracks[name]
	if track and track.IsPlaying then
		track:Stop(fadeTime or 0)
	end
end

--- Stop all currently playing animations.
function AnimationController:StopAll()
	for _, track in pairs(self.Tracks) do
		track:Stop()
	end
end

--- Get a loaded AnimationTrack by name.
--- @param name -- The name of the animation track to get.
--- @return AnimationTrack? -- The AnimationTrack if found, else nil.
function AnimationController:GetTrack(name: string): AnimationTrack?
	return self.Tracks[name]
end

--- Destructor for the AnimationController, cleans everything up and disconnects events.
function AnimationController:Destroy()
	for _, connection in ipairs(self.Connections) do
		connection:Disconnect()
	end

	for _, track in pairs(self.Tracks) do
		pcall(function()
			track:Stop()
			track:Destroy()
		end)
	end

	self.Tracks = {}
end

return AnimationController