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
            * Rain.CollisionMode.Params			- Use the RaycastParams provided to Rain::SetCollisionMode.
            * Rain.CollisionMode.Function		- Use the test function provided to Rain::SetCollisionMode and do deep-casts.
            * Rain.CollisionMode.Whitelist		- Deprecated, use Rain.CollisionMode.Params instead.
            * Rain.CollisionMode.Blacklist		- Deprecated, use Rain.CollisionMode.Params instead.

        Rain:SetCollisionMode(Rain.CollisionMode.None)
            No parameters.

        Rain:SetCollisionMode(Rain.CollisionMode.Params, <RaycastParams> params)
            The provided params are used for every cast the rain makes.

        Rain:SetCollisionMode(Rain.CollisionMode.Function, <function<BasePart -> boolean>> f)
            If f(part) returns a value that lua evaluates to a true condition, that part can be hit by rain.
            If f(part) returns any other value, that part cannot be hit by the rain.

        Rain:SetCollisionMode(Rain.CollisionMode.Whitelist, <Variant<Instance, table>> whitelist)
            The provided value can either be a hierarchy of objects or a table of objects to filter with.

        Rain:SetCollisionMode(Rain.CollisionMode.Blacklist, <Variant<Instance, table>> blacklist)
            The provided value can either be a hierarchy of objects or a table of objects to filter out.
            
    
--]]

-- Options:

local MIN_SIZE = Vector3.new(0.05, 0.05, 0.05) -- Size of main emitter part when rain inactive

local RAIN_DEFAULT_COLOR = Color3.new(1, 1, 1) -- Default color3 of all rain elements
local RAIN_DEFAULT_TRANSPARENCY = 0 -- Default transparency scale ratio of all rain elements
local RAIN_DEFAULT_SPEEDRATIO = 1 -- Default speed scale ratio of falling rain effects
local RAIN_DEFAULT_INTENSITYRATIO = 1 -- Default intensity ratio of all rain elements
local RAIN_DEFAULT_LIGHTEMISSION = 0.05 -- Default LightEmission of all rain elements
local RAIN_DEFAULT_LIGHTINFLUENCE = 0.9 -- Default LightInfluence of all rain elements
local RAIN_DEFAULT_DIRECTION = Vector3.new(0, -1, 0) -- Default direction for rain to fall into

local RAIN_TRANSPARENCY_T1 = 0.25 -- Define the shape (time-wise) of the transparency curves for emitters
local RAIN_TRANSPARENCY_T2 = 0.75

local RAIN_SCANHEIGHT = 1000 -- How many studs to scan up from camera position to determine whether occluded

local RAIN_EMITTER_DIM_DEFAULT = 40 -- Size of emitter block to the side/up
local RAIN_EMITTER_DIM_MAXFORWARD = 100 -- Size of emitter block forwards when looking at the horizon
local RAIN_EMITTER_UP_MODIFIER = 20 -- Maximum vertical displacement of emitter (when looking fully up/down)

local RAIN_SOUND_ASSET = "rbxassetid://1516791621"
local RAIN_SOUND_BASEVOLUME = 0.2 -- Starting volume of rain sound effect when not occluded
local RAIN_SOUND_FADEOUT_TIME = 1

local RAIN_STRAIGHT_ASSET = "rbxassetid://1822883048" -- Some properties of the straight rain particle effect
local RAIN_STRAIGHT_ALPHA_LOW = 0.7 -- Minimum particle transparency for the straight rain emitter
local RAIN_STRAIGHT_SIZE = NumberSequence.new(10)
local RAIN_STRAIGHT_LIFETIME = NumberRange.new(0.8)
local RAIN_STRAIGHT_MAX_RATE = 600 -- Maximum rate for the straight rain emitter
local RAIN_STRAIGHT_MAX_SPEED = 60 -- Maximum speed for the straight rain emitter

local RAIN_TOPDOWN_ASSET = "rbxassetid://1822856633" -- Some properties of the top-down rain particle effect
local RAIN_TOPDOWN_ALPHA_LOW = 0.85 -- Minimum particle transparency for the top-down rain emitter
local RAIN_TOPDOWN_SIZE = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 5.33, 2.75),
    NumberSequenceKeypoint.new(1, 5.33, 2.75),
})
local RAIN_TOPDOWN_LIFETIME = NumberRange.new(0.8)
local RAIN_TOPDOWN_ROTATION = NumberRange.new(0, 360)
local RAIN_TOPDOWN_MAX_RATE = 600 -- Maximum rate for the top-down rain emitter
local RAIN_TOPDOWN_MAX_SPEED = 60 -- Maximum speed for the top-down rain emitter

