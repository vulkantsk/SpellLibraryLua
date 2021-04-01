LinkLuaModifier( "modifier_ability_illusory_orb_thinker", "heroes/puck/illusory_orb", LUA_MODIFIER_MOTION_NONE )

ability_illusory_orb = {}
ability_illusory_orb.projectiles = {}
ability_ethereal_jaunt = {}

function ability_illusory_orb:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local damage = self:GetAbilityDamage()
	local projectile_speed = self:GetSpecialValueFor("orb_speed")
	local projectile_distance = self:GetSpecialValueFor("max_distance")
	local projectile_radius = self:GetSpecialValueFor("radius")
	local vision_radius = self:GetSpecialValueFor("orb_vision")
	local vision_duration = self:GetSpecialValueFor("vision_duration")

	local projectile_direction = point-caster:GetOrigin()
	projectile_direction = Vector( projectile_direction.x, projectile_direction.y, 0 ):Normalized()

	local projectile = ProjectileManager:CreateLinearProjectile({
		Source = caster,
		Ability = self,
		vSpawnOrigin = caster:GetOrigin(),
		bDeleteOnHit = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		EffectName = "particles/units/heroes/hero_puck/puck_illusory_orb.vpcf",
		fDistance = projectile_distance,
		fStartRadius = projectile_radius,
		fEndRadius =projectile_radius,
		vVelocity = projectile_direction * projectile_speed,
		bReplaceExisting = false,
		bProvidesVision = true,
		iVisionRadius = vision_radius,
		iVisionTeamNumber = caster:GetTeamNumber(),
	})

	local modifier = CreateModifierThinker(
		caster,
		self,
		"modifier_ability_illusory_orb_thinker",
		{ duration = 20 },
		caster:GetOrigin(),
		caster:GetTeamNumber(),
		false		
	)
	modifier = modifier:FindModifierByName( "modifier_ability_illusory_orb_thinker" )

	local extraData = {}
	extraData.damage = damage
	extraData.location = caster:GetOrigin()
	extraData.time = GameRules:GetGameTime()
	extraData.modifier = modifier
	self.projectiles[projectile] = extraData
	self.jaunt:SetActivated( true )
end

function ability_illusory_orb:OnProjectileThinkHandle( proj )
	local location = ProjectileManager:GetLinearProjectileLocation( proj )
	self.projectiles[proj].location = location
	self.projectiles[proj].modifier:GetParent():SetOrigin( location )
end

function ability_illusory_orb:OnProjectileHitHandle( target, location, proj )
	if not target then
		self.projectiles[proj].modifier:Destroy()
		self.projectiles[proj] = nil
		self.jaunt:Deactivate()
		return true
	end

	local damageTable = {
		victim = target,
		attacker = self:GetCaster(),
		damage = self.projectiles[proj].damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self,
	}
	ApplyDamage(damageTable)

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_puck/puck_orb_damage.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		target
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_Puck.IIllusory_Orb_Damage", target )

	return false
end

function ability_illusory_orb:OnUpgrade()
	if not self.jaunt then
		self.jaunt = self:GetCaster():FindAbilityByName( "ability_ethereal_jaunt" )
		self.jaunt.projectiles = self.projectiles
		self.jaunt:SetActivated( false )
	end

	self.jaunt:UpgradeAbility( true )
end

function ability_ethereal_jaunt:OnSpellStart()
	local first = false
	for k,v in pairs(self.projectiles) do
		first = k
		break
	end
	if not first then return end

	for idx,projectile in pairs(self.projectiles) do
		if projectile.time < self.projectiles[first].time then
			first = idx
		end
	end

	local old_pos = self:GetCaster():GetOrigin()
	FindClearSpaceForUnit( self:GetCaster(), ProjectileManager:GetLinearProjectileLocation( first ), true )
	ProjectileManager:ProjectileDodge( self:GetCaster() )

	ProjectileManager:DestroyLinearProjectile( first )
	self.projectiles[first].modifier:Destroy()
	self.projectiles[first] = nil
	self:Deactivate()

	local caster = self:GetCaster()
	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_puck/puck_illusory_orb_blink_out.vpcf",
		PATTACH_ABSORIGIN,
		caster
	)
	ParticleManager:SetParticleControl( effect_cast, 0, old_pos )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_Puck.EtherealJaunt", self:GetCaster() )
end

function ability_ethereal_jaunt:Deactivate()
	local any = false
	for k,v in pairs(self.projectiles) do
		any = true
		break
	end
	if not any then
		self:SetActivated( false )
	end
end

modifier_ability_illusory_orb_thinker = {}

function modifier_ability_illusory_orb_thinker:IsHidden()
	return true
end

function modifier_ability_illusory_orb_thinker:IsPurgable()
	return false
end

function modifier_ability_illusory_orb_thinker:OnCreated( kv )
	if IsServer() then
		EmitSoundOn( "Hero_Puck.Illusory_Orb", self:GetParent() )
	end
end

function modifier_ability_illusory_orb_thinker:OnDestroy( kv )
	if IsServer() then
		StopSoundOn( "Hero_Puck.Illusory_Orb", self:GetParent() )
		UTIL_Remove( self:GetParent() )
	end
end