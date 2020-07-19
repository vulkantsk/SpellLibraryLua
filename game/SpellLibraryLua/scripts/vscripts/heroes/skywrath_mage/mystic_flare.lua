LinkLuaModifier("modifier_skywrath_mage_mystic_flare_thinker", "heroes/skywrath_mage/mystic_flare.lua", 0)

ability_skywrath_mage_mystic_flare = class({})

function ability_skywrath_mage_mystic_flare:GetAOERadius() return self:GetSpecialValueFor("radius") end

function ability_skywrath_mage_mystic_flare:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	local duration = self:GetSpecialValueFor("duration")
	local radius = self:GetSpecialValueFor("radius")

	CreateModifierThinker(caster, self, "modifier_skywrath_mage_mystic_flare_thinker", {duration = duration}, point, caster:GetTeam(), false)

	caster:EmitSound("Hero_SkywrathMage.MysticFlare.Cast")
end

modifier_skywrath_mage_mystic_flare_thinker = class({})

function modifier_skywrath_mage_mystic_flare_thinker:OnCreated()
	local parent = self:GetParent()
	local interval = self:GetAbility():GetSpecialValueFor("damage_interval")
	local duration = self:GetAbility():GetSpecialValueFor("duration")
	self.damage = self:GetAbility():GetSpecialValueFor("damage")
	self.radius = self:GetAbility():GetSpecialValueFor("radius")

	if IsServer() then
		self.damage = self.damage * interval / duration

		self:StartIntervalThink(interval)
		self:OnIntervalThink()

		local particle = "particles/units/heroes/hero_skywrath_mage/skywrath_mage_mystic_flare_ambient.vpcf"

		local fx = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN, self:GetParent())
		ParticleManager:SetParticleControl(fx, 1, Vector(self.radius, duration, interval))
		ParticleManager:ReleaseParticleIndex(fx)

		parent:EmitSound("Hero_SkywrathMage.MysticFlare")
	end
end

function modifier_skywrath_mage_mystic_flare_thinker:OnDestroy()
	if IsServer() then
		self:Destroy()
	end
end

function modifier_skywrath_mage_mystic_flare_thinker:OnIntervalThink()
	local heroes = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),
		self:GetParent():GetOrigin(),
		nil,
		self.radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO,
		0,
		0,
		false
	)

	for _, enemy in pairs(heroes) do
		local damage = self.damage / #heroes

		ApplyDamage({
			victim = enemy,
			attacker = self:GetCaster(),
			ability = self:GetAbility(),
			damage = damage,
			damage_type = self:GetAbility():GetAbilityDamageType()
		})
	end
end