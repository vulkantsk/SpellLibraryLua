LinkLuaModifier( "modifier_ability_chakram", "heroes/shredder/chakram", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_chakram_disarm", "heroes/shredder/chakram", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_chakram_thinker", "heroes/shredder/chakram", LUA_MODIFIER_MOTION_NONE )

ability_chakram = {}

ability_chakram.sub_name = "ability_return_chakram"
ability_chakram.scepter = 0

function ability_chakram:GetAOERadius()
	return self:GetSpecialValueFor( "radius" )
end

function ability_chakram:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	local thinker = CreateModifierThinker(
		caster,
		self,
		"modifier_ability_chakram_thinker",
		{
			target_x = point.x,
			target_y = point.y,
			target_z = point.z,
			scepter = self.scepter,
		},
		caster:GetOrigin(),
		caster:GetTeamNumber(),
		false
	)
	local modifier = thinker:FindModifierByName( "modifier_ability_chakram_thinker" )
	local sub = caster:FindAbilityByName( self.sub_name )

	caster:SwapAbilities(
		self:GetAbilityName(),
		self.sub_name,
		false,
		true
	)

	self.modifier = modifier
	sub.modifier = modifier
	modifier.sub = sub

	EmitSoundOn( "Hero_Shredder.Chakram.Cast", caster )
end

function ability_chakram:OnUpgrade()
	self:GetCaster():FindAbilityByName( self.sub_name ):SetLevel(1)
end

function ability_chakram:OnUnStolen()
	if self.modifier and not self.modifier:IsNull() then
		self.modifier:ReturnChakram()

		self:GetCaster():SwapAbilities(
			self:GetAbilityName(),
			self.sub_name,
			true,
			false
		)
	end
end

function ability_chakram:OnInventoryContentsChanged( params )
	local caster = self:GetCaster()

	local scepter = caster:HasScepter()
	local ability = caster:FindAbilityByName( "ability_chakram_2" )

	if not ability then return end

	ability:SetActivated( scepter )
	ability:SetHidden( not scepter )

	if ability:GetLevel()<1 then
		ability:SetLevel( 1 )
	end
end

ability_return_chakram = {}

function ability_return_chakram:OnSpellStart()
	if self.modifier and not self.modifier:IsNull() then
		self.modifier:ReturnChakram()
	end
end

ability_chakram_2 = class(ability_chakram)
ability_chakram_2.sub_name = "ability_return_chakram_2"
ability_chakram_2.scepter = 1
ability_chakram_2.OnInventoryContentsChanged = nil

ability_return_chakram_2 = class(ability_return_chakram)

modifier_ability_chakram_thinker = {}
local MODE_LAUNCH = 0
local MODE_STAY = 1
local MODE_RETURN = 2

function modifier_ability_chakram_thinker:IsHidden()
	return true
end

function modifier_ability_chakram_thinker:IsPurgable()
	return false
end

function modifier_ability_chakram_thinker:OnCreated( kv )
	if not IsServer() then return end
	self.parent = self:GetParent()
	self.caster = self:GetCaster()

	-- references
	self.damage_pass = self:GetAbility():GetSpecialValueFor( "pass_damage" )
	self.damage_stay = self:GetAbility():GetSpecialValueFor( "damage_per_second" )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
	self.speed = self:GetAbility():GetSpecialValueFor( "speed" )
	self.duration = self:GetAbility():GetSpecialValueFor( "pass_slow_duration" )
	self.manacost = self:GetAbility():GetSpecialValueFor( "mana_per_second" )
	self.max_range = self:GetAbility():GetSpecialValueFor( "break_distance" )
	self.interval = self:GetAbility():GetSpecialValueFor( "damage_interval" )

	-- kv references
	self.point = Vector( kv.target_x, kv.target_y, kv.target_z )
	self.scepter = kv.scepter==1

	-- init vars
	self.mode = MODE_LAUNCH
	self.move_interval = FrameTime()
	self.proximity = 50
	self.caught_enemies = {}
	self.damageTable = {
		-- victim = target,
		attacker = self.caster,
		-- damage = damage,
		damage_type = self:GetAbility():GetAbilityDamageType(),
		ability = self:GetAbility(), --Optional.
	}
	-- ApplyDamage(damageTable)

	-- give vision to thinker
	self.parent:SetDayTimeVisionRange( 500 )
	self.parent:SetNightTimeVisionRange( 500 )

	-- add disarm to caster
	self.disarm = self.caster:AddNewModifier(
		self.caster, -- player source
		self:GetAbility(), -- ability source
		"modifier_ability_chakram_disarm", -- modifier name
		{} -- kv
	)

	-- Init mode
	self.damageTable.damage = self.damage_pass
	self:StartIntervalThink( self.move_interval )

	-- play effects
	self:PlayEffects1()
