LinkLuaModifier("modifier_ability_slardar_slithereen_crush_slow", "heroes/slardar/slithereen_crush.lua", 0)

ability_slardar_slithereen_crush = class({})

function ability_slardar_slithereen_crush:OnSpellStart()
	local caster = self:GetCaster()

	local radius = self:GetSpecialValueFor("crush_radius")
	local damage = self:GetAbilityDamage()
	local stun_duration = self:GetSpecialValueFor("stun_duration")
	local slow_duration = self:GetSpecialValueFor("crush_extra_slow_duration")

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		caster:GetOrigin(),
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)

	for _, enemy in pairs(enemies) do
		ApplyDamage({
			victim = enemy,
			attacker = caster,
			ability = self,
			damage = damage,
			damage_type = self:GetAbilityDamageType()
		})

		enemy:AddNewModifier(caster, self, "modifier_stunned", {duration = stun_duration})
		enemy:AddNewModifier(caster, self, "modifier_ability_slardar_slithereen_crush_slow", {duration = stun_duration + slow_duration})
	end

	local particle = "particles/units/heroes/hero_slardar/slardar_crush.vpcf"
	local fx = ParticleManager:CreateParticle(particle, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(fx, 0, caster:GetOrigin())
	ParticleManager:SetParticleControl(fx, 1, Vector(radius, radius, radius))
	ParticleManager:ReleaseParticleIndex(fx)

	EmitSoundOnLocationWithCaster(caster:GetOrigin(), "Hero_Slardar.Slithereen_Crush", caster)
end

modifier_ability_slardar_slithereen_crush_slow = class({
	IsPurgable = function() return true end,
	IsDebuff = function() return true end,
	IsStunDebuff = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
	} end
})

function modifier_ability_slardar_slithereen_crush_slow:OnCreated()
	self.movespeed_slow = self:GetAbility():GetSpecialValueFor("crush_extra_slow")
	self.as_slow = self:GetAbility():GetSpecialValueFor("crush_attack_slow_tooltip")
end

function modifier_ability_slardar_slithereen_crush_slow:OnRefresh()
	self:OnCreated()
end

function modifier_ability_slardar_slithereen_crush_slow:GetModifierMoveSpeedBonus_Percentage()
	return self.movespeed_slow
end
function modifier_ability_slardar_slithereen_crush_slow:GetModifierAttackSpeedBonus_Constant()
	return self.as_slow
end
