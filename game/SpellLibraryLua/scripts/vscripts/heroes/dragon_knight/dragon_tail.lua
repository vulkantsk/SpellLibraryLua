ability_dragon_tail = {}

LinkLuaModifier( "modifier_ability_dragon_tail", "heroes/dragon_knight/dragon_tail", LUA_MODIFIER_MOTION_NONE )

function ability_dragon_tail:GetCastRange( vLocation, hTarget )
	if self:GetCaster():HasModifier( "modifier_ability_elder_dragon_form" ) then
		return 400
	else
		return self.BaseClass.GetCastRange( self, vLocation, hTarget )
	end
end

function ability_dragon_tail:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	local modifier = caster:FindModifierByNameAndCaster( "modifier_ability_elder_dragon_form", caster )

	if not modifier then
		if target:TriggerSpellAbsorb( self ) then return end

		self:Hit( target, false )

		EmitSoundOn( "Hero_DragonKnight.DragonTail.Cast", caster )

		return
	end

	local info = {
		Target = target,
		Source = caster,
		Ability = self,
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_2,
		EffectName = "particles/units/heroes/hero_dragon_knight/dragon_knight_dragon_tail_dragonform_proj.vpcf",
		iMoveSpeed = self:GetSpecialValueFor( "projectile_speed" ),
		bDodgeable = true,
		}
	ProjectileManager:CreateTrackingProjectile(info)
end

function ability_dragon_tail:Hit( target, dragonform )
	local caster = self:GetCaster()

	if target:TriggerSpellAbsorb( self ) then return end

	local damage = self:GetAbilityDamage()
	local duration = self:GetSpecialValueFor( "stun_duration" )

	local damageTable = {
		victim = target,
		attacker = caster,
		damage = damage,
		damage_type = self:GetAbilityDamageType(),
		ability = self,
	}

	ApplyDamage(damageTable)

	target:AddNewModifier(
		caster,
		self,
		"modifier_ability_dragon_tail",
		{ duration = duration }
	)

	self:PlayEffects( target, dragonform )
	EmitSoundOn( "Hero_DragonKnight.DragonTail.Target", target )
end

function ability_dragon_tail:OnProjectileHit( target, location )
	if not target then return end

	self:Hit( target, true )
end

function ability_dragon_tail:PlayEffects( target, dragonform )
	local vec = target:GetOrigin()-self:GetCaster():GetOrigin()
	local attach = "attach_attack1"
	if dragonform then
		attach = "attach_attack2"
	end

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_dragon_knight/dragon_knight_dragon_tail.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		target
	)
	ParticleManager:SetParticleControl( effect_cast, 3, vec )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		2,
		self:GetCaster(),
		PATTACH_POINT_FOLLOW,
		attach,
		Vector(0,0,0),
		true 
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		4,
		target,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(0,0,0),
		true
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )
end

modifier_ability_dragon_tail = {}

function modifier_ability_dragon_tail:IsDebuff()
	return true
end

function modifier_ability_dragon_tail:IsStunDebuff()
	return true
end

function modifier_ability_dragon_tail:IsPurgable()
	return true
end

function modifier_ability_dragon_tail:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
	}
end

function modifier_ability_dragon_tail:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}
end

function modifier_ability_dragon_tail:GetOverrideAnimation( params )
	return ACT_DOTA_DISABLED
end

function modifier_ability_dragon_tail:GetEffectName()
	return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_ability_dragon_tail:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end