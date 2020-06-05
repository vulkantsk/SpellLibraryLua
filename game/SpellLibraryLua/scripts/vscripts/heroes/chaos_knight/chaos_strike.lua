ability_chaos_strike = class({})
LinkLuaModifier('modifier_ability_chaos_strike_buff', 'heroes/chaos_knight/chaos_strike', LUA_MODIFIER_MOTION_NONE)
function ability_chaos_strike:GetIntrinsicModifierName()
    return 'modifier_ability_chaos_strike_buff'
end 

modifier_ability_chaos_strike_buff = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return true end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    AllowIllusionDuplicate  = function(self) return false end,
})

function modifier_ability_chaos_strike_buff:OnCreated()
	-- references
    self.ability = self:GetAbility()
    self.crit_min = self:GetAbility():GetSpecialValueFor( "crit_min" )
    self.crit_max = self:GetAbility():GetSpecialValueFor( "crit_max" )
	self.lifesteal = self:GetAbility():GetSpecialValueFor( "lifesteal" )
end

function modifier_ability_chaos_strike_buff:OnRefresh()
	self:OnCreated()
end

function modifier_ability_chaos_strike_buff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}

	return funcs
end

function modifier_ability_chaos_strike_buff:GetModifierPreAttack_CriticalStrike( params )
	if IsServer() and (not self:GetParent():PassivesDisabled()) and self.ability:IsCooldownReady() then
        self.record = params.record
        self.ability:StartCooldown(self.ability:GetCooldown(self.ability:GetLevel()))
		return RandomInt(self.crit_min, self.crit_max)
	end
end

function modifier_ability_chaos_strike_buff:OnTakeDamage( params )
	if IsServer() then
		if self.record and params.record == self.record then
			local heal = params.damage * self.lifesteal/100
			self:GetParent():Heal( heal, self:GetAbility() )
            self.record = nil
            local effect_cast = ParticleManager:CreateParticle( "particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
            ParticleManager:ReleaseParticleIndex( effect_cast )
            ParticleManager:ReleaseParticleIndex(effect_cast)
            EmitSoundOn( "Hero_ChaosKnight.ChaosStrike", self:GetParent() )

		end
	end
end
