LinkLuaModifier( "modifier_ability_ignite", "heroes/ogre_magi/ignite", LUA_MODIFIER_MOTION_NONE )

ability_ignite = {}

function ability_ignite:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	local projectile_name = "particles/units/heroes/hero_ogre_magi/ogre_magi_ignite.vpcf"
	local projectile_speed = self:GetSpecialValueFor( "projectile_speed" )

	local info = {
		Target = target,
		Source = caster,
		Ability = self,	
		EffectName = projectile_name,
		iMoveSpeed = projectile_speed,
		bDodgeable = true,
	}
	ProjectileManager:CreateTrackingProjectile(info)

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		caster:GetOrigin(),
		nil,
		self:GetCastRange( target:GetOrigin(), target ),
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
		0,
		false
	)

	local target_2 = nil
	for _,enemy in pairs(enemies) do
		if enemy~=target and ( not enemy:HasModifier("modifier_ability_ignite") ) then
			target_2 = enemy
			break
		end
	end

	if target_2 then
		info.Target = target_2
		ProjectileManager:CreateTrackingProjectile(info)
	end

	EmitSoundOn( "Hero_OgreMagi.Ignite.Cast", caster )
end

function ability_ignite:OnProjectileHit( target, location )
	if not target then return end
	if target:TriggerSpellAbsorb( self ) then return end

	target:AddNewModifier(
		self:GetCaster(),
		self,
		"modifier_ability_ignite",
		{ duration = self:GetSpecialValueFor( "duration" ) }
	)

	EmitSoundOn( "Hero_OgreMagi.Ignite.Target", self:GetCaster() )
end

modifier_ability_ignite = {}

function modifier_ability_ignite:IsHidden()
	return false
end

function modifier_ability_ignite:IsDebuff()
	return true
end

function modifier_ability_ignite:IsStunDebuff()
	return false
end

function modifier_ability_ignite:IsPurgable()
	return true
end

function modifier_ability_ignite:OnCreated( kv )
	self.slow = self:GetAbility():GetSpecialValueFor( "slow_movement_speed_pct" )
	local damage = self:GetAbility():GetSpecialValueFor( "burn_damage" )

	if not IsServer() then return end

	local interval = 1

	self.damageTable = {
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage = damage,
		damage_type = self:GetAbility():GetAbilityDamageType(),
		ability = self, --Optional.
	}

	self:StartIntervalThink( interval )
end

function modifier_ability_ignite:OnRefresh( kv )
	self.slow = self:GetAbility():GetSpecialValueFor( "slow_movement_speed_pct" )
	local damage = self:GetAbility():GetSpecialValueFor( "burn_damage" )
	
	if not IsServer() then return end

	self.damageTable.damage = damage
end

function modifier_ability_ignite:OnRemoved()
end

function modifier_ability_ignite:OnDestroy()
end

function modifier_ability_ignite:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_ability_ignite:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end

function modifier_ability_ignite:OnIntervalThink()
	ApplyDamage( self.damageTable )
	EmitSoundOn( "Hero_OgreMagi.Ignite.Damage", self:GetParent() )
end

function modifier_ability_ignite:GetEffectName()
	return "particles/units/heroes/hero_ogre_magi/ogre_magi_ignite_debuff.vpcf"
end

function modifier_ability_ignite:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end