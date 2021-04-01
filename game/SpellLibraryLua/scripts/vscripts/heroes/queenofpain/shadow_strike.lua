LinkLuaModifier( "modifier_ability_shadow_strike", "heroes/queenofpain/shadow_strike", LUA_MODIFIER_MOTION_NONE )

ability_shadow_strike = {}

function ability_shadow_strike:OnSpellStart()
	local info = {
		Target = self:GetCursorTarget(),
		Source = self:GetCaster(),
		Ability = self,	
		EffectName = "particles/units/heroes/hero_queenofpain/queen_shadow_strike.vpcf",
		iMoveSpeed = self:GetSpecialValueFor( "projectile_speed" ),
		bReplaceExisting = false,
		bProvidesVision = false
	}
	ProjectileManager:CreateTrackingProjectile(info)

	EmitSoundOn( "Hero_QueenOfPain.ShadowStrike", caster )
end

function ability_shadow_strike:OnProjectileHit( target, location )
	if target==nil or target:IsInvulnerable() or target:TriggerSpellAbsorb( self ) then
		return
	end

	local debuffDuration = self:GetDuration()

	target:AddNewModifier(
		self:GetCaster(),
		self,
		"modifier_ability_shadow_strike",
		{ duration = debuffDuration }
	)	
end

function ability_shadow_strike:AbilityConsiderations()
	local bBlocked = target:TriggerSpellAbsorb( self )
end

modifier_ability_shadow_strike = {}

function modifier_ability_shadow_strike:IsHidden()
	return false
end

function modifier_ability_shadow_strike:IsDebuff()
	return true
end

function modifier_ability_shadow_strike:IsStunDebuff()
	return false
end

function modifier_ability_shadow_strike:IsPurgable()
	return true
end

function modifier_ability_shadow_strike:OnCreated( kv )
	self.total_duration = self:GetRemainingTime()
	self.max_slow = self:GetAbility():GetSpecialValueFor( "movement_slow" )
	local init_damage = self:GetAbility():GetSpecialValueFor( "strike_damage" )
	local tick_damage = self:GetAbility():GetSpecialValueFor( "duration_damage" )

	if IsServer() then	 
		self.damageTable = {
			victim = self:GetParent(),
			attacker = self:GetCaster(),
			damage = init_damage,
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self,
		}
		ApplyDamage( self.damageTable )

		self.damageTable.damage = tick_damage

		self.tick_instance = 5
		self.ticks = 0
		local tick_interval = self.total_duration/self.tick_instance

		self.tick_instance_slow = 15
		self.tick_interval_slow = self.total_duration/self.tick_instance_slow

		self:StartIntervalThink( tick_interval )

		local effect_cast = ParticleManager:CreateParticle(
			"particles/units/heroes/hero_queenofpain/queen_shadow_strike_debuff.vpcf",
			PATTACH_ABSORIGIN_FOLLOW,
			self:GetParent()
		)
		ParticleManager:SetParticleControlEnt(
			effect_cast,
			0,
			self:GetParent(),
			PATTACH_POINT_FOLLOW,
			"attach_hitloc",
			self:GetParent():GetAbsOrigin(),
			true
		)
		self:AddParticle(
			effect_cast,
			false,
			false,
			-1,
			false,
			false
		)
	end
end

function modifier_ability_shadow_strike:OnRemoved()
	if (self.ticks and self.tick_instance) and self.ticks < self.tick_instance then
		self:OnIntervalThink()
	end
end

function modifier_ability_shadow_strike:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_ability_shadow_strike:GetModifierMoveSpeedBonus_Percentage()
	return self.max_slow * (self:GetRemainingTime()/self.total_duration)
end

function modifier_ability_shadow_strike:CheckState()
	return { [MODIFIER_STATE_SPECIALLY_DENIABLE] = (self:GetParent():GetHealthPercent()<25) }
end

function modifier_ability_shadow_strike:OnIntervalThink()
	self.ticks = self.ticks + 1
	ApplyDamage( self.damageTable )
end