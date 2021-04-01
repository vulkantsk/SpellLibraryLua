LinkLuaModifier( "modifier_ability_caustic_finale", "heroes/sand_king/caustic_finale", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_caustic_finale_debuff", "heroes/sand_king/caustic_finale", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_caustic_finale_slow", "heroes/sand_king/caustic_finale", LUA_MODIFIER_MOTION_NONE )

ability_caustic_finale = {}

function ability_caustic_finale:GetIntrinsicModifierName()
	return "modifier_ability_caustic_finale"
end

modifier_ability_caustic_finale = {}

function modifier_ability_caustic_finale:IsHidden()
	return true
end

function modifier_ability_caustic_finale:IsPurgable()
	return false
end

function modifier_ability_caustic_finale:OnCreated( kv )
	self.duration = self:GetAbility():GetSpecialValueFor( "caustic_finale_duration" )
end

modifier_ability_caustic_finale.OnRefresh = modifier_ability_caustic_finale.OnCreated

function modifier_ability_caustic_finale:DeclareFunctions()
	return { MODIFIER_PROPERTY_PROCATTACK_FEEDBACK }
end

function modifier_ability_caustic_finale:GetModifierProcAttack_Feedback( params )
	if IsServer() then
		if self:GetParent():PassivesDisabled() then return end
		if params.target:GetTeamNumber()==self:GetParent():GetTeamNumber() then return end
		if params.target:IsMagicImmune() then return end

		local modifier = params.target:FindModifierByNameAndCaster( "modifier_ability_caustic_finale_debuff", self:GetParent() )
		if not modifier then
			params.target:AddNewModifier(
				self:GetParent(),
				self:GetAbility(),
				"modifier_ability_caustic_finale_debuff",
				{ duration = self.duration }
			)
		end
	end
end

modifier_ability_caustic_finale_debuff = {}

function modifier_ability_caustic_finale_debuff:IsHidden()
	return false
end

function modifier_ability_caustic_finale_debuff:IsDebuff()
	return true
end

function modifier_ability_caustic_finale_debuff:IsPurgable()
	return true
end

function modifier_ability_caustic_finale_debuff:DestroyOnExpire()
	return false
end

function modifier_ability_caustic_finale_debuff:OnCreated( kv )
	self.radius = self:GetAbility():GetSpecialValueFor( "caustic_finale_radius" )
	self.damage = self:GetAbility():GetSpecialValueFor( "caustic_finale_damage" )
	self.damage_exp = self:GetAbility():GetSpecialValueFor( "caustic_finale_damage_expire" )
	self.slow_duration = self:GetAbility():GetSpecialValueFor( "caustic_finale_slow_duration" )

	if IsServer() then
		self:StartIntervalThink( kv.duration )
	end
end

function modifier_ability_caustic_finale_debuff:DeclareFunctions()
	return { MODIFIER_EVENT_ON_DEATH }
end

function modifier_ability_caustic_finale_debuff:OnDeath( params )
	if IsServer() then
		if params.unit~=self:GetParent() then return end
		if params.unit:GetTeamNumber()==params.attacker:GetTeamNumber() then return end

		self:Explode( true )
	end
end

function modifier_ability_caustic_finale_debuff:OnIntervalThink()
	self:Explode( false )
end

function modifier_ability_caustic_finale_debuff:Explode( death )
	local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),
		self:GetParent():GetAbsOrigin(),
		nil,
		self.radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0,
		0,
		false
	)

	local dmg = self.damage
	if death then dmg = self.damage_exp end
	local damageTable = {
		attacker = self:GetCaster(),
		damage = dmg,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self:GetAbility(),
	}

	for _,enemy in pairs(enemies) do
		enemy:AddNewModifier(
			self:GetCaster(),
			self:GetAbility(),
			"modifier_ability_caustic_finale_slow",
			{ duration = self.slow_duration }
		)

		damageTable.victim = enemy
		ApplyDamage(damageTable)
	end

	self:PlayEffects()
	self:Destroy()
end

function modifier_ability_caustic_finale_debuff:GetEffectName()
	return "particles/units/heroes/hero_sandking/sandking_caustic_finale_debuff.vpcf"
end

function modifier_ability_caustic_finale_debuff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_ability_caustic_finale_debuff:PlayEffects()
	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_sandking/sandking_caustic_finale_explode.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		self:GetParent()
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Ability.SandKing_CausticFinale", self:GetParent() )
end

modifier_ability_caustic_finale_slow = {}

function modifier_ability_caustic_finale_slow:IsHidden()
	return false
end

function modifier_ability_caustic_finale_slow:IsDebuff()
	return true
end

function modifier_ability_caustic_finale_slow:IsPurgable()
	return true
end

function modifier_ability_caustic_finale_slow:OnCreated( kv )
	self.slow = self:GetAbility():GetSpecialValueFor( "caustic_finale_slow" )
end

modifier_ability_caustic_finale_slow.OnRefresh = modifier_ability_caustic_finale_slow.OnCreated

function modifier_ability_caustic_finale_slow:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_ability_caustic_finale_slow:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end