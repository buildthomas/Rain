# Rain Module

This module simulates rain for use in Roblox games.

Features:
- Full customization of nearly all properties of the effect, such as color, direction, intensity, transparency, assets that are used, lighting properties.
- Collision functions that are fully customizable (incl. normal, blacklist, whitelist, custom) that also allow you to i.e. easily let rain pass through transparent or non-CanCollide parts easily.
- Provided by default with game-ready, royalty-free, open-source sound effects also used in Egg Hunt 2018.
- Performant for low-end devices.

Refer to this thread for more description:
https://devforum.roblox.com/t/open-source-rain-effect-plugin-release/157190

There is also a user-friendly Roblox plugin available to insert the rain effect into your games, which is useful to preview the rain effect in Studio, as well as allows non-scripters to insert rain into their games all by themselves:
https://www.roblox.com/library/2166774609/Rain-Plugin

# Examples

https://gfycat.com/HeavenlyCelebratedBee.gif

https://gfycat.com/LittleClassicGoldenretriever

# API available on the Rain Module

The following listing contains all API members that can be used with a description.

```text

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
```
