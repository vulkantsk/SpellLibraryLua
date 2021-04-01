LinkLuaModifier( "modifier_ability_astral_imprisonment", "heroes/obsidian_destroyer/astral_imprisonment", LUA_MODIFIER_MOTION_NONE )

ability_astral_imprisonment = {}

function ability_astral_imprisonment:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local duration = self:GetSpecialValueFor( "prison_duration" )

	target:AddNewModifier(
		caster,
		self,
		"modifier_ability_astral_imprisonment",
		{ duration = duration }
	)

	EmitSoundOn( "Hero_ObsidianDestroyer.AstralImprisonment.Cast", caster )
end

modifier_ability_astral_imprisonment = {}

function modifier_ability_astral_imprisonment:IsHidden()
	return false
end

function modifier_ability_astral_imprisonment:IsDebuff()
	return self:GetCaster():GetTeamNumber()~=self:GetParent():GetTeamNumber()
end

function modifier_ability_astral_imprisonment:IsStunDebuff()
	return true
end

function modifier_ability_astral_imprisonment:IsPurgable()
	return true
end

function modifier_ability_astral_imprisonment:RemoveOnDeath()
	return false
end

function modifier_ability_astral_imprisonment:OnCreated( kv )
	local damage = self:GetAbility():GetSpecialValueFor( "damage" )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )

	if not IsServer() then return end

	self.damageTable = {
		attacker = self:GetCaster(),
		damage = damage,
		damage_type = self:GetAbility():GetAbilityDamageType(),
		ability = self:GetAbility(),
	}

	self:GetParent():AddNoDraw()
	self:PlayEffects()
end

function modifier_ability_astral_imprisonment:OnRefresh( kv )
	local damage = self:GetAbility():GetSpecialValueFor( "damage" )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )

	if not IsServer() then return end

	self.damageTable.damage = damage
end

function modifier_ability_astral_imprisonment:OnDestroy()
	if not IsServer() then return end

	local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),
		self:GetParent():GetOrigin(),
		nil,
		self.radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0,
		0,
		false
	)

	for _,enemy in pairs(enemies) do
		self.damageTable.victim = enemy
		ApplyDamage( self.damageTable )

		SendOverheadEventMessage(
			nil,
			OVERHEAD_ALERT_BONUS_SPELL_DAMAGE,
			self:GetParent(),
			self.damageTable.damage,
			nil
		)
	end

	self:GetParent():RemoveNoDraw()
	StopSoundOn( "Hero_ObsidianDestroyer.AstralImprisonment", self:GetCaster() )
	EmitSoundOnLocationWithCaster( self:GetParent():GetOrigin(), "Hero_ObsidianDestroyer.AstralImprisonment.End", self:GetCaster() )
end

function modifier_ability_astral_imprisonment:CheckState()
	return {
		[MODIFIER_STATE_OUT_OF_GAME] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_STUNNED] = true,
	}
end

function modifier_ability_astral_imprisonment:PlayEffects()
	local effect_cast1 = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_prison.vpcf",
		PATTACH_WORLDORIGIN,
		nil
	)
	ParticleManager:SetParticleControl( effect_cast1, 0, self:GetParent():GetOrigin() )

	local effect_cast2 = ParticleManager:CreateParticleForTeam(
		"particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_prison_ring.vpcf",
		PATTACH_WORLDORIGIN,
		nil,
		self:GetCaster():GetTeamNumber()
	)
	ParticleManager:SetParticleControl( effect_cast2, 0, self:GetParent():GetOrigin() )

	self:AddParticle(
		effect_cast1,
		false,
		false,
		-1,
		false,
		false
	)

	self:AddParticle(
		effect_cast2,
		false,
		false,
		-1,
		false,
		false
	)

	EmitSoundOnLocationWithCaster( self:GetParent():GetOrigin(), "Hero_ObsidianDestroyer.AstralImprisonment", self:GetCaster() )
end