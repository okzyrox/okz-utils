--// Mouse
--// CC: okzyrox
--/ Alternative to Player:GetMouse().Target (as that ignores the player's character itself!!!!!)

--/ Services
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

--/ Config
local RAY_DISTANCE = 1000

--/ Module
--- @class Mouse
--- Utility functions to replace the builtin Roblox [Mouse] object, which has inconsitencies with `Target` and raycasts.
local Mouse = {}

--- Casts a ray from the camera to the mouse position, and returns the result. This is the base function for the other two functions, [Mouse.Hit] and [Mouse.HitPosition].
--- @param raycastParams -- The RaycastParams to use for the raycast. (Optional)
--- @param distance -- The maximum distance from the camera that the raycast can hit. (Optional, defaults to 1000)
--- @return (RaycastResult?, Vector3) -- The result of the raycast, and the position that was hit or the end position of the ray if nothing was hit.
function Mouse.Cast(raycastParams: RaycastParams?, distance: number?): (RaycastResult?, Vector3)
	if not raycastParams then
		raycastParams = RaycastParams.new()
	end

	local cam = workspace.CurrentCamera
	local mousePos = UserInputService:GetMouseLocation()

	local viewportMouseRay = cam:ViewportPointToRay(mousePos.X, mousePos.Y)
	local rayCastResult = workspace:Raycast(viewportMouseRay.Origin, viewportMouseRay.Direction * RAY_DISTANCE, raycastParams)

	local hitPosition
	if rayCastResult then
		hitPosition = rayCastResult.Position
	else
		hitPosition = viewportMouseRay.Origin + viewportMouseRay.Direction * RAY_DISTANCE
	end

	if distance then
		local character = Players.LocalPlayer.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")

		if rootPart then
			-- check from the root part; so that we dont have to worry about camera zoom BS
			local distFromCharacter = (hitPosition - rootPart.Position).Magnitude

			-- void if too far
			if distFromCharacter > distance then
				rayCastResult = nil
			end
		else
			local distFromCam = (hitPosition - viewportMouseRay.Origin).Magnitude
			if distFromCam > distance then
				rayCastResult = nil
			end
		end
	end

	return rayCastResult, hitPosition
end

--- Returns the instance that the mouse is currently hovering over. A replacement to the `Mouse.Target` property of the Roblox `Mouse` object.
--- @param raycastParams -- The RaycastParams to use for the raycast. (Optional)
--- @param distance -- The maximum distance from the camera that the raycast can hit. (Optional, defaults to 1000)
--- @return Instance? -- The instance that the mouse is currently hovering over, or nil if it is not hovering over anything.
function Mouse.Hit(raycastParams: RaycastParams?, distance: number): Instance?
	if not raycastParams then
		raycastParams = RaycastParams.new()
	end
	
	local result, position = Mouse.Cast(raycastParams, distance)
	if result then
		return result.Instance
	else
		return nil
	end
end

--- Returns the position that the mouse is currently hovering over.
--- @param raycastParams -- The RaycastParams to use for the raycast. (Optional)
--- @param distance -- The maximum distance from the camera that the raycast can hit. (Optional, defaults to 1000)
--- @return Vector3 -- The position that the mouse is currently hovering over, or the end position of the ray if it is not hovering over anything.
function Mouse.HitPosition(raycastParams: RaycastParams?, distance: number): Vector3
	if not raycastParams then
		raycastParams = RaycastParams.new()
	end

	local result, position = Mouse.Cast(raycastParams, distance)
	return position
end


return Mouse