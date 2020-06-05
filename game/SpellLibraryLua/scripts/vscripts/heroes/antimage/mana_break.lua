ability_mana_break = class({})

LinkLuaModifier( "modifier_ability_mana_break_passive", "heroes/antimage/mana_break", LUA_MODIFIER_MOTION_NONE )
function ability_mana_break:GetIntrinsicModifierName()
	return "modifier_ability_mana_break_passive"
end

modifier_ability_mana_break_passive = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_ability_mana_break_passive:IsHidden()
	return true
end

function modifier_ability_mana_break_passive:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_ability_mana_break_passive:OnCreated( kv )
	-- references
    self.mana_break = self:GetAbility():GetSpecialValueFor( "mana_per_hit" ) 
    self.mana_per_hit_pct = self:GetAbility():GetSpecialValueFor( "mana_per_hit_pct" ) * .01
	self.mana_damage_pct = self:GetAbility():GetSpecialValueFor( self:GetParent():IsIllusion() and "illusion_percentage" or "percent_damage_per_burn" ) * .01
end

function modifier_ability_mana_break_passive:OnRefresh( kv )
	self:OnCreated()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_ability_mana_break_passive:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL,
	}

	return funcs
end

function modifier_ability_mana_break_passive:GetModifierProcAttack_BonusDamage_Physical( params )
	if IsServer() and (not self:GetParent():PassivesDisabled()) then
		local target = params.target
		local result = UnitFilter(
			target,	-- Target Filter
			DOTA_UNIT_TARGET_TEAM_ENEMY,	-- Team Filter
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,	-- Unit Filter
			DOTA_UNIT_TARGET_FLAG_MANA_ONLY,	-- Unit Flag
			self:GetParent():GetTeamNumber()	-- Team reference
		)
        
		if result == UF_SUCCESS then
			local mana_burn =  math.min( target:GetMana(), self.mana_break + target:GetMana() * self.mana_per_hit_pct )
			target:ReduceMana( mana_burn )        
            local effect_cast = ParticleManager:CreateParticle( "particles/generic_gameplay/generic_manaburn.vpcf", PATTACH_ABSORIGIN, target )
            ParticleManager:ReleaseParticleIndex( effect_cast )
    
            EmitSoundOn( "Hero_Antimage.ManaBreak", target )
			return mana_burn * self.mana_damage_pct
		end

	end
end