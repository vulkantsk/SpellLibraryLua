ability_pulse_nova = {}

LinkLuaModifier( "modifier_ability_pulse_nova", "heroes/leshrac/pulse_nova", LUA_MODIFIER_MOTION_NONE )

function ability_pulse_nova:OnToggle()
	local caster = self:GetCaster()
	local toggle = self:GetToggleState()

	if toggle then
		self.modifier = caster:AddNewModifier(
			caster,
			self,
			"modifier_ability_pulse_nova",
			{}
		)
	else
		if self.modifier and not self.modifier:IsNull() then
			self.modifier:Destroy()
		end
		self.modifier = nil
	end
end

modifier_ability_pulse_nova = {}

function modifier_ability_pulse_nova:IsHidden()
	return false
end

function modifier_ability_pulse_nova:IsDebuff()
	return false
end

function modifier_ability_pulse_nova:IsPurgable()
	return false
end

function modifier_ability_pulse_nova:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT 
end

function modifier_ability_pulse_nova:OnCreated( kv )
	if not IsServer() then return end

	local damage = self:GetAbility():GetSpecialValueFor( "damage" )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
	self.manacost = self:GetAbility():GetSpecialValueFor( "mana_cost_per_second" )
	local interval = 1

	self.parent = self:GetParent()
	self.damageTable = {
		attacker = self:GetParent(),
		damage = damage,
		damage_type = self:GetAbility():GetAbilityDamageType(),
		ability = self:GetAbility(),
	}

	self:Burn()
	self:StartIntervalThink( interval )

	EmitSoundOn( "Hero_Leshrac.Pulse_Nova", self.parent )
end

function modifier_ability_pulse_nova:OnDestroy()
	if not IsServer() then return end

	StopSoundOn( "Hero_Leshrac.Pulse_Nova", self.parent )
end

function modifier_ability_pulse_nova:OnIntervalThink()
	if self.parent:GetMana() < self.manacost then
		if self:GetAbility():GetToggleState() then
			self:GetAbility():ToggleAbility()
		end

		return
	end

	self:Burn()
end

function modifier_ability_pulse_nova:Burn()
	self.parent:SpendMana( self.manacost, self:GetAbility() )

	local enemies = FindUnitsInRadius(
		self.parent:GetTeamNumber(),
		self.parent:GetOrigin(),
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

		local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_leshrac/leshrac_pulse_nova.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy )

		ParticleManager:SetParticleControlEnt(
			effect_cast,
			0,
			enemy,
			PATTACH_POINT_FOLLOW,
			"attach_hitloc",
			Vector( 0, 0, 0 ),
			true
		)

		ParticleManager:SetParticleControl( effect_cast, 1, Vector( 100, 0, 0 ) )
		ParticleManager:ReleaseParticleIndex( effect_cast )

		EmitSoundOn( "Hero_Leshrac.Pulse_Nova_Strike", enemy )
	end
end

function modifier_ability_pulse_nova:GetEffectName()
	return "particles/units/heroes/hero_leshrac/leshrac_pulse_nova_ambient.vpcf"
end

function modifier_ability_pulse_nova:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end