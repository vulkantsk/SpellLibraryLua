LinkLuaModifier("modifier_ability_storm_spirit_thinker", "heroes/storm_spirit/static_remnant.lua", 0)

ability_storm_spirit_static_remnant = class({})

function ability_storm_spirit_static_remnant:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("static_remnant_duration")

	CreateModifierThinker(caster, self, "modifier_ability_storm_spirit_thinker", {duration = duration}, caster:GetAbsOrigin(), caster:GetTeam(), false)

	caster:EmitSound("Hero_StormSpirit.StaticRemnantPlant")
end

modifier_ability_storm_spirit_thinker = class({})

function modifier_ability_storm_spirit_thinker:OnCreated()
	self.radius = self:GetAbility():GetSpecialValueFor("static_remnant_radius")
	self.damage_radius = self:GetAbility():GetSpecialValueFor("static_remnant_damage_radius")
	self.delay = self:GetAbility():GetSpecialValueFor("static_remnant_delay")
	self.damage = self:GetAbility():GetSpecialValueFor("static_remnant_damage")

	if IsServer() then
		local caster = self:GetCaster()
		local particle = "particles/units/heroes/hero_stormspirit/stormspirit_static_remnant.vpcf"
		self.fx = ParticleManager:CreateParticle(particle, PATTACH_WORLDORIGIN, caster)
		ParticleManager:SetParticleControl(self.fx, 0, caster:GetAbsOrigin())
		ParticleManager:SetParticleControlEnt(self.fx, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
		ParticleManager:SetParticleControl(self.fx, 2, Vector(RandomInt(37, 52), 1, 100))
		ParticleManager:SetParticleControl(self.fx, 11, caster:GetAbsOrigin())

		self:StartIntervalThink(FrameTime())
	end
end

function modifier_ability_storm_spirit_thinker:OnIntervalThink()
	if self:GetElapsedTime() >= self.delay then
		local enemies = FindUnitsInRadius(
			self:GetCaster():GetTeamNumber(),
			self:GetParent():GetAbsOrigin(),
			nil,
			self.radius,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
			0,
			false
		)

		if #enemies > 0 then
			self:Destroy()
		end
	end
end

function modifier_ability_storm_spirit_thinker:OnDestroy()
	if IsServer() then
		local parent = self:GetParent()

		local enemies = FindUnitsInRadius(
			self:GetCaster():GetTeamNumber(),
			parent:GetAbsOrigin(),
			nil,
			self.damage_radius,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			0,
			0,
			false
		)

		for _, enemy in pairs(enemies) do
			ApplyDamage({
				victim = enemy,
				attacker = self:GetCaster(),
				ability = self:GetAbility(),
				damage = self.damage,
				damage_type = self:GetAbility():GetAbilityDamageType()
			})
		end

		parent:EmitSound("Hero_StormSpirit.StaticRemnantExplode")

		ParticleManager:DestroyParticle(self.fx, false)
		ParticleManager:ReleaseParticleIndex(self.fx)
		UTIL_Remove(self:GetParent())
	end
end