LinkLuaModifier( "modifier_ability_dark_artistry", "heroes/grimstroke/dark_artistry", LUA_MODIFIER_MOTION_NONE )

ability_dark_artistry = {}

function ability_dark_artistry:OnAbilityPhaseStart()
	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_grimstroke/grimstroke_cast2_ground.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		self:GetCaster()
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		self:GetCaster(),
		PATTACH_POINT_FOLLOW,
		"attach_attack2",
		Vector(),
		true
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_Grimstroke.DarkArtistry.PreCastPoint", self:GetCaster() )

	return true
end
function ability_dark_artistry:OnAbilityPhaseInterrupted()
	StopSoundOn( "Hero_Grimstroke.DarkArtistry.PreCastPoint", self:GetCaster() )
end

function ability_dark_artistry:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local spawnDelta = 150
	local projectile_name = "particles/units/heroes/hero_grimstroke/grimstroke_darkartistry_proj.vpcf"
	local distance = self:GetCastRange( point, nil )
	local start_radius = self:GetSpecialValueFor("start_radius")
	local end_radius = self:GetSpecialValueFor("end_radius")
	local speed = self:GetSpecialValueFor("projectile_speed")

	local spawnPos = caster:GetOrigin() + caster:GetRightVector()*(-spawnDelta)
	local direction = point-spawnPos
	direction.z = 0
	direction = direction:Normalized()

	local info = {
		Source = self:GetCaster(),
		Ability = self,
		vSpawnOrigin = spawnPos,
		
	    bDeleteOnHit = false,
	    
	    iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
	    iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
	    iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
	    
	    EffectName = projectile_name,
	    fDistance = distance,
	    fStartRadius = start_radius,
	    fEndRadius =end_radius,
		vVelocity = direction * speed,
	
		bHasFrontalCone = false,
		bReplaceExisting = false,
		
		bProvidesVision = false,

		EffectSound = "Hero_Grimstroke.DarkArtistry.Projectile",
		ProjectileSound = "Hero_Grimstroke.DarkArtistry.Projectile",
		SoundName = "Hero_Grimstroke.DarkArtistry.Projectile",
		Sound = "Hero_Grimstroke.DarkArtistry.Projectile",
		SoundEvent = "Hero_Grimstroke.DarkArtistry.Projectile",
	}
	ProjectileManager:CreateLinearProjectile( info )

	EmitSoundOn( "Hero_Grimstroke.DarkArtistry.Cast", caster )
	EmitSoundOn( "Hero_Grimstroke.DarkArtistry.Cast.Layer", caster )
end

ability_dark_artistry.active_proj = {}

function ability_dark_artistry:OnProjectileHitHandle( target, location, handle )
	if IsServer() then
		if not target then
			self.active_proj[handle] = nil
			return true
		end

		if not self.active_proj[handle] then
			self.active_proj[handle] = 0
		end

		local multiplier = self.active_proj[handle]
		local base_damage = self:GetAbilityDamage()
		local plus_damage = self:GetSpecialValueFor( "bonus_damage_per_target" )
		local slow = self:GetSpecialValueFor( "slow_duration" )
		local damageTable = {
			victim = target,
			attacker = self:GetCaster(),
			damage = base_damage + multiplier*plus_damage,
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self,
		}

		ApplyDamage(damageTable)

		target:AddNewModifier(
			self:GetCaster(),
			self,
			"modifier_ability_dark_artistry",
			{
				duration = slow,
			}
		)

		self.active_proj[handle] = multiplier + 1

		local effect_cast = ParticleManager:CreateParticle(
			"particles/units/heroes/hero_grimstroke/grimstroke_darkartistry_dmg.vpcf",
			PATTACH_ABSORIGIN_FOLLOW,
			target
		)
		ParticleManager:ReleaseParticleIndex( effect_cast )

		if target:IsCreep() then
			EmitSoundOn( "Hero_Grimstroke.DarkArtistry.Damage.Creep", target )
		else
			EmitSoundOn( "Hero_Grimstroke.DarkArtistry.Damage", target )
		end
	end
end

modifier_ability_dark_artistry = {}

function modifier_ability_dark_artistry:IsHidden()
	return false
end

function modifier_ability_dark_artistry:IsDebuff()
	return true
end

function modifier_ability_dark_artistry:IsStunDebuff()
	return false
end

function modifier_ability_dark_artistry:IsPurgable()
	return true
end

function modifier_ability_dark_artistry:OnCreated( kv )
	self.slow = self:GetAbility():GetSpecialValueFor( "movement_slow_pct" )
end

modifier_ability_dark_artistry.OnRefresh = modifier_ability_dark_artistry.OnCreated

function modifier_ability_dark_artistry:OnDestroy( kv )

end

function modifier_ability_dark_artistry:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_ability_dark_artistry:GetModifierMoveSpeedBonus_Percentage()
	return -self.slow
end

function modifier_ability_dark_artistry:GetEffectName()
	return "particles/units/heroes/hero_grimstroke/grimstroke_dark_artistry_debuff.vpcf"
end

function modifier_ability_dark_artistry:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end