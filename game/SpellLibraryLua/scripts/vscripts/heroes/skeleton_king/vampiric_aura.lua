ability_vampiric_aura = {}

LinkLuaModifier( "modifier_ability_vampiric_aura", "heroes/skeleton_king/vampiric_aura", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_vampiric_aura_lifesteal", "heroes/skeleton_king/vampiric_aura", LUA_MODIFIER_MOTION_NONE )

function ability_vampiric_aura:GetIntrinsicModifierName()
	return "modifier_ability_vampiric_aura"
end

modifier_ability_vampiric_aura = {}

function modifier_ability_vampiric_aura:IsHidden()
	return true
end

function modifier_ability_vampiric_aura:IsAura()
	return true
end

function modifier_ability_vampiric_aura:GetModifierAura()
	return "modifier_ability_vampiric_aura_lifesteal"
end

function modifier_ability_vampiric_aura:GetAuraRadius()
	return self:GetAbility():GetSpecialValueFor( "vampiric_aura_radius" )
end

function modifier_ability_vampiric_aura:GetAuraSearchTeam()
	if not self:GetParent():PassivesDisabled() then
		return DOTA_UNIT_TARGET_TEAM_FRIENDLY
	end
end

function modifier_ability_vampiric_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO
end

function modifier_ability_vampiric_aura:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

modifier_ability_vampiric_aura_lifesteal = {}

function modifier_ability_vampiric_aura_lifesteal:IsHidden()
	return false
end

function modifier_ability_vampiric_aura_lifesteal:IsDebuff()
	return false
end

function modifier_ability_vampiric_aura_lifesteal:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE
	}
end

function modifier_ability_vampiric_aura_lifesteal:OnTakeDamage( params )
	if IsServer() then
		if params.attacker == self:GetParent() then
			local heal = params.damage * self:GetAbility():GetSpecialValueFor( "vampiric_aura" ) / 100

			if self:GetParent():IsRangedAttacker() then
				heal = heal * ( self:GetAbility():GetSpecialValueFor( "vampiric_aura_ranged_pct" ) / 100 ) 
			end

			self:GetParent():Heal( heal, self:GetAbility() )

			local effect_cast = ParticleManager:CreateParticle(
				"particles/units/heroes/hero_skeletonking/wraith_king_vampiric_aura_lifesteal.vpcf",
				PATTACH_ABSORIGIN_FOLLOW,
				self:GetParent()
			)
			ParticleManager:SetParticleControl( effect_cast, 1, self:GetParent():GetOrigin() )
			ParticleManager:ReleaseParticleIndex( effect_cast )

			local effect_lifesteal = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
			ParticleManager:SetParticleControl(effect_lifesteal, 0, self:GetParent():GetAbsOrigin())
			ParticleManager:ReleaseParticleIndex(effect_lifesteal)
		end
	end
end