-- Generated from template

function Precache( context )
	--[[
		Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "soundfile", "*.vsndevts", context )
			PrecacheResource( "particle", "*.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )
	]]
end
require('gamemode')
-- Create the game mode when we activate
function Activate()
	GameRules.AddonTemplate = GameMode()
	GameRules.AddonTemplate:InitGameMode()
end

