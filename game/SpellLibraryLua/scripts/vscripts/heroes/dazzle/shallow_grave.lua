ability_shallow_grave = class({})
-- Creator: https://github.com/Elfansoer/dota-2-lua-abilities/tree/master/scripts/vscripts/lua_abilities/dazzle_shallow_grave_lua
LinkLuaModifier( "modifier_ability_shallow_grave_buff", "heroes/dazzle/shallow_grave", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Ability Start
function ability_shallow_grave:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	-- load data
	local duration = self:GetSpecialValueFor("duration")

	-- Add modifier
	target:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_ability_shallow_grave_buff", -- modifier name
		{ duration = duration } -- kv
	)
end

modifier_ability_shallow_grave_buff = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_ability_shallow_grave_buff:IsHidden()
	return false
end

function modifier_ability_shallow_grave_buff:IsDebuff()
	return false
end

function modifier_ability_shallow_grave_buff:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_ability_shallow_grave_buff:OnCreated( kv )
	if IsServer() then
		-- Play effects
		local sound_cast = "Hero_Dazzle.Shallow_Grave"
		EmitSoundOn( sound_cast, self:GetParent() )
	end
end
--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_ability_shallow_grave_buff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MIN_HEALTH,
	}

	return funcs
end
function modifier_ability_shallow_grave_buff:GetMinHealth()
	return 1
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_ability_shallow_grave_buff:GetEffectName()
	return "particles/units/heroes/hero_dazzle/dazzle_shallow_grave.vpcf"
end

function modifier_ability_shallow_grave_buff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end