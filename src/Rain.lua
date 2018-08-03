--[[
	
	Rain module v1.0 by buildthomas (July 2018)
	
	This module is licensed under the APLv2:
	http://www.apache.org/licenses/LICENSE-2.0
	
	In short, you may use this code only if you agree to the following:
	* This notice must always be present and may not be modified or removed in any copy of this code or derived code.
	* You may use this in commercial, closed source projects, and you may modify the source code itself.
	
	Refer to the license for a full description.
	
	For questions please reach out on the Developer Forum (@buildthomas)
	or via Twitter (https://www.twitter.com/buildthomasRBX)
	
	------
	
	
	Rain:Enable(<TweenInfo> tweenInfo)
		Enable the rain effects instantly, or over a given easing function if tweenInfo is given.
		
	Rain:Disable(<TweenInfo> tweenInfo)
		Disable the rain effects instantly, or over a given easing function if tweenInfo is given.
		
		
	Rain:SetColor(<Color3> color, <TweenInfo> tweenInfo)
		Set the global color of all rain particles to a given Color3 value.
		Sets the color instantly, or over a given easing function if tweenInfo is given.
		Color sequences are not supported because this would lead to a messy effect.
		The starting value is RAIN_DEFAULT_COLOR.
		
	Rain:SetTransparency(<number> transparency, <TweenInfo> tweenInfo)
		Set the global transparency of all rain effects. 0 = regular visibility, 1 = fully invisible.
		Sets the transparency instantly, or over a given easing function if tweenInfo is given.
		Clamped between 0 and 1, the starting value is RAIN_DEFAULT_TRANSPARENCY.
	
	Rain:SetSpeedRatio(<number> ratio, <TweenInfo> tweenInfo)
		Set the vertical falling speed of the rain particles. 0 = still, 1 = max falling speed.
		Sets the speed instantly, or over a given easing function if tweenInfo is given.
		Clamped between 0 and 1, the starting value is RAIN_DEFAULT_SPEEDRATIO.
		
	Rain:SetIntensityRatio(<number> ratio, <TweenInfo> tweenInfo)
		Set the intensity of the rain. 0 = no effects, 1 = full effects.
		Sets the intensity instantly, or over a given easing function if tweenInfo is given.
		Clamped between 0 and 1, the starting value is RAIN_DEFAULT_INTENSITYRATIO.
		
	Rain:SetLightEmission(<number> ratio, <TweenInfo> tweenInfo)
		Set the global light emission of all rain effects.
		Sets the light emission instantly, or over a given easing function if tweenInfo is given.
		Clamped between 0 and 1, the starting value is RAIN_DEFAULT_LIGHTEMISSION.
		
	Rain:SetLightInfluence(<number> transparency, <TweenInfo> tweenInfo)
		Set the global light influence of all rain effects.
		Sets the light influence instantly, or over a given easing function if tweenInfo is given.
		Clamped between 0 and 1, the starting value is RAIN_DEFAULT_LIGHTINFLUENCE.
		
		
	Rain:SetVolume(<number> volume, <TweenInfo> tweenInfo)
		Set the global max volume of rain instantly, or over a given easing function if tweenInfo is given.
		The initial volume of the rain's soundgroup is RAIN_SOUND_BASEVOLUME.
		
		
	Rain:SetCeiling(<Variant<number, nil>> ceiling)
		Set a Y coordinate that marks the ceiling of the world. Above this spot, rain will act as if it's indoors.
		Feed nil to remove any previously set ceiling.
		
		
	Rain:SetDirection(<Vector3> direction, <TweenInfo> tweenInfo)
		Set the direction that rain falls from. The direction parameter should be a unit direction.
		Sets the rain direction instantly, or over a given easing function if tweenInfo is given.
		
	Rain:SetStraightTexture(<string> asset)
	Rain:SetTopDownTexture(<string> asset)
	Rain:SetSplashTexture(<string> asset)
		Adjust textures of the rain effect.
		
	Rain:SetSoundId(<string> asset)
		Adjust sound effect of the rain effect.
		
	Rain:SetCollisionMode(<Rain.CollisionMode> mode, ...)
		Sets the current way collisions are determined for the rain.
		
		Rain.CollisionMode
			A table that should be seen as an enumerator for the collision mode.
			The following values are available:
			* Rain.CollisionMode.None			- All parts in the default collision group will block the rain.
			* Rain.CollisionMode.Whitelist		- Use the whitelist provided by Rain::SetCollisionWhitelist.
			* Rain.CollisionMode.Blacklist		- Use the blacklist provided by Rain::SetCollisionBlacklist.
			* Rain.CollisionMode.Function		- Use the test function provided by Rain::SetCollisionFunction and do deep-casts.
			
		Rain:SetCollisionMode(Rain.CollisionMode.None)
			No parameters.
			
		Rain:SetCollisionMode(Rain.CollisionMode.Whitelist, <Variant<Instance, table>> whitelist)
			The provided value can either be a hierarchy of objects or a table of objects to filter with.
		
		Rain:SetCollisionMode(Rain.CollisionMode.Blacklist, <Variant<Instance, table>> blacklist)
			The provided value can either be a hierarchy of objects or a table of objects to filter out.
			
		Rain:SetCollisionMode(Rain.CollisionMode.Function, <function<BasePart -> boolean>> f)
			If f(part) returns a value that lua evaluates to a true condition, that part can be hit by rain.
			If f(part) returns any other value, that part cannot be hit by the rain.
			
	
--]]

-- Options:

local MIN_SIZE = Vector3.new(0.05,0.05,0.05)				-- Size of main emitter part when rain inactive

local RAIN_DEFAULT_COLOR = Color3.new(1,1,1)				-- Default color3 of all rain elements
local RAIN_DEFAULT_TRANSPARENCY = 0							-- Default transparency scale ratio of all rain elements
local RAIN_DEFAULT_SPEEDRATIO = 1							-- Default speed scale ratio of falling rain effects
local RAIN_DEFAULT_INTENSITYRATIO = 1						-- Default intensity ratio of all rain elements
local RAIN_DEFAULT_LIGHTEMISSION = 0.05						-- Default LightEmission of all rain elements
local RAIN_DEFAULT_LIGHTINFLUENCE = 0.9						-- Default LightInfluence of all rain elements
local RAIN_DEFAULT_DIRECTION = Vector3.new(0,-1,0)			-- Default direction for rain to fall into

local RAIN_TRANSPARENCY_T1 = .25							-- Define the shape (time-wise) of the transparency curves for emitters
local RAIN_TRANSPARENCY_T2 = .75

local RAIN_SCANHEIGHT = 1000								-- How many studs to scan up from camera position to determine whether occluded

local RAIN_EMITTER_DIM_DEFAULT = 40							-- Size of emitter block to the side/up
local RAIN_EMITTER_DIM_MAXFORWARD = 100						-- Size of emitter block forwards when looking at the horizon
local RAIN_EMITTER_UP_MODIFIER = 20							-- Maximum vertical displacement of emitter (when looking fully up/down)

local RAIN_SOUND_ASSET = "rbxassetid://1516791621"
local RAIN_SOUND_BASEVOLUME = 0.2							-- Starting volume of rain sound effect when not occluded
local RAIN_SOUND_FADEIN_TIME = 1							-- Tween in/out times for sound volume
local RAIN_SOUND_FADEOUT_TIME = 1

local RAIN_STRAIGHT_ASSET = "rbxassetid://1822883048"		-- Some properties of the straight rain particle effect
local RAIN_STRAIGHT_ALPHA_LOW = 0.7							-- Minimum particle transparency for the straight rain emitter
local RAIN_STRAIGHT_SIZE = NumberSequence.new(10)
local RAIN_STRAIGHT_LIFETIME = NumberRange.new(0.8)
local RAIN_STRAIGHT_MAX_RATE = 600							-- Maximum rate for the straight rain emitter
local RAIN_STRAIGHT_MAX_SPEED = 60							-- Maximum speed for the straight rain emitter

local RAIN_TOPDOWN_ASSET = "rbxassetid://1822856633"		-- Some properties of the top-down rain particle effect
local RAIN_TOPDOWN_ALPHA_LOW = 0.85							-- Minimum particle transparency for the top-down rain emitter
local RAIN_TOPDOWN_SIZE = NumberSequence.new {
	NumberSequenceKeypoint.new(0, 5.33, 2.75);
	NumberSequenceKeypoint.new(1, 5.33, 2.75);
}			
local RAIN_TOPDOWN_LIFETIME = NumberRange.new(0.8)
local RAIN_TOPDOWN_ROTATION = NumberRange.new(0,360)
local RAIN_TOPDOWN_MAX_RATE = 600							-- Maximum rate for the top-down rain emitter
local RAIN_TOPDOWN_MAX_SPEED = 60							-- Maximum speed for the top-down rain emitter

local RAIN_SPLASH_ASSET = "rbxassetid://1822856633"			-- Some properties of the splash particle effect
local RAIN_SPLASH_ALPHA_LOW = 0.6							-- Minimum particle transparency for the splash emitters
local RAIN_SPLASH_SIZE = NumberSequence.new {				
	NumberSequenceKeypoint.new(0, 0);
	NumberSequenceKeypoint.new(.4, 3);
	NumberSequenceKeypoint.new(1, 0);
}
local RAIN_SPLASH_LIFETIME = NumberRange.new(0.1, 0.15)
local RAIN_SPLASH_ROTATION = NumberRange.new(0,360)
local RAIN_SPLASH_NUM = 20									-- Amount of splashes per frame
local RAIN_SPLASH_CORRECTION_Y = .5							-- Offset from impact position for visual reasons
local RAIN_SPLASH_STRAIGHT_OFFSET_Y = 50					-- Offset against rain direction for straight rain particles from splash position
local RAIN_NOSPLASH_STRAIGHT_OFFSET_Y_MIN = 20				-- Min/max vertical offset from camera height for straight rain particles
local RAIN_NOSPLASH_STRAIGHT_OFFSET_Y_MAX = 100				-- when no splash position could be found (i.e. no floor at that XZ-column)

local RAIN_OCCLUDED_MINSPEED = 70							-- Minimum speed for the occluded straight rain emitters
local RAIN_OCCLUDED_MAXSPEED = 100							-- Maximum speed for the occluded straight rain emitters
local RAIN_OCCLUDED_SPREAD = Vector2.new(10,10)				-- Spread angle for the occluded straight rain emitters
local RAIN_OCCLUDED_MAXINTENSITY = 2						-- How many occluded straight rain particles are emitted for every splash for max intensity

local RAIN_OCCLUDECHECK_OFFSET_Y = 500						-- Vertical offset from camera height to start scanning downward from for splashes
local RAIN_OCCLUDECHECK_OFFSET_XZ_MIN = -100				-- Range of possible XZ offset values from camera XZ position for the splashes
local RAIN_OCCLUDECHECK_OFFSET_XZ_MAX = 100
local RAIN_OCCLUDECHECK_SCAN_Y = 550						-- Scan magnitude along rain path

local RAIN_UPDATE_PERIOD = 6								-- Update the transparency of the main emitters + volume of rain inside every X frames

local RAIN_VOLUME_SCAN_RADIUS = 35							-- Defining grid for checking how far the camera is away from a spot exposed to rain
local RAIN_VOLUME_SCAN_GRID = {								-- Unit range grid for scanning how far away user is from rain space
	-- range 0.2, 4 pts
	Vector3.new(0.141421363, 0, 0.141421363);
	Vector3.new(-0.141421363, 0, 0.141421363);
	Vector3.new(-0.141421363, 0, -0.141421363);
	Vector3.new(0.141421363, 0, -0.141421363);
	-- range 0.4, 8 pts
	Vector3.new(0.400000006, 0, 0);
	Vector3.new(0.282842726, 0, 0.282842726);
	Vector3.new(2.44929371e-17, 0, 0.400000006);
	Vector3.new(-0.282842726, 0, 0.282842726);
	Vector3.new(-0.400000006, 0, 4.89858741e-17);
	Vector3.new(-0.282842726, 0, -0.282842726);
	Vector3.new(-7.34788045e-17, 0, -0.400000006);
	Vector3.new(0.282842726, 0, -0.282842726);
	-- range 0.6, 10 pts
	Vector3.new(0.600000024, 0, 0);
	Vector3.new(0.485410213, 0, 0.352671146);
	Vector3.new(0.185410202, 0, 0.570633948);
	Vector3.new(-0.185410202, 0, 0.570633948);
	Vector3.new(-0.485410213, 0, 0.352671146);
	Vector3.new(-0.600000024, 0, 7.34788112e-17);
	Vector3.new(-0.485410213, 0, -0.352671146);
	Vector3.new(-0.185410202, 0, -0.570633948);
	Vector3.new(0.185410202, 0, -0.570633948);
	Vector3.new(0.485410213, 0, -0.352671146);
	-- range 0.8, 12 pts
	Vector3.new(0.772740662, 0, 0.207055241);
	Vector3.new(0.565685451, 0, 0.565685451);
	Vector3.new(0.207055241, 0, 0.772740662);
	Vector3.new(-0.207055241, 0, 0.772740662);
	Vector3.new(-0.565685451, 0, 0.565685451);
	Vector3.new(-0.772740662, 0, 0.207055241);
	Vector3.new(-0.772740662, 0, -0.207055241);
	Vector3.new(-0.565685451, 0, -0.565685451);
	Vector3.new(-0.207055241, 0, -0.772740662);
	Vector3.new(0.207055241, 0, -0.772740662);
	Vector3.new(0.565685451, 0, -0.565685451);
	Vector3.new(0.772740662, 0, -0.207055241);
}


-- Enumerators:

local CollisionMode = {
	None = 0;
	Whitelist = 1;
	Blacklist = 2;
	Function = 3;
}


-- Variables & setup:

-- services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local GlobalModifier = Instance.new("NumberValue")			-- modifier for rain visibility for disabling/enabling over time span
GlobalModifier.Value = 1									-- 0 = fully visible, 1 = invisible

local connections = {}										-- Stores connections to RunService signals when enabled

local disabled = true										-- Value to figure out whether we are moving towards a disabled state (useful during tweens)

local rainDirection = RAIN_DEFAULT_DIRECTION				-- Direction that rain falls into

local currentCeiling = nil									-- Y coordinate of ceiling (if present)

local collisionMode = CollisionMode.None					-- Collision mode (from Rain.CollisionMode) for raycasting
local collisionList = nil									-- Blacklist/whitelist for raycasting
local collisionFunc = nil									-- Raycasting test function for when collisionMode == Rain.CollisionMode.Function

local straightLowAlpha = 1									-- Current transparency for straight rain particles
local topdownLowAlpha = 1									-- Current transparency for top-down rain particles
local intensityOccludedRain = 0								-- Current intensity of occluded rain particles
local numSplashes = 0										-- Current number of generated splashes per frame
local volumeTarget = 0										-- Current (target of tween for) sound volume

-- shorthands
local v3 = Vector3.new
local NSK010 = NumberSequenceKeypoint.new(0, 1, 0)
local NSK110 = NumberSequenceKeypoint.new(1, 1, 0)

local volumeScanGrid = {}									-- Pre-generate grid used for raining area distance scanning
for _,v in pairs(RAIN_VOLUME_SCAN_GRID) do
	table.insert(volumeScanGrid, v * RAIN_VOLUME_SCAN_RADIUS)
end
table.sort(volumeScanGrid, function(a,b)					-- Optimization: sort from close to far away for fast evaluation if closeby
	return a.magnitude < b.magnitude
end)

-- sound group for easy main volume tweaking
local SoundGroup = Instance.new("SoundGroup")
SoundGroup.Name = "__RainSoundGroup"
SoundGroup.Volume = RAIN_SOUND_BASEVOLUME
SoundGroup.Archivable = false

local Sound = Instance.new("Sound")
Sound.Name = "RainSound"
Sound.Volume = volumeTarget
Sound.SoundId = RAIN_SOUND_ASSET
Sound.Looped = true
Sound.SoundGroup = SoundGroup
Sound.Parent = SoundGroup
Sound.Archivable = false

-- emitter block around camera used when outside
local Emitter do
	
	Emitter = Instance.new("Part")
	Emitter.Transparency = 1
	Emitter.Anchored = true
	Emitter.CanCollide = false
	Emitter.Locked = false
	Emitter.Archivable = false
	Emitter.TopSurface = Enum.SurfaceType.Smooth
	Emitter.BottomSurface = Enum.SurfaceType.Smooth
	Emitter.Name = "__RainEmitter"
	Emitter.Size = MIN_SIZE
	Emitter.Archivable = false
	
	local straight = Instance.new("ParticleEmitter")
	straight.Name = "RainStraight"
	straight.LightEmission = RAIN_DEFAULT_LIGHTEMISSION
	straight.LightInfluence = RAIN_DEFAULT_LIGHTINFLUENCE
	straight.Size = RAIN_STRAIGHT_SIZE
	straight.Texture = RAIN_STRAIGHT_ASSET
	straight.LockedToPart = true
	straight.Enabled = false
	straight.Lifetime = RAIN_STRAIGHT_LIFETIME
	straight.Rate = RAIN_STRAIGHT_MAX_RATE
	straight.Speed = NumberRange.new(RAIN_STRAIGHT_MAX_SPEED)
	straight.EmissionDirection = Enum.NormalId.Bottom
	straight.Parent = Emitter
	
	local topdown = Instance.new("ParticleEmitter")
	topdown.Name = "RainTopDown"
	topdown.LightEmission = RAIN_DEFAULT_LIGHTEMISSION
	topdown.LightInfluence = RAIN_DEFAULT_LIGHTINFLUENCE
	topdown.Size = RAIN_TOPDOWN_SIZE
	topdown.Texture = RAIN_TOPDOWN_ASSET
	topdown.LockedToPart = true
	topdown.Enabled = false
	topdown.Rotation = RAIN_TOPDOWN_ROTATION
	topdown.Lifetime = RAIN_TOPDOWN_LIFETIME
	topdown.Rate = RAIN_TOPDOWN_MAX_RATE
	topdown.Speed = NumberRange.new(RAIN_TOPDOWN_MAX_SPEED)
	topdown.EmissionDirection = Enum.NormalId.Bottom
	topdown.Parent = Emitter
	
end

local splashAttachments, rainAttachments do
	
	splashAttachments = {}
	rainAttachments = {}
	
	for i = 1, RAIN_SPLASH_NUM do
		
		-- splashes on ground
		local splashAttachment = Instance.new("Attachment")
		splashAttachment.Name = "__RainSplashAttachment"
		local splash = Instance.new("ParticleEmitter")
		splash.LightEmission = RAIN_DEFAULT_LIGHTEMISSION
		splash.LightInfluence = RAIN_DEFAULT_LIGHTINFLUENCE
		splash.Size = RAIN_SPLASH_SIZE
		splash.Texture = RAIN_SPLASH_ASSET
		splash.Rotation = RAIN_SPLASH_ROTATION
		splash.Lifetime = RAIN_SPLASH_LIFETIME
		splash.Transparency = NumberSequence.new {
			NSK010;
			NumberSequenceKeypoint.new(RAIN_TRANSPARENCY_T1, RAIN_SPLASH_ALPHA_LOW, 0);
			NumberSequenceKeypoint.new(RAIN_TRANSPARENCY_T2, RAIN_SPLASH_ALPHA_LOW, 0);
			NSK110;
		}
		splash.Enabled = false
		splash.Rate = 0
		splash.Speed = NumberRange.new(0)
		splash.Name = "RainSplash"
		splash.Parent = splashAttachment
		splashAttachment.Archivable = false
		table.insert(splashAttachments, splashAttachment)
		
		-- occluded rain particle generation
		local rainAttachment = Instance.new("Attachment")
		rainAttachment.Name = "__RainOccludedAttachment"
		local straightOccluded = Emitter.RainStraight:Clone()
		straightOccluded.Speed = NumberRange.new(RAIN_OCCLUDED_MINSPEED, RAIN_OCCLUDED_MAXSPEED)
		straightOccluded.SpreadAngle = RAIN_OCCLUDED_SPREAD
		straightOccluded.LockedToPart = false
		straightOccluded.Enabled = false
		straightOccluded.Parent = rainAttachment
		local topdownOccluded = Emitter.RainTopDown:Clone()
		topdownOccluded.Speed = NumberRange.new(RAIN_OCCLUDED_MINSPEED, RAIN_OCCLUDED_MAXSPEED)
		topdownOccluded.SpreadAngle = RAIN_OCCLUDED_SPREAD
		topdownOccluded.LockedToPart = false
		topdownOccluded.Enabled = false
		topdownOccluded.Parent = rainAttachment
		rainAttachment.Archivable = false
		table.insert(rainAttachments, rainAttachment)
		
	end
	
end


-- Helper methods:

local ignoreEmitterList = { Emitter }

local raycastFunctions = {
	[CollisionMode.None] = function(ray, ignoreCharacter)
		return workspace:FindPartOnRayWithIgnoreList(ray, ignoreCharacter and {Emitter, Players.LocalPlayer and Players.LocalPlayer.Character} or ignoreEmitterList)
	end;
	[CollisionMode.Blacklist] = function(ray)
		return workspace:FindPartOnRayWithIgnoreList(ray, collisionList)
	end;
	[CollisionMode.Whitelist] = function(ray)
		return workspace:FindPartOnRayWithWhitelist(ray, collisionList)
	end;
	[CollisionMode.Function] = function(ray)
		local destination = ray.Origin + ray.Direction
		-- draw multiple raycasts concatenated to each other until no hit / valid hit found
		while ray.Direction.magnitude > 0.001 do
			local part, pos, norm, mat = workspace:FindPartOnRayWithIgnoreList(ray, ignoreEmitterList)
			if not part or collisionFunc(part) then
				return part, pos, norm, mat
			end
			local start = pos + ray.Direction.Unit * 0.001
			ray = Ray.new(start, destination - start)
		end
	end;
}
local raycast = raycastFunctions[collisionMode]

local function connectLoop()
	
	local rand = Random.new()
	
	local inside = true					-- Whether camera is currently in a spot occluded from the sky
	local frame = RAIN_UPDATE_PERIOD	-- Frame counter, and force update cycle right now
	
	-- Update Emitter on RenderStepped since it needs to be synced to Camera
	table.insert(connections, RunService.RenderStepped:connect(function()
		
		-- Check if camera is outside or inside
		local part, position = raycast(Ray.new(workspace.CurrentCamera.CFrame.p, -rainDirection * RAIN_SCANHEIGHT), true)
		
		if (not currentCeiling or workspace.CurrentCamera.CFrame.p.y <= currentCeiling) and not part then
			
			-- Camera is outside and under ceiling
				
			if volumeTarget < 1 and not disabled then
				volumeTarget = 1
				TweenService:Create(Sound, TweenInfo.new(.5), {Volume = 1}):Play()
			end
			
			frame = RAIN_UPDATE_PERIOD
			
			local t = math.abs(workspace.CurrentCamera.CFrame.lookVector:Dot(rainDirection))
			
			local center = workspace.CurrentCamera.CFrame.p
			local right = workspace.CurrentCamera.CFrame.lookVector:Cross(-rainDirection)
			right = right.magnitude > 0.001 and right.unit or -rainDirection
			local forward = rainDirection:Cross(right).unit
			
			Emitter.Size = v3(
				RAIN_EMITTER_DIM_DEFAULT,
				RAIN_EMITTER_DIM_DEFAULT,
				RAIN_EMITTER_DIM_DEFAULT + (1 - t)*(RAIN_EMITTER_DIM_MAXFORWARD - RAIN_EMITTER_DIM_DEFAULT)
			)
			
			Emitter.CFrame =
				CFrame.new(
					center.x, center.y, center.z,
					right.x, -rainDirection.x, forward.x,
					right.y, -rainDirection.y, forward.y,
					right.z, -rainDirection.z, forward.z
				)
				+ (1 - t) * workspace.CurrentCamera.CFrame.lookVector * Emitter.Size.Z/3
				- t * rainDirection * RAIN_EMITTER_UP_MODIFIER
			
			Emitter.RainStraight.Enabled = true
			Emitter.RainTopDown.Enabled = true
			
			inside = false
			
		else
			
			-- Camera is inside / above ceiling
			
			Emitter.RainStraight.Enabled = false
			Emitter.RainTopDown.Enabled = false
		
			inside = true
			
		end
		
	end))

	-- Do the other effects on Stepped
	local signal = RunService:IsRunning() and RunService.Stepped or RunService.RenderStepped
	table.insert(connections, signal:connect(function()
		
		frame = frame + 1
		
		-- Only do some updates once every few frames
		if frame >= RAIN_UPDATE_PERIOD then
			
			-- Measure of how much camera is facing down (0-1)
			local t = math.abs(workspace.CurrentCamera.CFrame.lookVector:Dot(rainDirection))
			
			-- More looking down = see straight particles less and see top-down particles more
			local straightSequence = NumberSequence.new {
				NSK010;
				NumberSequenceKeypoint.new(RAIN_TRANSPARENCY_T1, (1 - t)*straightLowAlpha + t, 0);
				NumberSequenceKeypoint.new(RAIN_TRANSPARENCY_T2, (1 - t)*straightLowAlpha + t, 0);
				NSK110;
			}
			local topdownSequence = NumberSequence.new {
				NSK010;
				NumberSequenceKeypoint.new(RAIN_TRANSPARENCY_T1, t*topdownLowAlpha + (1 - t), 0);
				NumberSequenceKeypoint.new(RAIN_TRANSPARENCY_T2, t*topdownLowAlpha + (1 - t), 0);
				NSK110;
			}
			
			-- Find desired rotation for the straight rain particles
			local mapped = workspace.Camera.CFrame:inverse() * (workspace.Camera.CFrame.p - rainDirection)
			local straightRotation = NumberRange.new(math.deg(math.atan2(-mapped.x, mapped.y)))
			
			if inside then
				
				-- Update emitter properties
				for _,v in pairs(rainAttachments) do
					v.RainStraight.Transparency = straightSequence
					v.RainStraight.Rotation = straightRotation
					v.RainTopDown.Transparency = topdownSequence
				end
				
				if not disabled then
					
					-- Only do occluded volume check if not moving towards disabled state
					
					local volume = 0
					
					if (not currentCeiling or workspace.CurrentCamera.CFrame.p.y <= currentCeiling) then
						
						-- Check how far away camera is from a space open to the sky using volume scan grid
						
						local minDistance = RAIN_VOLUME_SCAN_RADIUS
						local rayDirection = -rainDirection * RAIN_SCANHEIGHT
						
						for i = 1, #volumeScanGrid do -- In order, so first hit is closest
							if not raycast(Ray.new(workspace.CurrentCamera.CFrame * volumeScanGrid[i], rayDirection), true) then
								minDistance = volumeScanGrid[i].magnitude
								break
							end
						end
						
						-- Volume is inversely proportionate to minimum distance
						volume = 1 - minDistance / RAIN_VOLUME_SCAN_RADIUS
						
					end
					
					if math.abs(volume - volumeTarget) > .01 then
						-- Value is sufficiently different from previous target, overwrite it
						volumeTarget = volume
						TweenService:Create(Sound, TweenInfo.new(1), {Volume = volumeTarget}):Play()
					end
					
				end
				
			else
				
				-- Update emitter properties
				Emitter.RainStraight.Transparency = straightSequence
				Emitter.RainStraight.Rotation = straightRotation
				Emitter.RainTopDown.Transparency = topdownSequence
				
			end
			
			-- Reset frame counter
			frame = 0
			
		end
		
		local center = workspace.CurrentCamera.CFrame.p
		local right = workspace.CurrentCamera.CFrame.lookVector:Cross(-rainDirection)
		right = right.magnitude > 0.001 and right.unit or -rainDirection
		local forward = rainDirection:Cross(right).unit
		local transform = CFrame.new(
			center.x, center.y, center.z,
			right.x, -rainDirection.x, forward.x,
			right.y, -rainDirection.y, forward.y,
			right.z, -rainDirection.z, forward.z
		)
		local rayDirection = rainDirection * RAIN_OCCLUDECHECK_SCAN_Y
		
		-- Splash and occlusion effects
		for i = 1, numSplashes do
			
			local splashAttachment = splashAttachments[i]
			local rainAttachment = rainAttachments[i]
			
			-- Sample random splash position
			local x = rand:NextNumber(RAIN_OCCLUDECHECK_OFFSET_XZ_MIN, RAIN_OCCLUDECHECK_OFFSET_XZ_MAX)
			local z = rand:NextNumber(RAIN_OCCLUDECHECK_OFFSET_XZ_MIN, RAIN_OCCLUDECHECK_OFFSET_XZ_MAX)
			local part, position, normal = raycast(Ray.new(transform * v3(x, RAIN_OCCLUDECHECK_OFFSET_Y, z), rayDirection))
			
			if part then
				
				-- Draw a splash at hit
				splashAttachment.Position = position + normal * RAIN_SPLASH_CORRECTION_Y
				splashAttachment.RainSplash:Emit(1)
				
				if inside then
					
					-- Draw occlusion rain particles a little bit above the splash position
					local corrected = position - rainDirection * RAIN_SPLASH_STRAIGHT_OFFSET_Y
					if currentCeiling and corrected.Y > currentCeiling and rainDirection.Y < 0 then
						corrected = corrected + rainDirection * (currentCeiling - corrected.Y) / rainDirection.Y
					end
					rainAttachment.CFrame = transform - transform.p + corrected
					rainAttachment.RainStraight:Emit(intensityOccludedRain)
					rainAttachment.RainTopDown:Emit(intensityOccludedRain)
					
				end
				
			elseif inside then
				
				-- Draw occlusion rain particles on the XZ-position at around the camera's height
				local corrected = transform * v3(x, rand:NextNumber(RAIN_NOSPLASH_STRAIGHT_OFFSET_Y_MIN, RAIN_NOSPLASH_STRAIGHT_OFFSET_Y_MAX), z)
				if currentCeiling and corrected.Y > currentCeiling and rainDirection.Y < 0 then
					corrected = corrected + rainDirection * (currentCeiling - corrected.Y) / rainDirection.Y
				end
				rainAttachment.CFrame = transform - transform.p + corrected
				rainAttachment.RainStraight:Emit(intensityOccludedRain)
				rainAttachment.RainTopDown:Emit(intensityOccludedRain)
				
			end
			
		end
		
	end))

end

local function disconnectLoop()
	-- If present, disconnect all RunService connections
	if #connections > 0 then
		for _,v in pairs(connections) do
			v:disconnect()
		end
		connections = {}
	end
end

local function disableSound(tweenInfo)
	
	-- Tween the rain sound to be mute over a given easing function
	volumeTarget = 0
	local tween = TweenService:Create(Sound, tweenInfo, {Volume = 0})
	tween.Completed:connect(function(state)
		if state == Enum.PlaybackState.Completed then
			Sound:Stop()
		end
		tween:Destroy()
	end)
	tween:Play()
	
end

local function disable()
	
	disconnectLoop()
	
	-- Hide Emitter
	Emitter.RainStraight.Enabled = false
	Emitter.RainTopDown.Enabled = false
	Emitter.Size = MIN_SIZE
	
	-- Disable sound now if not tweened into disabled state beforehand
	if not disabled then
		disableSound(TweenInfo.new(RAIN_SOUND_FADEOUT_TIME))
	end
	
end

-- Shorthand for creating a tweenable "variable" using value object
local function makeProperty(valueObjectClass, defaultValue, setter)
	local valueObject = Instance.new(valueObjectClass)
	if defaultValue then
		valueObject.Value = defaultValue
	end
	valueObject.Changed:connect(setter)
	setter(valueObject.Value)
	return valueObject
end

local Color = makeProperty("Color3Value", RAIN_DEFAULT_COLOR, function(value)
	
	local value = ColorSequence.new(value)
	
	Emitter.RainStraight.Color = value
	Emitter.RainTopDown.Color = value
	
	for _,v in pairs(splashAttachments) do
		v.RainSplash.Color = value
	end
	for _,v in pairs(rainAttachments) do
		v.RainStraight.Color = value
		v.RainTopDown.Color = value
	end
	
end)

local function updateTransparency(value)
	
	local opacity = (1 - value) * (1 - GlobalModifier.Value)
	local transparency = 1 - opacity
	
	straightLowAlpha = RAIN_STRAIGHT_ALPHA_LOW * opacity + transparency
	topdownLowAlpha = RAIN_TOPDOWN_ALPHA_LOW * opacity + transparency
	
	local splashSequence = NumberSequence.new {
		NSK010;
		NumberSequenceKeypoint.new(RAIN_TRANSPARENCY_T1, opacity*RAIN_SPLASH_ALPHA_LOW + transparency, 0);
		NumberSequenceKeypoint.new(RAIN_TRANSPARENCY_T2, opacity*RAIN_SPLASH_ALPHA_LOW + transparency, 0);
		NSK110;
	}
	
	for _,v in pairs(splashAttachments) do
		v.RainSplash.Transparency = splashSequence
	end
	
end
local Transparency = makeProperty("NumberValue", RAIN_DEFAULT_TRANSPARENCY, updateTransparency)
GlobalModifier.Changed:connect(updateTransparency)

local SpeedRatio = makeProperty("NumberValue", RAIN_DEFAULT_SPEEDRATIO, function(value)
	
	Emitter.RainStraight.Speed = NumberRange.new(value * RAIN_STRAIGHT_MAX_SPEED)
	Emitter.RainTopDown.Speed = NumberRange.new(value * RAIN_TOPDOWN_MAX_SPEED)
	
end)

local IntensityRatio = makeProperty("NumberValue", RAIN_DEFAULT_INTENSITYRATIO, function(value)
	
	Emitter.RainStraight.Rate = RAIN_STRAIGHT_MAX_RATE * value
	Emitter.RainTopDown.Rate = RAIN_TOPDOWN_MAX_RATE * value
	
	intensityOccludedRain = math.ceil(RAIN_OCCLUDED_MAXINTENSITY * value)
	numSplashes = RAIN_SPLASH_NUM * value
	
end)

local LightEmission = makeProperty("NumberValue", RAIN_DEFAULT_LIGHTEMISSION, function(value)
	
	Emitter.RainStraight.LightEmission = value
	Emitter.RainTopDown.LightEmission = value
	
	for _,v in pairs(rainAttachments) do
		v.RainStraight.LightEmission = value
		v.RainTopDown.LightEmission = value
	end
	for _,v in pairs(splashAttachments) do
		v.RainSplash.LightEmission = value
	end
	
end)

local LightInfluence = makeProperty("NumberValue", RAIN_DEFAULT_LIGHTINFLUENCE, function(value)
	
	Emitter.RainStraight.LightInfluence = value
	Emitter.RainTopDown.LightInfluence = value
	
	for _,v in pairs(rainAttachments) do
		v.RainStraight.LightInfluence = value
		v.RainTopDown.LightInfluence = value
	end
	for _,v in pairs(splashAttachments) do
		v.RainSplash.LightInfluence = value
	end
	
end)

local RainDirection = makeProperty("Vector3Value", RAIN_DEFAULT_DIRECTION, function(value)
	if value.magnitude > 0.001 then
		rainDirection = value.unit
	end
end)


-- Exposed API:

local Rain = {}

Rain.CollisionMode = CollisionMode

function Rain:Enable(tweenInfo)
	
	if tweenInfo ~= nil and typeof(tweenInfo) ~= "TweenInfo" then
		error("bad argument #1 to 'Enable' (TweenInfo expected, got " .. typeof(tweenInfo) .. ")", 2)
	end
	
	disconnectLoop() -- Just in case :Enable(..) is called multiple times on accident
	
	Emitter.RainStraight.Enabled = true
	Emitter.RainTopDown.Enabled = true
	Emitter.Parent = workspace.CurrentCamera
	
	for i = 1, RAIN_SPLASH_NUM do
		splashAttachments[i].Parent = workspace.Terrain
		rainAttachments[i].Parent = workspace.Terrain
	end
	
	if RunService:IsRunning() then -- don't need sound in studio preview, it won't work anyway
		SoundGroup.Parent = game:GetService("SoundService")
	end
	
	connectLoop()
	
	if tweenInfo then
		TweenService:Create(GlobalModifier, tweenInfo, {Value = 0}):Play()
	else
		GlobalModifier.Value = 0
	end
	
	if not Sound.Playing then
		Sound:Play()
		Sound.TimePosition = math.random()*Sound.TimeLength
	end
	
	disabled = false
	
end

function Rain:Disable(tweenInfo)
	
	if tweenInfo ~= nil and typeof(tweenInfo) ~= "TweenInfo" then
		error("bad argument #1 to 'Disable' (TweenInfo expected, got " .. typeof(tweenInfo) .. ")", 2)
	end
	
	if tweenInfo then
		local tween = TweenService:Create(GlobalModifier, tweenInfo, {Value = 1})
		tween.Completed:connect(function(state)
			if state == Enum.PlaybackState.Completed then
				-- Only disable the rain completely once the visual effects are faded out
				disable()
			end
			tween:Destroy()
		end)
		tween:Play()
		-- Start tweening out sound now as well
		disableSound(tweenInfo)
	else
		GlobalModifier.Value = 1
		disable()
	end
	
	disabled = true
	
end

function Rain:SetColor(value, tweenInfo)
		
	if typeof(value) ~= "Color3" then
		error("bad argument #1 to 'SetColor' (Color3 expected, got " .. typeof(value) .. ")", 2)
	elseif tweenInfo ~= nil and typeof(tweenInfo) ~= "TweenInfo" then
		error("bad argument #2 to 'SetColor' (TweenInfo expected, got " .. typeof(tweenInfo) .. ")", 2)
	end
	
	if tweenInfo then
		TweenService:Create(Color, tweenInfo, {Value = value}):Play()
	else
		Color.Value = value
	end
	
end

local function makeRatioSetter(methodName, valueObject)
	-- Shorthand because most of the remaining property setters are very similar
	return function(_, value, tweenInfo)
		
		if typeof(value) ~= "number" then
			error("bad argument #1 to '" .. methodName .. "' (number expected, got " .. typeof(value) .. ")", 2)
		elseif tweenInfo ~= nil and typeof(tweenInfo) ~= "TweenInfo" then
			error("bad argument #2 to '" .. methodName .. "' (TweenInfo expected, got " .. typeof(tweenInfo) .. ")", 2)
		end
		
		value = math.clamp(value, 0, 1)
		
		if tweenInfo then
			TweenService:Create(valueObject, tweenInfo, {Value = value}):Play()
		else
			valueObject.Value = value
		end
		
	end
end

Rain.SetTransparency = makeRatioSetter("SetTransparency", Transparency)
Rain.SetSpeedRatio = makeRatioSetter("SetSpeedRatio", SpeedRatio)
Rain.SetIntensityRatio = makeRatioSetter("SetIntensityRatio", IntensityRatio)
Rain.SetLightEmission = makeRatioSetter("SetLightEmission", LightEmission)
Rain.SetLightInfluence = makeRatioSetter("SetLightInfluence", LightInfluence)

function Rain:SetVolume(volume, tweenInfo)
	
	if typeof(volume) ~= "number" then
		error("bad argument #1 to 'SetVolume' (number expected, got " .. typeof(volume) .. ")", 2)
	elseif tweenInfo ~= nil and typeof(tweenInfo) ~= "TweenInfo" then
		error("bad argument #2 to 'SetVolume' (TweenInfo expected, got " .. typeof(tweenInfo) .. ")", 2)
	end
	
	if tweenInfo then
		TweenService:Create(SoundGroup, tweenInfo, {Volume = volume}):Play()
	else
		SoundGroup.Volume = volume
	end
	
end

function Rain:SetDirection(direction, tweenInfo)
	
	if typeof(direction) ~= "Vector3" then
		error("bad argument #1 to 'SetDirection' (Vector3 expected, got " .. typeof(direction) .. ")", 2)
	elseif tweenInfo ~= nil and typeof(tweenInfo) ~= "TweenInfo" then
		error("bad argument #2 to 'SetDirection' (TweenInfo expected, got " .. typeof(tweenInfo) .. ")", 2)
	end
	
	if not (direction.unit.magnitude > 0) then -- intentional statement formatting since NaN comparison
		warn("Attempt to set rain direction to a zero-length vector, falling back on default direction = (" .. tostring(RAIN_DEFAULT_DIRECTION) .. ")")
		direction = RAIN_DEFAULT_DIRECTION
	end
	
	if tweenInfo then
		TweenService:Create(RainDirection, tweenInfo, {Value = direction}):Play()
	else
		RainDirection.Value = direction
	end
	
end

function Rain:SetCeiling(ceiling)
	
	if ceiling ~= nil and typeof(ceiling) ~= "number" then
		error("bad argument #1 to 'SetCeiling' (number expected, got " .. typeof(ceiling) .. ")", 2)
	end
	
	currentCeiling = ceiling
	
end

function Rain:SetStraightTexture(asset)
	
	if typeof(asset) ~= "string" then
		error("bad argument #1 to 'SetStraightTexture' (string expected, got " .. typeof(asset) .. ")", 2)
	end
	
	Emitter.RainStraight.Texture = asset
	
	for _,v in pairs(rainAttachments) do
		v.RainStraight.Texture = asset
	end
	
end

function Rain:SetTopDownTexture(asset)
	
	if typeof(asset) ~= "string" then
		error("bad argument #1 to 'SetStraightTexture' (string expected, got " .. typeof(asset) .. ")", 2)
	end
	
	Emitter.RainTopDown.Texture = asset
	
	for _,v in pairs(rainAttachments) do
		v.RainTopDown.Texture = asset
	end
	
end

function Rain:SetSplashTexture(asset)
	
	if typeof(asset) ~= "string" then
		error("bad argument #1 to 'SetStraightTexture' (string expected, got " .. typeof(asset) .. ")", 2)
	end
	
	for _,v in pairs(splashAttachments) do
		v.RainSplash.Texture = asset
	end
	
end

function Rain:SetSoundId(asset)
	
	if typeof(asset) ~= "string" then
		error("bad argument #1 to 'SetSoundId' (string expected, got " .. typeof(asset) .. ")", 2)
	end
	
	Sound.SoundId = asset
	
end

function Rain:SetCollisionMode(mode, param)
	
	if mode == CollisionMode.None then
		
		-- Regular mode needs no white/blacklist or test function
		collisionList = nil
		collisionFunc = nil
		
	elseif mode == CollisionMode.Blacklist then
		
		if typeof(param) == "Instance" then
			-- Add Emitter anyway, since users will probably not expect collisions with emitter block regardless
			collisionList = {param, Emitter}
		elseif typeof(param) == "table" then
			for i = 1, #param do
				if typeof(param[i]) ~= "Instance" then
					error("bad argument #2 to 'SetCollisionMode' (blacklist contained a " .. typeof(param[i]) .. " on index " .. tostring(i) .. " which is not an Instance)", 2)
				end
			end
			collisionList = {Emitter} -- see above
			for i = 1, #param do
				table.insert(collisionList, param[i])
			end
		else
			error("bad argument #2 to 'SetCollisionMode (Instance or array of Instance expected, got " .. typeof(param) .. ")'", 2)
		end
		
		-- Blacklist does not need a test function
		collisionFunc = nil
		
	elseif mode == CollisionMode.Whitelist then
		
		if typeof(param) == "Instance" then
			collisionList = {param}
		elseif typeof(param) == "table" then
			for i = 1, #param do
				if typeof(param[i]) ~= "Instance" then
					error("bad argument #2 to 'SetCollisionMode' (whitelist contained a " .. typeof(param[i])  .. " on index " .. tostring(i) .. " which is not an Instance)", 2)
				end
			end
			collisionList = {}
			for i = 1, #param do
				table.insert(collisionList, param[i])
			end
		else
			error("bad argument #2 to 'SetCollisionMode (Instance or array of Instance expected, got " .. typeof(param) .. ")'", 2)
		end
		
		-- Whitelist does not need a test function
		collisionFunc = nil
		
	elseif mode == CollisionMode.Function then
		
		if typeof(param) ~= "function" then
			error("bad argument #2 to 'SetCollisionMode' (function expected, got " .. typeof(param) .. ")", 2)
		end
		
		-- Test function does not need a list
		collisionList = nil
		
		collisionFunc = param
		
	else
		error("bad argument #1 to 'SetCollisionMode (Rain.CollisionMode expected, got " .. typeof(param) .. ")'", 2)
	end
	
	collisionMode = mode
	raycast = raycastFunctions[mode]
	
end

return Rain
