ability_hellfire_blast = {}

LinkLuaModifier("modifier_ability_hellfire_blast", "heroes/skeleton_king/hellfire_blast", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_ability_hellfire_blast_slow", "heroes/skeleton_king/hellfire_blast", LUA_MODIFIER_MOTION_NONE )

function ability_hellfire_blast:OnSpellStart()
	ProjectileManager:CreateTrackingProjectile( {
		EffectName = "particles/units/heroes/hero_skeletonking/skeletonking_hellfireblast.vpcf",
		Ability = self,
		iMoveSpeed = self:GetSpecialValueFor("blast_speed"),
		Source = self:GetCaster(),
		Target = self:GetCursorTarget(),
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_2
	} )

	EmitSoundOn( "Hero_SkeletonKing.Hellfire_Blast", self:GetCaster() )
end

function ability_hellfire_blast:OnProjectileHit( hTarget, vLocation )
	if hTarget ~= nil and ( not hTarget:IsInvulnerable() ) and ( not hTarget:IsMagicImmune() ) and ( not hTarget:TriggerSpellAbsorb( self ) ) then
		local stun_duration = self:GetSpecialValueFor( "blast_stun_duration" )
		local stun_damage = self:GetAbilityDamage()
		local dot_duration = self:GetSpecialValueFor( "blast_dot_duration" )

		local damage = {
			victim = hTarget,
			attacker = self:GetCaster(),
			damage = stun_damage,
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self
		}
		ApplyDamage( damage )

		hTarget:AddNewModifier( self:GetCaster(), self, "modifier_ability_hellfire_blast", { duration = stun_duration } )
		hTarget:AddNewModifier( self:GetCaster(), self, "modifier_ability_hellfire_blast_slow", { duration = dot_duration } )

		EmitSoundOn( "Hero_SkeletonKing.Hellfire_BlastImpact", hTarget )
	end

	return true
end

modifier_ability_hellfire_blast = {}

function modifier_ability_hellfire_blast:IsDebuff()
	return true
end

function modifier_ability_hellfire_blast:IsStunDebuff()
	return true
end

function modifier_ability_hellfire_blast:GetEffectName()
	return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_ability_hellfire_blast:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_ability_hellfire_blast:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}
end

function modifier_ability_hellfire_blast:GetOverrideAnimation( params )
	return ACT_DOTA_DISABLED
end

function modifier_ability_hellfire_blast:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
	}
end

modifier_ability_hellfire_blast_slow = {}

function modifier_ability_hellfire_blast_slow:IsDebuff()
	return true
end

function modifier_ability_hellfire_blast_slow:OnCreated( kv )
	self.dot_damage = self:GetAbility():GetSpecialValueFor( "blast_dot_damage" )
	self.dot_slow = self:GetAbility():GetSpecialValueFor( "blast_slow" )
	self.tick = 0
	self.interval = self:GetRemainingTime() / kv.duration
	self.duration = kv.duration

	self:StartIntervalThink( self.interval )
end

modifier_ability_hellfire_blast_slow.OnRefresh = modifier_ability_hellfire_blast_slow.OnCreated

function modifier_ability_hellfire_blast_slow:OnDestroy()
	if IsServer() then
		if self.tick < self.duration then
			self:OnIntervalThink()
		end
	end
end

function modifier_ability_hellfire_blast_slow:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_ability_hellfire_blast_slow:GetModifierMoveSpeedBonus_Percentage( params )
	return self.dot_slow
end

function modifier_ability_hellfire_blast_slow:OnIntervalThink()
	if IsServer() then
		local damage = {
			victim = self:GetParent(),
			attacker = self:GetCaster(),
			damage = self.dot_damage,
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self:GetAbility()
		}
		ApplyDamage( damage )
	end

	self.tick = self.tick + 1
end

function modifier_ability_hellfire_blast_slow:GetEffectName()
	return "particles/units/heroes/hero_skeletonking/skeletonking_hellfireblast_debuff.vpcf"
end

function modifier_ability_hellfire_blast_slow:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end