end

function modifier_ability_chakram_thinker:OnDestroy()
	if not IsServer() then return end

	self.disarm:Destroy()

	self.caster:SwapAbilities(
		self:GetAbility():GetAbilityName(),
		self:GetAbility().sub_name,
		true,
		false
	)

	self:StopEffects()

	UTIL_Remove( self.parent )
end

function modifier_ability_chakram_thinker:OnIntervalThink()
	if self.mode==MODE_LAUNCH then
		self:LaunchThink()
	elseif self.mode==MODE_STAY then
		self:StayThink()
	elseif self.mode==MODE_RETURN then
		self:ReturnThink()
	end
end

function modifier_ability_chakram_thinker:LaunchThink()
	local origin = self.parent:GetOrigin()

	self:PassLogic( origin )

	local close = self:MoveLogic( origin )

	if close then
		self.mode = MODE_STAY
		self.damageTable.damage = self.damage_stay*self.interval
		self:StartIntervalThink( self.interval )
		self:OnIntervalThink()

		self:PlayEffects2()
	end
end

function modifier_ability_chakram_thinker:StayThink()
	local origin = self.parent:GetOrigin()

	local mana = self.caster:GetMana()
	if (self.caster:GetOrigin()-origin):Length2D()>self.max_range or mana<self.manacost*self.interval or (not self.caster:IsAlive()) then
		self:ReturnChakram()
		return
	end

	self.caster:SpendMana( self.manacost*self.interval, self:GetAbility() )

	local enemies = FindUnitsInRadius(
		self.caster:GetTeamNumber(),
		origin,
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
	end

	local trees = GridNav:GetAllTreesAroundPoint( origin, self.radius, true )
	for _,tree in pairs(trees) do
		EmitSoundOnLocationWithCaster( tree:GetOrigin(), "Hero_Shredder.Chakram.Tree", self.parent )
	end
	GridNav:DestroyTreesAroundPoint( origin, self.radius, true )
end

function modifier_ability_chakram_thinker:ReturnThink()
	local origin = self.parent:GetOrigin()

	self:PassLogic( origin )

	self.point = self.caster:GetOrigin( )
	local close = self:MoveLogic( origin )

	if close then
		self:Destroy()
	end
end

function modifier_ability_chakram_thinker:PassLogic( origin )
	local enemies = FindUnitsInRadius(
		self.caster:GetTeamNumber(),
		origin,
		nil,
		self.radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0,
		0,
		false
	)

	for _,enemy in pairs(enemies) do
		if not self.caught_enemies[enemy] then
			self.caught_enemies[enemy] = true

			self.damageTable.victim = enemy
			ApplyDamage( self.damageTable )

			enemy:AddNewModifier(
				self.caster,
				self:GetAbility(),
				"modifier_ability_chakram",
				{ duration = self.duration }
			)

			EmitSoundOn( "Hero_Shredder.Chakram.Target", enemy )
		end
	end

	local trees = GridNav:GetAllTreesAroundPoint( origin, self.radius, true )
	for _,tree in pairs(trees) do
		EmitSoundOnLocationWithCaster( tree:GetOrigin(), "Hero_Shredder.Chakram.Tree", self.parent )
	end
	GridNav:DestroyTreesAroundPoint( origin, self.radius, true )
end

function modifier_ability_chakram_thinker:MoveLogic( origin )
	local direction = (self.point-origin):Normalized()
	local target = origin + direction * self.speed * self.move_interval
	self.parent:SetOrigin( target )

	return (target-self.point):Length2D()<self.proximity
end

function modifier_ability_chakram_thinker:ReturnChakram()
	if self.mode == MODE_RETURN then return end

	self.mode = MODE_RETURN
	self.caught_enemies = {}
	self.damageTable.damage = self.damage_pass
	self:StartIntervalThink( self.move_interval )

	self:PlayEffects3()
end

function modifier_ability_chakram_thinker:IsAura()
	return self.mode==MODE_STAY
end

function modifier_ability_chakram_thinker:GetModifierAura()
	return "modifier_ability_chakram"
end

function modifier_ability_chakram_thinker:GetAuraRadius()
	return self.radius
end

function modifier_ability_chakram_thinker:GetAuraDuration()
	return 0.3
end

function modifier_ability_chakram_thinker:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_ability_chakram_thinker:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_ability_chakram_thinker:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_ability_chakram_thinker:PlayEffects1()

	local direction = self.point-self.parent:GetOrigin()
	direction.z = 0
	direction = direction:Normalized()

	self.effect_cast = ParticleManager:CreateParticle("particles/units/heroes/hero_shredder/shredder_chakram.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent )
	ParticleManager:SetParticleControl( self.effect_cast, 0, self:GetParent():GetOrigin() )
	ParticleManager:SetParticleControl( self.effect_cast, 1, direction * self.speed )
	ParticleManager:SetParticleControl( self.effect_cast, 16, Vector( 0, 0, 0 ) )

	if self.scepter then
		ParticleManager:SetParticleControl( self.effect_cast, 15, Vector( 0, 0, 255 ) )
		ParticleManager:SetParticleControl( self.effect_cast, 16, Vector( 1, 0, 0 ) )
	end

	EmitSoundOn( "Hero_Shredder.Chakram", self.parent )
end

function modifier_ability_chakram_thinker:PlayEffects2()
	ParticleManager:DestroyParticle( self.effect_cast, false )
	ParticleManager:ReleaseParticleIndex( self.effect_cast )

	self.effect_cast = ParticleManager:CreateParticle("particles/units/heroes/hero_shredder/shredder_chakram_stay.vpcf", PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( self.effect_cast, 0, self.parent:GetOrigin() )
	ParticleManager:SetParticleControl( self.effect_cast, 16, Vector( 0, 0, 0 ) )

	if self.scepter then
		ParticleManager:SetParticleControl( self.effect_cast, 15, Vector( 0, 0, 255 ) )
		ParticleManager:SetParticleControl( self.effect_cast, 16, Vector( 1, 0, 0 ) )
	end
end

function modifier_ability_chakram_thinker:PlayEffects3()
	ParticleManager:DestroyParticle( self.effect_cast, false )
	ParticleManager:ReleaseParticleIndex( self.effect_cast )

	self.effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_shredder/shredder_chakram_return.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent )
	ParticleManager:SetParticleControl( self.effect_cast, 0, self:GetParent():GetOrigin() )
	ParticleManager:SetParticleControlEnt(
		self.effect_cast,
		1,
		self.caster,
		PATTACH_ABSORIGIN_FOLLOW,
		nil,
		self.caster:GetOrigin(),
		true
	)
	ParticleManager:SetParticleControl( self.effect_cast, 2, Vector( self.speed, 0, 0 ) )
	ParticleManager:SetParticleControl( self.effect_cast, 16, Vector( 0, 0, 0 ) )

	if self.scepter then
		ParticleManager:SetParticleControl( self.effect_cast, 15, Vector( 0, 0, 255 ) )
		ParticleManager:SetParticleControl( self.effect_cast, 16, Vector( 1, 0, 0 ) )
	end

	EmitSoundOn( "Hero_Shredder.Chakram.Return", self.parent )
end

function modifier_ability_chakram_thinker:StopEffects()
	ParticleManager:DestroyParticle( self.effect_cast, false )
	ParticleManager:ReleaseParticleIndex( self.effect_cast )

	StopSoundOn( "Hero_Shredder.Chakram", self.parent )
end

modifier_ability_chakram_disarm = {}

function modifier_ability_chakram_disarm:IsHidden()
	return false
end

function modifier_ability_chakram_disarm:IsDebuff()
	return false
end

function modifier_ability_chakram_disarm:IsPurgable()
	return false
end

function modifier_ability_chakram_disarm:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_ability_chakram_disarm:CheckState()
	return {
		[MODIFIER_STATE_DISARMED] = true,
	}
end

modifier_ability_chakram = {}

function modifier_ability_chakram:IsHidden()
	return false
end

function modifier_ability_chakram:IsDebuff()
	return true
end

function modifier_ability_chakram:IsStunDebuff()
	return false
end

function modifier_ability_chakram:IsPurgable()
	return true
end

function modifier_ability_chakram:OnCreated( kv )
	if self:GetAbility() and not self:GetAbility():IsNull() then
		self.slow = self:GetAbility():GetSpecialValueFor( "slow" )
	else
		self.slow = 0
	end
	self.step = 5
end

function modifier_ability_chakram:OnRefresh( kv )
	self:OnCreated( kv )
end

function modifier_ability_chakram:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_ability_chakram:GetModifierMoveSpeedBonus_Percentage()
	return -math.floor( (100-self:GetParent():GetHealthPercent())/self.step ) * self.slow
end

function modifier_ability_chakram:GetStatusEffectName()
	return "particles/status_fx/status_effect_frost.vpcf"
end