local RAIN_SPLASH_ASSET = "rbxassetid://1822856633" -- Some properties of the splash particle effect
local RAIN_SPLASH_ALPHA_LOW = 0.6 -- Minimum particle transparency for the splash emitters
local RAIN_SPLASH_SIZE = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(0.4, 3),
    NumberSequenceKeypoint.new(1, 0),
})
local RAIN_SPLASH_LIFETIME = NumberRange.new(0.1, 0.15)
local RAIN_SPLASH_ROTATION = NumberRange.new(0, 360)
local RAIN_SPLASH_NUM = 20 -- Amount of splashes per frame
local RAIN_SPLASH_CORRECTION_Y = 0.5 -- Offset from impact position for visual reasons
local RAIN_SPLASH_STRAIGHT_OFFSET_Y = 50 -- Offset against rain direction for straight rain particles from splash position
local RAIN_NOSPLASH_STRAIGHT_OFFSET_Y_MIN = 20 -- Min/max vertical offset from camera height for straight rain particles
local RAIN_NOSPLASH_STRAIGHT_OFFSET_Y_MAX = 100 -- when no splash position could be found (i.e. no floor at that XZ-column)

local RAIN_OCCLUDED_MINSPEED = 70 -- Minimum speed for the occluded straight rain emitters
local RAIN_OCCLUDED_MAXSPEED = 100 -- Maximum speed for the occluded straight rain emitters
local RAIN_OCCLUDED_LIFETIME = NumberRange.new(RAIN_SPLASH_STRAIGHT_OFFSET_Y / RAIN_OCCLUDED_MAXSPEED)
local RAIN_OCCLUDED_SPREAD = Vector2.new(10, 10) -- Spread angle for the occluded straight rain emitters
local RAIN_OCCLUDED_MAXINTENSITY = 2 -- How many occluded straight rain particles are emitted for every splash for max intensity

local RAIN_OCCLUDECHECK_OFFSET_Y = 500 -- Vertical offset from camera height to start scanning downward from for splashes
local RAIN_OCCLUDECHECK_OFFSET_XZ_MIN = -100 -- Range of possible XZ offset values from camera XZ position for the splashes
local RAIN_OCCLUDECHECK_OFFSET_XZ_MAX = 100
local RAIN_OCCLUDECHECK_SCAN_Y = 550 -- Scan magnitude along rain path

local RAIN_UPDATE_PERIOD = 6 -- Update the transparency of the main emitters + volume of rain inside every X frames

local RAIN_VOLUME_SCAN_RADIUS = 35 -- Defining grid for checking how far the camera is away from a spot exposed to rain
local RAIN_VOLUME_SCAN_GRID = { -- Unit range grid for scanning how far away user is from rain space
    -- range 0.2, 4 pts
    Vector3.new(0.141421363, 0, 0.141421363),
    Vector3.new(-0.141421363, 0, 0.141421363),
    Vector3.new(-0.141421363, 0, -0.141421363),
    Vector3.new(0.141421363, 0, -0.141421363),
    -- range 0.4, 8 pts
    Vector3.new(0.400000006, 0, 0),
    Vector3.new(0.282842726, 0, 0.282842726),
    Vector3.new(2.44929371e-17, 0, 0.400000006),
    Vector3.new(-0.282842726, 0, 0.282842726),
    Vector3.new(-0.400000006, 0, 4.89858741e-17),
    Vector3.new(-0.282842726, 0, -0.282842726),
    Vector3.new(-7.34788045e-17, 0, -0.400000006),
    Vector3.new(0.282842726, 0, -0.282842726),
    -- range 0.6, 10 pts
    Vector3.new(0.600000024, 0, 0),
    Vector3.new(0.485410213, 0, 0.352671146),
    Vector3.new(0.185410202, 0, 0.570633948),
    Vector3.new(-0.185410202, 0, 0.570633948),
    Vector3.new(-0.485410213, 0, 0.352671146),
    Vector3.new(-0.600000024, 0, 7.34788112e-17),
    Vector3.new(-0.485410213, 0, -0.352671146),
    Vector3.new(-0.185410202, 0, -0.570633948),
    Vector3.new(0.185410202, 0, -0.570633948),
    Vector3.new(0.485410213, 0, -0.352671146),
    -- range 0.8, 12 pts
    Vector3.new(0.772740662, 0, 0.207055241),
    Vector3.new(0.565685451, 0, 0.565685451),
    Vector3.new(0.207055241, 0, 0.772740662),
    Vector3.new(-0.207055241, 0, 0.772740662),
    Vector3.new(-0.565685451, 0, 0.565685451),
    Vector3.new(-0.772740662, 0, 0.207055241),
    Vector3.new(-0.772740662, 0, -0.207055241),
    Vector3.new(-0.565685451, 0, -0.565685451),
    Vector3.new(-0.207055241, 0, -0.772740662),
    Vector3.new(0.207055241, 0, -0.772740662),
    Vector3.new(0.565685451, 0, -0.565685451),
    Vector3.new(0.772740662, 0, -0.207055241),
}

