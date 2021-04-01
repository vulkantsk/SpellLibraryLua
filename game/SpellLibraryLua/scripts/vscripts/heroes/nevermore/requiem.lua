LinkLuaModifier( "modifier_ability_requiem", "heroes/nevermore/requiem", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_requiem_scepter", "heroes/nevermore/requiem", LUA_MODIFIER_MOTION_NONE )

ability_requiem = {}

function ability_requiem:OnAbilityPhaseStart()
	self.effect_precast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_nevermore/nevermore_wings.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		self:GetCaster()
	)	

	EmitSoundOn("Hero_Nevermore.RequiemOfSoulsCast", self:GetCaster())

	return true
end

function ability_requiem:OnAbilityPhaseInterrupted()
	ParticleManager:DestroyParticle( self.effect_precast, true )
	ParticleManager:ReleaseParticleIndex( self.effect_precast )

	StopSoundOn("Hero_Nevermore.RequiemOfSoulsCast", self:GetCaster())
end

function ability_requiem:OnSpellStart()
	local soul_per_line = self:GetSpecialValueFor("requiem_soul_conversion")

	local lines = 0
	local modifier = self:GetCaster():FindModifierByNameAndCaster( "modifier_ability_necromastery", self:GetCaster() )
	if modifier~=nil then
		lines = math.floor(modifier:GetStackCount() / soul_per_line) 
	end

	self:Explode( lines )

	if self:GetCaster():HasScepter() then
		local explodeDuration = self:GetSpecialValueFor("requiem_radius") / self:GetSpecialValueFor("requiem_line_speed")
		self:GetCaster():AddNewModifier(
			self:GetCaster(),
			self,
			"modifier_ability_requiem_scepter",
			{
				lineDuration = explodeDuration,
				lineNumber = lines,
			}
		)
	end
end

function ability_requiem:OnProjectileHit_ExtraData( hTarget, vLocation, params )
	if hTarget ~= nil then
		pass = false
		if hTarget:GetTeamNumber()~=self:GetCaster():GetTeamNumber() then
			pass = true
		end

		if pass then
			if params and params.scepter then
				damage = self.damage * (self.damage_pct/100)

				if hTarget:IsHero() then
					local modifier = self:RetATValue( params.modifier )
					modifier:AddTotalHeal( damage )
				end
			end

			local damage = {
				victim = hTarget,
				attacker = self:GetCaster(),
				damage = self.damage,
				damage_type = DAMAGE_TYPE_MAGICAL,
				ability = this,
			}
			ApplyDamage( damage )

			hTarget:AddNewModifier(
				self:GetCaster(),
				self,
				"modifier_ability_requiem",
				{ duration = self.duration }
			)
		end
	end

	return false
end

function ability_requiem:OnOwnerDied()
	if self:GetLevel()<1 then return end

	local soul_per_line = self:GetSpecialValueFor("requiem_soul_conversion")

	local lines = 0
	local modifier = self:GetCaster():FindModifierByNameAndCaster( "modifier_ability_necromastery", self:GetCaster() )
	if modifier~=nil then
		lines = math.floor(modifier:GetStackCount() / soul_per_line) 
	end

	self:Explode( lines/2 )
end

function ability_requiem:Explode( lines )
	self.damage =  self:GetAbilityDamage()
	self.duration = self:GetSpecialValueFor("requiem_slow_duration")

	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("requiem_radius")
	local line_speed = self:GetSpecialValueFor("requiem_line_speed")
	local initial_angle_deg = self:GetCaster():GetAnglesAsVector().y
	local delta_angle = 360/lines
	for i=0,lines-1 do
		local facing_angle_deg = initial_angle_deg + delta_angle * i
		if facing_angle_deg>360 then facing_angle_deg = facing_angle_deg - 360 end
		local facing_angle = math.rad(facing_angle_deg)
		local facing_vector = Vector( math.cos(facing_angle), math.sin(facing_angle), 0 ):Normalized()
		local velocity = facing_vector * line_speed

		ProjectileManager:CreateLinearProjectile( {
			Source = caster,
			Ability = self,
			EffectName = "particles/units/heroes/hero_nevermore/nevermore_requiemofsouls_line.vpcf",
			vSpawnOrigin = self:GetCaster():GetAbsOrigin(),
			fDistance = radius,
			vVelocity = velocity,
			fStartRadius = self:GetSpecialValueFor("requiem_line_width_start"),
			fEndRadius = self:GetSpecialValueFor("requiem_line_width_end"),
			iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_SPELL_IMMUNE_ENEMIES,
			iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			bReplaceExisting = false,
			bProvidesVision = false,
		} )

		local effect_line = ParticleManager:CreateParticle(
			"particles/units/heroes/hero_nevermore/nevermore_requiemofsouls_line.vpcf",
			PATTACH_ABSORIGIN,
			caster
		)
		ParticleManager:SetParticleControl(effect_line, 0, caster:GetAbsOrigin())
		ParticleManager:SetParticleControl(effect_line, 1, velocity)
		ParticleManager:SetParticleControl(effect_line, 2, Vector(0, radius / line_speed, 0))
		ParticleManager:ReleaseParticleIndex(effect_line)
	end

	ParticleManager:ReleaseParticleIndex( self.effect_precast )

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_nevermore/nevermore_requiemofsouls.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		self:GetCaster()
	)
	ParticleManager:SetParticleControl( effect_cast, 1, Vector( lines, 0, 0 ) )
	ParticleManager:SetParticleControlForward( effect_cast, 2, caster:GetForwardVector() )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn("Hero_Nevermore.RequiemOfSouls", caster)
