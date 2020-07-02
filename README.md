## **SpellLibraryLua** 

This repository is a collection of remade Dota 2 Hero abilities for the use of the Dota2 modding community by the Dota2 modding community

If you have any questions regarding the project or if you have found a bug/issue with the spells then feel free to [create an issue](https://github.com/vulkantsk/SpellLibraryLua/issues/new).

[Progress so far](https://docs.google.com/spreadsheets/d/1By8Ccpom5_8i80zciTsneFfCjUOXsWzBDa0Clo9QKWQ/edit#gid=0)

## **Contribution & Guidelines** 

If you wish to contribute to this project then it is preferred if you could follow the following guidelines when contributing:

* **Abilities that are not written in LUA are not accepted**

* Lua scripts should be separated on a per hero basis

* Use as many AbilitySpecials as possible, do not hardcode the lua file.

* Don't use Global Lua Events, abilities should work without any main addon scripts.

* Don't bother with completely dota-hardcoded interactions

* Implementing Aghanims upgrades and casting animations is not neccessary

* Implementing Refresher compatibility is recommended but not mandatory

* Use default particles and sounds

* If you find an ability that seems hard or impossible to rewrite, ask and document your attempts, others will help you

* It is fine to use BMD's Timers and Physics libraries

* Lua abilities should be saved as **abilityname.txt** inside scripts/npc/heroes/HERONAME/ folder

* Lua scripts should be saved as **abilityname.lua** inside scripts/vscripts/heroes/HERONAME/ folder

* If the hero of the written ability is not in the file **activelist** and **npc_heroes_custom**, then be sure to enter it there, following the example of what is already there.

* If your ability uses a new dummy unit, then enter it in the **npc_units_custom** file

* Make sure to enter the path to each ability in both the **KV** file and the **npc_abilities_custom** file

## **Follow this coding style**:

* **For KV abilities names**:
  * Start names with "ability_"
  * Then add the original spell name (no hero name)

* **For Lua functions**

```
function AbilityName:OnSpellStart()
    -- Variables
    local caster = self:GetCaster()
    local value = self:GetSpecialValueFor( "value" )

    -- Try to comment each block of logical actions
    -- If the ability handle is not nil, print a message
    if self then
        print("RunScript")
    end
end
```

* **For Lua modifiers**
  * Start names with "modifier_"
  * Then add the spell name (no hero name)
  * Add "_buff" "_debuff" "_stun" or anything when appropiate

```
modifier_ABILITYNAME_EXAMPLE = class({
    --Here you can enter all the functions that will not change during the game
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsPurgeException 		= function(self) return true end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    --To list here all the properties and events
    DeclareFunctions        = function(self)
        return {
			MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
			MODIFIER_PROPERTY_MODEL_CHANGE
        }
    end,
    --Here all state
    CheckState				= function(self)
    	return {
    		[MODIFIER_STATE_HEXED] = true,
    		[MODIFIER_STATE_MUTED] = true,
			[MODIFIER_STATE_DISARMED] = true,
			[MODIFIER_STATE_SILENCED] = true,
			[MODIFIER_STATE_BLOCK_DISABLED] = true,
			[MODIFIER_STATE_EVADE_DISABLED] = true,
			[MODIFIER_STATE_PASSIVES_DISABLED] = true
    	}
    end,
    GetModifierModelChange 	= function(self) return "models/props_gameplay/chicken.vmdl" end
    --And so on
})

--OnCreated
function modifier_ABILITYNAME_EXAMPLE:OnCreated()
	self.movespeed = self:GetAbility():GetSpecialValueFor("movespeed")
end

--Take out of the class only what changes during the game, such as increasing the absolute speed, as here
function modifier_ABILITYNAME_EXAMPLE:GetModifierMoveSpeed_Absolute() return self.movespeed end
```

## Recommended resources

* [ModDota](https://moddota.com/) the great Moddota tutorial collection and API libraries
* [Workshop Tools Wiki](https://developer.valvesoftware.com/wiki/Dota_2_Workshop_Tools) the official Dota 2 Workshop Tools wiki
* [CustomGames](https://customgames.ru/forum/) forum with useful information where you can ask what you need
* [Standart Dota files](https://github.com/SteamDatabase/GameTracking-Dota2/tree/master/game/dota/pak01_dir) You can take the names of all the sounds you are interested in from here
