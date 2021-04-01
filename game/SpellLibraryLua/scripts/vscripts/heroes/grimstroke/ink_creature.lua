LinkLuaModifier( "modifier_ability_ink_creature", "heroes/grimstroke/ink_creature", LUA_MODIFIER_MOTION_NONE )

ability_ink_creature = {}

function ability_ink_creature:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local duration = self:GetSpecialValueFor("buff_duration")

	target:AddNewModifier( self:GetCaster(), self, "modifier_ability_ink_creature", { duration = duration } )

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_grimstroke/grimstroke_cast_ink_swell.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		self:GetCaster()
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_Grimstroke.InkSwell.Cast", self:GetCaster() )
end

modifier_ability_ink_creature = {}

function modifier_ability_ink_creature:IsHidden()
	return false
end

function modifier_ability_ink_creature:IsDebuff()
	return false
end

function modifier_ability_ink_creature:IsPurgable()
	return true
end

function modifier_ability_ink_creature:OnCreated( kv )
	self.interval = self:GetAbility():GetSpecialValueFor( "tick_rate" )
	self.speed = self:GetAbility():GetSpecialValueFor( "movespeed_bonus_pct" )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )

	self.base_damage = self:GetAbility():GetSpecialValueFor( "damage" )
	self.base_stun = self:GetAbility():GetSpecialValueFor( "debuff_duration" )
	self.max_multiplier = self:GetAbility():GetSpecialValueFor( "max_bonus_multiplier" )

	local damage = self:GetAbility():GetSpecialValueFor( "damage_per_tick" )

	if IsServer() then
		self.counter = 0
		self.max_counter = 20

		self.damageTable = {
			attacker = self:GetCaster(),
			damage = damage,
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self:GetAbility(),
		}

		self:StartIntervalThink( self.interval )

		local effect_cast = ParticleManager:CreateParticle(
			"particles/units/heroes/hero_grimstroke/grimstroke_ink_swell_buff.vpcf",
			PATTACH_OVERHEAD_FOLLOW,
			self:GetParent()
		)
		ParticleManager:SetParticleControl( effect_cast, 2, Vector( self.radius, self.radius, self.radius ) )
		ParticleManager:SetParticleControlEnt(
			effect_cast,
			3,
			self:GetParent(),
			PATTACH_ABSORIGIN_FOLLOW,
			nil,
			self:GetParent():GetOrigin(),
			true
		)

		self:AddParticle(
			effect_cast,
			false,
			false,
			-1,
			false,
			true
		)

		EmitSoundOn( "Hero_Grimstroke.InkSwell.Target", self:GetParent() )
	end
end

function modifier_ability_ink_creature:OnRefresh( kv )
	local damage = self:GetAbility():GetSpecialValueFor( "damage_per_tick" )

	self.interval = self:GetAbility():GetSpecialValueFor( "tick_rate" )
	self.speed = self:GetAbility():GetSpecialValueFor( "movespeed_bonus_pct" )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )

	self.base_damage = self:GetAbility():GetSpecialValueFor( "damage" )
	self.base_stun = self:GetAbility():GetSpecialValueFor( "debuff_duration" )
	self.max_multiplier = self:GetAbility():GetSpecialValueFor( "max_bonus_multiplier" )

	if IsServer() then
		self.damageTable.damage = damage
	end
end

function modifier_ability_ink_creature:OnDestroy( kv )
	if IsServer() then
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

		local multiplier = math.min(self.counter/self.max_counter,1)
		local stun = self.base_stun + self.base_stun*self.max_multiplier*multiplier
		self.damageTable.damage = self.base_damage + self.base_damage*self.max_multiplier*multiplier
		
		for _,enemy in pairs(enemies) do
			self.damageTable.victim = enemy
			ApplyDamage( self.damageTable )

			enemy:AddNewModifier(
				self:GetCaster(),
				self:GetAbility(),
				"modifier_stunned",
				{ duration = stun }
			)
		end

		local effect_cast = ParticleManager:CreateParticle(
			"particles/units/heroes/hero_grimstroke/grimstroke_ink_swell_aoe.vpcf",
			PATTACH_ABSORIGIN_FOLLOW,
			self:GetParent()
		)
		ParticleManager:SetParticleControl( effect_cast, 2, Vector( self.radius, self.radius, self.radius ) )
		ParticleManager:ReleaseParticleIndex( effect_cast )

		EmitSoundOn( "Hero_Grimstroke.InkSwell.Stun", self:GetParent() )
		StopSoundOn( "Hero_Grimstroke.InkSwell.Target", self:GetParent() )
	end
end

function modifier_ability_ink_creature:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_ability_ink_creature:GetModifierMoveSpeedBonus_Percentage()
	return self.speed
end

function modifier_ability_ink_creature:CheckState()
	return {
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_SILENCED] = true,
	}
end

function modifier_ability_ink_creature:OnIntervalThink()
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
		self.counter = self.counter + 1

		ApplyDamage(self.damageTable)

		local effect_cast = ParticleManager:CreateParticle(
			"particles/units/heroes/hero_grimstroke/grimstroke_ink_swell_tick_damage.vpcf",
			PATTACH_ABSORIGIN_FOLLOW,
			self:GetParent()
		)
		ParticleManager:SetParticleControlEnt(
			effect_cast,
			0,
			self:GetParent(),
			PATTACH_POINT_FOLLOW,
			"attach_hitloc",
			Vector(),
			true
		)
		ParticleManager:SetParticleControlEnt(
			effect_cast,
			1,
			enemy,
			PATTACH_POINT_FOLLOW,
			"attach_hitloc",
			Vector(),
			true
		)
		ParticleManager:ReleaseParticleIndex( effect_cast )

		EmitSoundOn( "Hero_Grimstroke.InkSwell.Damage", enemy )
	end
end

function modifier_ability_ink_creature:GetStatusEffectName()
	return "particles/status_fx/status_effect_grimstroke_ink_swell.vpcf"
end