end

function ability_requiem:Implode( lines, modifier )
	self.damage_pct = self:GetSpecialValueFor("requiem_damage_pct_scepter")
	self.damage_heal_pct = self:GetSpecialValueFor("requiem_heal_pct_scepter")

	local modifierAT = self:AddATValue( modifier )
	modifier.identifier = modifierAT

	local particle_line = "particles/units/heroes/hero_lina/lina_spell_dragon_slave.vpcf"
	local line_length = self:GetSpecialValueFor("requiem_radius")
	local width_start = self:GetSpecialValueFor("requiem_line_width_end")
	local width_end = self:GetSpecialValueFor("requiem_line_width_start")
	local line_speed = self:GetSpecialValueFor("requiem_line_speed")

	local initial_angle_deg = self:GetCaster():GetAnglesAsVector().y
	local delta_angle = 360/lines
	for i=0,lines-1 do
		local facing_angle_deg = initial_angle_deg + delta_angle * i
		if facing_angle_deg>360 then facing_angle_deg = facing_angle_deg - 360 end
		local facing_angle = math.rad(facing_angle_deg)
		local facing_vector = Vector( math.cos(facing_angle), math.sin(facing_angle), 0 ):Normalized()
		local velocity = facing_vector * line_speed

		local info = {
			Source = self:GetCaster(),
			Ability = self,
			EffectName = particle_line,
			vSpawnOrigin = self:GetCaster():GetAbsOrigin() + facing_vector * line_length,
			fDistance = line_length,
			vVelocity = -velocity,
			fStartRadius = width_start,
			fEndRadius = width_end,
			iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_SPELL_IMMUNE_ENEMIES,
			iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			bReplaceExisting = false,
			bProvidesVision = false,
			ExtraData = {
				scepter = true,
				modifier = modifierAT,
			}
		}
		ProjectileManager:CreateLinearProjectile( info )
	end
end

function ability_requiem:GetAT()
	if self.abilityTable==nil then
		self.abilityTable = {}
	end
	return self.abilityTable
end

function ability_requiem:GetATEmptyKey()
	local table = self:GetAT()
	local i = 1
	while table[i]~=nil do
		i = i+1
	end
	return i
end

function ability_requiem:AddATValue( value )
	local table = self:GetAT()
	local i = self:GetATEmptyKey()
	table[i] = value
	return i
end

function ability_requiem:RetATValue( key )
	local table = self:GetAT()
	local ret = table[key]
	return ret
end

function ability_requiem:DelATValue( key )
	local table = self:GetAT()
	local ret = table[key]
	table[key] = nil
end

modifier_ability_requiem = {}

function modifier_ability_requiem:IsDebuff()
	return true
end

modifier_ability_requiem_scepter = {}

function modifier_ability_requiem_scepter:IsHidden()
	return false
end

function modifier_ability_requiem_scepter:IsPurgable()
	return false
end

function modifier_ability_requiem_scepter:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_ability_requiem_scepter:OnCreated( kv )
	self.lines = kv.lineNumber
	self.duration = kv.lineDuration

	self.heal = 0

	if IsServer() then
		self:StartIntervalThink( self.duration )
	end
end

function modifier_ability_requiem_scepter:OnRefresh( kv )
end

function modifier_ability_requiem_scepter:OnDestroy()
	if IsServer() then
		if self.identifier then
			self:GetAbility():DelATValue( self.identifier )
		end
	end
end

function modifier_ability_requiem_scepter:OnIntervalThink()
	if not self.afterImplode then
		self.afterImplode = true

		self:GetAbility():Implode( self.lines, self )

		EmitSoundOn("Hero_Nevermore.RequiemOfSouls", self:GetParent())
	else
		self:GetParent():Heal( self.heal, self:GetAbility() )
		if self.heal > 0 then
			local effect_cast = ParticleManager:CreateParticle(
				"particles/items3_fx/octarine_core_lifesteal.vpcf",
				PATTACH_ABSORIGIN_FOLLOW,
				self:GetParent()
			)
			ParticleManager:ReleaseParticleIndex( effect_cast )
		end

		self:Destroy()
	end
end

function modifier_ability_requiem_scepter:AddTotalHeal( value )
	self.heal = self.heal + value
end