-- Enumerators:

local CollisionMode = {
    None = 0,
    Params = 1,
    Function = 2,
    Whitelist = 3,
    Blacklist = 4,
}
export type CollisionMode = keyof<typeof(CollisionMode)>

-- Variables & setup:

-- services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local GlobalModifier = Instance.new("NumberValue") -- modifier for rain visibility for disabling/enabling over time span
GlobalModifier.Value = 1 -- 0 = fully visible, 1 = invisible

local connections = {} -- Stores connections to RunService signals when enabled

local disabled = true -- Value to figure out whether we are moving towards a disabled state (useful during tweens)

local rainDirection = RAIN_DEFAULT_DIRECTION -- Direction that rain falls into

local currentCeiling = nil -- Y coordinate of ceiling (if present)

local collisionMode = CollisionMode.None -- Collision mode (from Rain.CollisionMode) for raycasting
local collisionFunc = nil -- Raycasting test function for when collisionMode == Rain.CollisionMode.Function
local collisionParams = nil -- User-supplied params for when collisionMode == Rain.CollisionMode.Params

local straightLowAlpha = 1 -- Current transparency for straight rain particles
local topdownLowAlpha = 1 -- Current transparency for top-down rain particles
local intensityOccludedRain = 0 -- Current intensity of occluded rain particles
local numSplashes = 0 -- Current number of generated splashes per frame
local volumeTarget = 0 -- Current (target of tween for) sound volume

-- shorthands
local v3 = Vector3.new
local NSK010 = NumberSequenceKeypoint.new(0, 1, 0)
local NSK110 = NumberSequenceKeypoint.new(1, 1, 0)

local volumeScanGrid = {} -- Pre-generate grid used for raining area distance scanning
for _, v in RAIN_VOLUME_SCAN_GRID do
    table.insert(volumeScanGrid, v * RAIN_VOLUME_SCAN_RADIUS)
end
table.sort(volumeScanGrid, function(a, b) -- Optimization: sort from close to far away for fast evaluation if closeby
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
local Emitter, EmitterStraight, EmitterTopDown
do
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
    EmitterStraight = straight
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
    straight.Orientation = Enum.ParticleOrientation.FacingCameraWorldUp

    local topdown = Instance.new("ParticleEmitter")
    EmitterTopDown = topdown
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

local splashAttachments, rainAttachments
local splashEmitters, occludedStraightEmitters, occludedTopDownEmitters
do
    splashAttachments = {}
    rainAttachments = {}
    splashEmitters = {}
    occludedStraightEmitters = {}
    occludedTopDownEmitters = {}

    for _ = 1, RAIN_SPLASH_NUM do
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
        splash.Transparency = NumberSequence.new({
            NSK010,
            NumberSequenceKeypoint.new(RAIN_TRANSPARENCY_T1, RAIN_SPLASH_ALPHA_LOW, 0),
            NumberSequenceKeypoint.new(RAIN_TRANSPARENCY_T2, RAIN_SPLASH_ALPHA_LOW, 0),
            NSK110,
        })
        splash.Enabled = false
        splash.Rate = 0
        splash.Speed = NumberRange.new(0)
        splash.Name = "RainSplash"
        splash.Parent = splashAttachment
        splashAttachment.Archivable = false
        table.insert(splashAttachments, splashAttachment)
        table.insert(splashEmitters, splash)

        -- occluded rain particle generation
        local rainAttachment = Instance.new("Attachment")
        rainAttachment.Name = "__RainOccludedAttachment"
        local straightOccluded = EmitterStraight:Clone()
        straightOccluded.Speed = NumberRange.new(RAIN_OCCLUDED_MINSPEED, RAIN_OCCLUDED_MAXSPEED)
        straightOccluded.Lifetime = RAIN_OCCLUDED_LIFETIME
        straightOccluded.SpreadAngle = RAIN_OCCLUDED_SPREAD
        straightOccluded.LockedToPart = false
        straightOccluded.Enabled = false
        straightOccluded.Parent = rainAttachment
        local topdownOccluded = EmitterTopDown:Clone()
        topdownOccluded.Speed = NumberRange.new(RAIN_OCCLUDED_MINSPEED, RAIN_OCCLUDED_MAXSPEED)
        topdownOccluded.Lifetime = RAIN_OCCLUDED_LIFETIME
        topdownOccluded.SpreadAngle = RAIN_OCCLUDED_SPREAD
        topdownOccluded.LockedToPart = false
        topdownOccluded.Enabled = false
        topdownOccluded.Parent = rainAttachment
        rainAttachment.Archivable = false
        table.insert(rainAttachments, rainAttachment)
        table.insert(occludedStraightEmitters, straightOccluded)
        table.insert(occludedTopDownEmitters, topdownOccluded)
    end
end

-- Helper methods:

local RAYCAST_DEEP_STEP = 0.001 -- Distance to advance past a rejected hit when concatenating deep-casts

local rng = Random.new()

local ignoreEmitterList = { Emitter }

local raycastParams = RaycastParams.new()
raycastParams.ExcludeInstances = ignoreEmitterList

local collisionListParams = RaycastParams.new()

local function raycastWithCollisionList(origin, direction)
    return workspace:Raycast(origin, direction, collisionListParams)
end

local function getLocalCharacter()
    local localPlayer = Players.LocalPlayer
    if not localPlayer then
        return nil
    end

    return localPlayer.Character
end

local raycastFunctions = {
    [CollisionMode.None] = function(origin, direction, ignoreCharacter)
        raycastParams.ExcludeInstances = if ignoreCharacter then { Emitter, getLocalCharacter() } else ignoreEmitterList
        return workspace:Raycast(origin, direction, raycastParams)
    end,
    [CollisionMode.Params] = function(origin, direction)
        return workspace:Raycast(origin, direction, collisionParams)
    end,
    [CollisionMode.Blacklist] = raycastWithCollisionList,
    [CollisionMode.Whitelist] = raycastWithCollisionList,
    [CollisionMode.Function] = function(origin, direction)
        raycastParams.ExcludeInstances = ignoreEmitterList

        local destination = origin + direction
        -- draw multiple raycasts concatenated to each other until no hit / valid hit found
        while direction.Magnitude > RAYCAST_DEEP_STEP do
            local result = workspace:Raycast(origin, direction, raycastParams)
            if not result or collisionFunc(result.Instance) then
                return result
            end
            origin = result.Position + direction.Unit * RAYCAST_DEEP_STEP
            direction = destination - origin
        end
        return nil
    end,
}
local raycast = raycastFunctions[collisionMode]

local function connectLoop()
    local inside = true -- Whether camera is currently in a spot occluded from the sky
    local frame = RAIN_UPDATE_PERIOD -- Frame counter, and force update cycle right now

    -- Update Emitter on RenderStepped since it needs to be synced to Camera
    table.insert(
        connections,
        RunService.RenderStepped:Connect(function()
            local cameraCFrame = workspace.CurrentCamera.CFrame
            local cameraPosition = cameraCFrame.Position

            -- Check if camera is outside or inside
            local occlusion = raycast(cameraPosition, -rainDirection * RAIN_SCANHEIGHT, true)

            if (not currentCeiling or cameraPosition.y <= currentCeiling) and not occlusion then
                -- Camera is outside and under ceiling

                if volumeTarget < 1 and not disabled then
                    volumeTarget = 1
                    TweenService:Create(Sound, TweenInfo.new(0.5), { Volume = 1 }):Play()
                end

                frame = RAIN_UPDATE_PERIOD

                local lookVector = cameraCFrame.LookVector
                local t = math.abs(lookVector:Dot(rainDirection))

                local center = cameraPosition
                local right = lookVector:Cross(-rainDirection)
                right = if right.magnitude > 0.001 then right.Unit else -rainDirection
                local forward = rainDirection:Cross(right).Unit

                local depth = RAIN_EMITTER_DIM_DEFAULT + (1 - t) * (RAIN_EMITTER_DIM_MAXFORWARD - RAIN_EMITTER_DIM_DEFAULT)
                Emitter.Size = v3(RAIN_EMITTER_DIM_DEFAULT, RAIN_EMITTER_DIM_DEFAULT, depth)

                Emitter.CFrame = CFrame.new(
                    center.x,
                    center.y,
                    center.z,
                    right.x,
                    -rainDirection.x,
                    forward.x,
                    right.y,
                    -rainDirection.y,
                    forward.y,
                    right.z,
                    -rainDirection.z,
                    forward.z
                ) + (1 - t) * lookVector * depth / 3 - t * rainDirection * RAIN_EMITTER_UP_MODIFIER

                EmitterStraight.Enabled = true
                EmitterTopDown.Enabled = true

                inside = false
            else
                -- Camera is inside / above ceiling

                EmitterStraight.Enabled = false
                EmitterTopDown.Enabled = false

                inside = true
            end
        end)
    )

    -- Do the other effects on Stepped
    local signal = if RunService:IsRunning() then RunService.Stepped else RunService.RenderStepped
    table.insert(
        connections,
        signal:Connect(function()
            local cameraCFrame = workspace.CurrentCamera.CFrame

            frame = frame + 1

            -- Only do some updates once every few frames
            if frame >= RAIN_UPDATE_PERIOD then
                -- Measure of how much camera is facing down (0-1)
                local t = math.abs(cameraCFrame.LookVector:Dot(rainDirection))

                -- More looking down = see straight particles less and see top-down particles more
                local straightSequence = NumberSequence.new({
                    NSK010,
                    NumberSequenceKeypoint.new(RAIN_TRANSPARENCY_T1, (1 - t) * straightLowAlpha + t, 0),
                    NumberSequenceKeypoint.new(RAIN_TRANSPARENCY_T2, (1 - t) * straightLowAlpha + t, 0),
                    NSK110,
                })
                local topdownSequence = NumberSequence.new({
                    NSK010,
                    NumberSequenceKeypoint.new(RAIN_TRANSPARENCY_T1, t * topdownLowAlpha + (1 - t), 0),
                    NumberSequenceKeypoint.new(RAIN_TRANSPARENCY_T2, t * topdownLowAlpha + (1 - t), 0),
                    NSK110,
                })

                -- Find desired rotation for the straight rain particles
                local mapped = cameraCFrame:VectorToObjectSpace(-rainDirection)
                local straightRotation = NumberRange.new(math.deg(math.atan2(-mapped.x, mapped.y)))

                if inside then
                    -- Update emitter properties
                    for i = 1, RAIN_SPLASH_NUM do
                        local straightEmitter = occludedStraightEmitters[i]
                        straightEmitter.Transparency = straightSequence
                        straightEmitter.Rotation = straightRotation
                        occludedTopDownEmitters[i].Transparency = topdownSequence
                    end

                    if not disabled then
                        -- Only do occluded volume check if not moving towards disabled state

                        local volume = 0

                        if not currentCeiling or cameraCFrame.Position.y <= currentCeiling then
                            -- Check how far away camera is from a space open to the sky using volume scan grid

                            local minDistance = RAIN_VOLUME_SCAN_RADIUS
                            local rayDirection = -rainDirection * RAIN_SCANHEIGHT

                            for i = 1, #volumeScanGrid do -- In order, so first hit is closest
                                if not raycast(cameraCFrame * volumeScanGrid[i], rayDirection, true) then
                                    minDistance = volumeScanGrid[i].magnitude
                                    break
                                end
                            end

                            -- Volume is inversely proportionate to minimum distance
                            volume = 1 - minDistance / RAIN_VOLUME_SCAN_RADIUS
                        end

                        if math.abs(volume - volumeTarget) > 0.01 then
                            -- Value is sufficiently different from previous target, overwrite it
                            volumeTarget = volume
                            TweenService:Create(Sound, TweenInfo.new(1), { Volume = volumeTarget }):Play()
                        end
                    end
                else
                    -- Update emitter properties
                    EmitterStraight.Transparency = straightSequence
                    EmitterStraight.Rotation = straightRotation
                    EmitterTopDown.Transparency = topdownSequence
                end

                -- Reset frame counter
                frame = 0
            end

            local center = cameraCFrame.Position
            local right = cameraCFrame.LookVector:Cross(-rainDirection)
            right = if right.magnitude > 0.001 then right.Unit else -rainDirection
            local forward = rainDirection:Cross(right).Unit
            local transform = CFrame.new(
                center.x,
                center.y,
                center.z,
                right.x,
                -rainDirection.x,
                forward.x,
                right.y,
                -rainDirection.y,
                forward.y,
                right.z,
                -rainDirection.z,
                forward.z
            )
            local transformRotation = transform - center
            local rayDirection = rainDirection * RAIN_OCCLUDECHECK_SCAN_Y

            -- Splash and occlusion effects
            for i = 1, numSplashes do
                local splashAttachment = splashAttachments[i]
                local rainAttachment = rainAttachments[i]
                local occludedStraight = occludedStraightEmitters[i]
                local occludedTopDown = occludedTopDownEmitters[i]

                -- Sample random splash position
                local x = rng:NextNumber(RAIN_OCCLUDECHECK_OFFSET_XZ_MIN, RAIN_OCCLUDECHECK_OFFSET_XZ_MAX)
                local z = rng:NextNumber(RAIN_OCCLUDECHECK_OFFSET_XZ_MIN, RAIN_OCCLUDECHECK_OFFSET_XZ_MAX)
                local impact = raycast(transform * v3(x, RAIN_OCCLUDECHECK_OFFSET_Y, z), rayDirection)

                if impact then
                    -- Draw a splash at hit
                    splashAttachment.Position = impact.Position + impact.Normal * RAIN_SPLASH_CORRECTION_Y
                    splashEmitters[i]:Emit(1)

                    if inside then
                        -- Draw occlusion rain particles a little bit above the splash position
                        local corrected = impact.Position - rainDirection * RAIN_SPLASH_STRAIGHT_OFFSET_Y
                        if currentCeiling and corrected.Y > currentCeiling and rainDirection.Y < 0 then
                            corrected = corrected + rainDirection * (currentCeiling - corrected.Y) / rainDirection.Y
                        end
                        rainAttachment.CFrame = transformRotation + corrected
                        occludedStraight:Emit(intensityOccludedRain)
                        occludedTopDown:Emit(intensityOccludedRain)
                    end
                elseif inside then
                    -- Draw occlusion rain particles on the XZ-position at around the camera's height
                    local corrected = transform * v3(x, rng:NextNumber(RAIN_NOSPLASH_STRAIGHT_OFFSET_Y_MIN, RAIN_NOSPLASH_STRAIGHT_OFFSET_Y_MAX), z)
                    if currentCeiling and corrected.Y > currentCeiling and rainDirection.Y < 0 then
                        corrected = corrected + rainDirection * (currentCeiling - corrected.Y) / rainDirection.Y
                    end
                    rainAttachment.CFrame = transformRotation + corrected
                    occludedStraight:Emit(intensityOccludedRain)
                    occludedTopDown:Emit(intensityOccludedRain)
                end
            end
        end)
    )
end

local function disconnectLoop()
    -- If present, disconnect all RunService connections
    if #connections > 0 then
        for _, v in connections do
            v:Disconnect()
        end
        connections = {}
    end
end

local function disableSound(tweenInfo)
    -- Tween the rain sound to be mute over a given easing function
    volumeTarget = 0
    local tween = TweenService:Create(Sound, tweenInfo, { Volume = 0 })
    tween.Completed:Connect(function(state)
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
    EmitterStraight.Enabled = false
    EmitterTopDown.Enabled = false
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
    valueObject.Changed:Connect(setter)
    setter(valueObject.Value)
    return valueObject
end

local Color = makeProperty("Color3Value", RAIN_DEFAULT_COLOR, function(value)
    local ColorSequence = ColorSequence.new(value)

    EmitterStraight.Color = ColorSequence
    EmitterTopDown.Color = ColorSequence

    for _, v in splashEmitters do
        v.Color = ColorSequence
    end
    for i = 1, RAIN_SPLASH_NUM do
        occludedStraightEmitters[i].Color = ColorSequence
        occludedTopDownEmitters[i].Color = ColorSequence
    end
end) :: Color3Value

local function updateTransparency(value)
    local opacity = (1 - value) * (1 - GlobalModifier.Value)
    local transparency = 1 - opacity

    straightLowAlpha = RAIN_STRAIGHT_ALPHA_LOW * opacity + transparency
    topdownLowAlpha = RAIN_TOPDOWN_ALPHA_LOW * opacity + transparency

    local splashSequence = NumberSequence.new({
        NSK010,
        NumberSequenceKeypoint.new(RAIN_TRANSPARENCY_T1, opacity * RAIN_SPLASH_ALPHA_LOW + transparency, 0),
        NumberSequenceKeypoint.new(RAIN_TRANSPARENCY_T2, opacity * RAIN_SPLASH_ALPHA_LOW + transparency, 0),
        NSK110,
    })

    for _, v in splashEmitters do
        v.Transparency = splashSequence
    end
end

local Transparency = makeProperty("NumberValue", RAIN_DEFAULT_TRANSPARENCY, updateTransparency) :: NumberValue
GlobalModifier.Changed:Connect(updateTransparency)

local SpeedRatio = makeProperty("NumberValue", RAIN_DEFAULT_SPEEDRATIO, function(value)
    EmitterStraight.Speed = NumberRange.new(value * RAIN_STRAIGHT_MAX_SPEED)
    EmitterTopDown.Speed = NumberRange.new(value * RAIN_TOPDOWN_MAX_SPEED)
end) :: NumberValue

local IntensityRatio = makeProperty("NumberValue", RAIN_DEFAULT_INTENSITYRATIO, function(value)
    EmitterStraight.Rate = RAIN_STRAIGHT_MAX_RATE * value
    EmitterTopDown.Rate = RAIN_TOPDOWN_MAX_RATE * value

    intensityOccludedRain = math.ceil(RAIN_OCCLUDED_MAXINTENSITY * value)
    numSplashes = RAIN_SPLASH_NUM * value
end) :: NumberValue

local LightEmission = makeProperty("NumberValue", RAIN_DEFAULT_LIGHTEMISSION, function(value)
    EmitterStraight.LightEmission = value
    EmitterTopDown.LightEmission = value

    for i = 1, RAIN_SPLASH_NUM do
        occludedStraightEmitters[i].LightEmission = value
        occludedTopDownEmitters[i].LightEmission = value
    end
    for _, v in splashEmitters do
        v.LightEmission = value
    end
end) :: NumberValue

local LightInfluence = makeProperty("NumberValue", RAIN_DEFAULT_LIGHTINFLUENCE, function(value)
    EmitterStraight.LightInfluence = value
    EmitterTopDown.LightInfluence = value

    for i = 1, RAIN_SPLASH_NUM do
        occludedStraightEmitters[i].LightInfluence = value
        occludedTopDownEmitters[i].LightInfluence = value
    end
    for _, v in splashEmitters do
        v.LightInfluence = value
    end
end) :: NumberValue

local RainDirection = makeProperty("Vector3Value", RAIN_DEFAULT_DIRECTION, function(value)
    if value.magnitude > 0.001 then
        rainDirection = value.Unit
    end
end) :: Vector3Value

-- Exposed API:

local Rain = {}

Rain.CollisionMode = CollisionMode

function Rain:Enable(tweenInfo: TweenInfo?)
    if tweenInfo ~= nil and typeof(tweenInfo) ~= "TweenInfo" then
        error("bad argument #1 to 'Enable' (TweenInfo expected, got " .. typeof(tweenInfo) .. ")", 2)
    end

    disconnectLoop() -- Just in case :Enable(..) is called multiple times on accident

    EmitterStraight.Enabled = true
    EmitterTopDown.Enabled = true
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
        TweenService:Create(GlobalModifier, tweenInfo, { Value = 0 }):Play()
    else
        GlobalModifier.Value = 0
    end

    if not Sound.Playing then
        Sound:Play()
        Sound.TimePosition = rng:NextNumber() * Sound.TimeLength
    end

    disabled = false
end

function Rain:Disable(tweenInfo: TweenInfo?)
    if tweenInfo ~= nil and typeof(tweenInfo) ~= "TweenInfo" then
        error("bad argument #1 to 'Disable' (TweenInfo expected, got " .. typeof(tweenInfo) .. ")", 2)
    end

    if tweenInfo then
        local tween = TweenService:Create(GlobalModifier, tweenInfo, { Value = 1 })
        tween.Completed:Connect(function(state)
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

function Rain:SetColor(value: Color3, tweenInfo: TweenInfo?)
    if typeof(value) ~= "Color3" then
        error("bad argument #1 to 'SetColor' (Color3 expected, got " .. typeof(value) .. ")", 2)
    elseif tweenInfo ~= nil and typeof(tweenInfo) ~= "TweenInfo" then
        error("bad argument #2 to 'SetColor' (TweenInfo expected, got " .. typeof(tweenInfo) .. ")", 2)
    end

    if tweenInfo then
        TweenService:Create(Color, tweenInfo, { Value = value }):Play()
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
            TweenService:Create(valueObject, tweenInfo, { Value = value }):Play()
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

function Rain:SetVolume(volume: number, tweenInfo: TweenInfo?)
    if typeof(volume) ~= "number" then
        error("bad argument #1 to 'SetVolume' (number expected, got " .. typeof(volume) .. ")", 2)
    elseif tweenInfo ~= nil and typeof(tweenInfo) ~= "TweenInfo" then
        error("bad argument #2 to 'SetVolume' (TweenInfo expected, got " .. typeof(tweenInfo) .. ")", 2)
    end

    if tweenInfo then
        TweenService:Create(SoundGroup, tweenInfo, { Volume = volume }):Play()
    else
        SoundGroup.Volume = volume
    end
end

function Rain:SetDirection(direction: Vector3, tweenInfo: TweenInfo?)
    if typeof(direction) ~= "Vector3" then
        error("bad argument #1 to 'SetDirection' (Vector3 expected, got " .. typeof(direction) .. ")", 2)
    elseif tweenInfo ~= nil and typeof(tweenInfo) ~= "TweenInfo" then
        error("bad argument #2 to 'SetDirection' (TweenInfo expected, got " .. typeof(tweenInfo) .. ")", 2)
    end

    if not (direction.Unit.magnitude > 0) then -- intentional statement formatting since NaN comparison
        warn("Attempt to set rain direction to a zero-length vector, falling back on default direction = (" .. tostring(RAIN_DEFAULT_DIRECTION) .. ")")
        direction = RAIN_DEFAULT_DIRECTION
    end

    if tweenInfo then
        TweenService:Create(RainDirection, tweenInfo, { Value = direction }):Play()
    else
        RainDirection.Value = direction
    end
end

function Rain:SetCeiling(ceiling: number?)
    if ceiling ~= nil and typeof(ceiling) ~= "number" then
        error("bad argument #1 to 'SetCeiling' (number expected, got " .. typeof(ceiling) .. ")", 2)
    end

    currentCeiling = ceiling
end

function Rain:SetStraightTexture(asset: string)
    if typeof(asset) ~= "string" then
        error("bad argument #1 to 'SetStraightTexture' (string expected, got " .. typeof(asset) .. ")", 2)
    end

    EmitterStraight.Texture = asset

    for _, v in occludedStraightEmitters do
        v.Texture = asset
    end
end

function Rain:SetTopDownTexture(asset: string)
    if typeof(asset) ~= "string" then
        error("bad argument #1 to 'SetStraightTexture' (string expected, got " .. typeof(asset) .. ")", 2)
    end

    EmitterTopDown.Texture = asset

    for _, v in occludedTopDownEmitters do
        v.Texture = asset
    end
end

function Rain:SetSplashTexture(asset: string)
    if typeof(asset) ~= "string" then
        error("bad argument #1 to 'SetStraightTexture' (string expected, got " .. typeof(asset) .. ")", 2)
    end

    for _, v in splashEmitters do
        v.Texture = asset
    end
end

function Rain:SetSoundId(asset: string)
    if typeof(asset) ~= "string" then
        error("bad argument #1 to 'SetSoundId' (string expected, got " .. typeof(asset) .. ")", 2)
    end

    Sound.SoundId = asset
end

function Rain:SetCollisionMode(mode: CollisionMode, param: (RaycastParams | Instance | { Instance } | ((Instance) -> boolean))?)
    if mode == CollisionMode.None then
        -- Regular mode needs no params or test function
        collisionFunc = nil
        collisionParams = nil
    elseif mode == CollisionMode.Params then
        if typeof(param) ~= "RaycastParams" then
            error("bad argument #2 to 'SetCollisionMode' (RaycastParams expected, got " .. typeof(param) .. ")", 2)
        end

        local excluded = param.ExcludeInstances
        if excluded and not table.find(excluded, Emitter) then
            -- Add Emitter anyway, since users will probably not expect collisions with emitter block regardless
            table.insert(excluded, Emitter)
            param.ExcludeInstances = excluded
        end

        -- Params mode does not need a test function
        collisionFunc = nil

        collisionParams = param
    elseif mode == CollisionMode.Blacklist then
        warn("Rain.CollisionMode.Blacklist is deprecated. Use Rain.CollisionMode.Params instead.")

        local blacklist = { Emitter }
        if typeof(param) == "Instance" then
            -- Add Emitter anyway, since users will probably not expect collisions with emitter block regardless
            blacklist = { param, Emitter }
        elseif typeof(param) == "table" then
            for i = 1, #param do
                if typeof(param[i]) ~= "Instance" then
                    error(
                        "bad argument #2 to 'SetCollisionMode' (blacklist contained a "
                            .. typeof(param[i])
                            .. " on index "
                            .. tostring(i)
                            .. " which is not an Instance)",
                        2
                    )
                end
            end

            for i = 1, #param do
                table.insert(blacklist, param[i])
            end
        else
            error("bad argument #2 to 'SetCollisionMode (Instance or array of Instance expected, got " .. typeof(param) .. ")'", 2)
        end

        collisionListParams.IncludeInstances = {}
        collisionListParams.ExcludeInstances = blacklist

        -- Blacklist does not need a test function
        collisionFunc = nil
    elseif mode == CollisionMode.Whitelist then
        warn("Rain.CollisionMode.Whitelist is deprecated. Use Rain.CollisionMode.Params instead.")

        local whitelist
        if typeof(param) == "Instance" then
            whitelist = { param }
        elseif typeof(param) == "table" then
            for i = 1, #param do
                if typeof(param[i]) ~= "Instance" then
                    error(
                        "bad argument #2 to 'SetCollisionMode' (whitelist contained a "
                            .. typeof(param[i])
                            .. " on index "
                            .. tostring(i)
                            .. " which is not an Instance)",
                        2
                    )
                end
            end
            whitelist = {}
            for i = 1, #param do
                table.insert(whitelist, param[i])
            end
        else
            error("bad argument #2 to 'SetCollisionMode (Instance or array of Instance expected, got " .. typeof(param) .. ")'", 2)
        end

        collisionListParams.ExcludeInstances = {}
        collisionListParams.IncludeInstances = whitelist

        -- Whitelist does not need a test function
        collisionFunc = nil
    elseif mode == CollisionMode.Function then
        if typeof(param) ~= "function" then
            error("bad argument #2 to 'SetCollisionMode' (function expected, got " .. typeof(param) .. ")", 2)
        end

        -- Test function does not need params
        collisionParams = nil

        collisionFunc = param
    else
        error("bad argument #1 to 'SetCollisionMode (Rain.CollisionMode expected, got " .. typeof(mode) .. ")'", 2)
    end

    collisionMode = mode
    raycast = raycastFunctions[mode]
end

return Rain
