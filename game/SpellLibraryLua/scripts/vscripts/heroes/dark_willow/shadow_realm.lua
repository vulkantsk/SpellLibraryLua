ability_shadow_realm = class({})

LinkLuaModifier( "modifier_ability_shadow_realm", "heroes/dark_willow/shadow_realm", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_shadow_realm_buff", "heroes/dark_willow/shadow_realm", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Ability Start
function ability_shadow_realm:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()

	-- load data
	local duration = self:GetSpecialValueFor( "duration" )

	-- add modifier
	caster:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_ability_shadow_realm", -- modifier name
		{ duration = duration } -- kv
	)
end


modifier_ability_shadow_realm = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_ability_shadow_realm:IsHidden()
	return false
end

function modifier_ability_shadow_realm:IsDebuff()
	return false
end

function modifier_ability_shadow_realm:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_ability_shadow_realm:OnCreated( kv )
	-- references
	self.bonus_range = self:GetAbility():GetSpecialValueFor( "attack_range_bonus" )
	self.bonus_damage = self:GetAbility():GetSpecialValueFor( "damage" )
	self.bonus_max = self:GetAbility():GetSpecialValueFor( "max_damage_duration" )
	self.buff_duration = self:GetDuration()

	if not IsServer() then return end
	-- set creation time
	self.create_time = GameRules:GetGameTime()

	-- dodge projectiles
	ProjectileManager:ProjectileDodge( self:GetParent() )

	-- stop if currently attacking
	if self:GetParent():GetAggroTarget() then

		-- unit:Stop() is not enough to stop
		local order = {
			UnitIndex = self:GetParent():entindex(),
			OrderType = DOTA_UNIT_ORDER_STOP,
		}
		ExecuteOrderFromTable( order )
	end

	self:PlayEffects()
end

function modifier_ability_shadow_realm:OnRefresh( kv )
	-- references
	self.bonus_range = self:GetAbility():GetSpecialValueFor( "attack_range_bonus" )
	self.bonus_damage = self:GetAbility():GetSpecialValueFor( "damage" )
	self.bonus_max = self:GetAbility():GetSpecialValueFor( "max_damage_duration" )
	self.buff_duration = self:GetDuration()

	if not IsServer() then return end
	-- dodge projectiles
	ProjectileManager:ProjectileDodge( self:GetParent() )
end

function modifier_ability_shadow_realm:OnDestroy()
	-- stop sound
	StopSoundOn( "Hero_DarkWillow.Shadow_Realm", self:GetParent() )
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_ability_shadow_realm:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		MODIFIER_PROPERTY_PROJECTILE_NAME,

		MODIFIER_EVENT_ON_ATTACK,
	}

	return funcs
end

function modifier_ability_shadow_realm:GetModifierAttackRangeBonus()
	return self.bonus_range
end
function modifier_ability_shadow_realm:GetModifierProjectileName()
	return "particles/units/heroes/hero_dark_willow/dark_willow_shadow_attack_dummy.vpcf"
end

function modifier_ability_shadow_realm:OnAttack( params )
	if not IsServer() then return end
	if params.attacker~=self:GetParent() then return end

	-- calculate time
	local time = GameRules:GetGameTime() - self.create_time
	time = math.min( time/self.bonus_max, 1 )

	-- create modifier
	self:GetParent():AddNewModifier(
		self:GetCaster(), -- player source
		self:GetAbility(), -- ability source
		"modifier_ability_shadow_realm_buff", -- modifier name
		{
			duration = self.buff_duration,
			record = params.record,
			damage = self.bonus_damage,
			time = time,
			target = params.target:entindex(),
		} -- kv
	)


    self:Destroy()

	-- play sound
	EmitSoundOn( "Hero_DarkWillow.Shadow_Realm.Attack", self:GetParent() )

end
--------------------------------------------------------------------------------
-- Status Effects
function modifier_ability_shadow_realm:CheckState()
	local state = {
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_UNTARGETABLE] = true,
		-- [MODIFIER_STATE_UNSELECTABLE] = true,
	}

	return state
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_ability_shadow_realm:GetStatusEffectName()
	return "particles/status_fx/status_effect_dark_willow_shadow_realm.vpcf"
end

function modifier_ability_shadow_realm:PlayEffects()
	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_dark_willow/dark_willow_shadow_realm.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		1,
		self:GetParent(),
		PATTACH_ABSORIGIN_FOLLOW,
		"attach_hitloc",
		Vector(0,0,0), -- unknown
		true -- unknown, true
	)

	-- buff particle
	self:AddParticle(
		effect_cast,
		false, -- bDestroyImmediately
		false, -- bStatusEffect
		-1, -- iPriority
		false, -- bHeroEffect
		false -- bOverheadEffect
	)

	-- Create Sound
	EmitSoundOn( "Hero_DarkWillow.Shadow_Realm", self:GetParent() )
end

modifier_ability_shadow_realm_buff = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_ability_shadow_realm_buff:IsHidden()
	return true
end

function modifier_ability_shadow_realm_buff:IsDebuff()
	return false
end

function modifier_ability_shadow_realm_buff:IsPurgable()
	return false
end

function modifier_ability_shadow_realm_buff:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_ability_shadow_realm_buff:OnCreated( kv )
	if not IsServer() then return end

	-- references
	self.damage = kv.damage
	self.record = kv.record
	self.time = kv.time
	self.target = EntIndexToHScript( kv.target )

	self.target_pos = self.target:GetOrigin()
	self.target_prev = self.target_pos

	-- create custom projectile
	self:PlayEffects()
end

function modifier_ability_shadow_realm_buff:OnRefresh( kv )
	
end

function modifier_ability_shadow_realm_buff:OnRemoved()
end

function modifier_ability_shadow_realm_buff:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_ability_shadow_realm_buff:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY,
		MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_MAGICAL,

		MODIFIER_EVENT_ON_PROJECTILE_DODGE,
		MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE, -- this does nothing but tracking target's movement, for projectile dodge purposes
	}

	return funcs
end

function modifier_ability_shadow_realm_buff:OnAttackRecordDestroy( params )
	if not IsServer() then return end
	if params.record~=self.record then return end

	-- destroy buff if attack finished (proc/miss/whatever)
	self:StopEffects( false )
	self:Destroy()
end
function modifier_ability_shadow_realm_buff:GetModifierProcAttack_BonusDamage_Magical( params )
	if params.record~=self.record then return end

	-- overhead event
	SendOverheadEventMessage(
		nil, --DOTAPlayer sendToPlayer,
		OVERHEAD_ALERT_BONUS_SPELL_DAMAGE,
		params.target,
		self.damage * self.time,
		self:GetParent():GetPlayerOwner() -- DOTAPlayer sourcePlayer
	)

	-- play effects
	local sound_cast = "Hero_DarkWillow.Shadow_Realm.Damage"
	EmitSoundOn( sound_cast, self:GetParent() )

	return self.damage * self.time
end

function modifier_ability_shadow_realm_buff:OnProjectileDodge( params )
	if not IsServer() then return end
	if params.target~=self.target then return end

	-- set target CP to last known location
	ParticleManager:SetParticleControlEnt(
		self.effect_cast,
		1,
		self.target,
		PATTACH_CUSTOMORIGIN,
		"attach_hitloc",
		self.target_prev, -- unknown
		true -- unknown, true
	)
end
function modifier_ability_shadow_realm_buff:GetModifierBaseAttack_BonusDamage()
	if not IsServer() then return end

	-- track target's position each frame
	self.target_prev = self.target_pos
	self.target_pos = self.target:GetOrigin()

	-- the property actually does nothing
	return 0
end

--------------------------------------------------------------------------------
-- Graphics and Animations
function modifier_ability_shadow_realm_buff:PlayEffects()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_dark_willow/dark_willow_shadow_attack.vpcf"

	-- Get data
	local speed = self:GetParent():GetProjectileSpeed()

	-- Create Particle
	self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:SetParticleControlEnt(
		self.effect_cast,
		0,
		self:GetParent(),
		PATTACH_POINT_FOLLOW,
		"attach_attack1",
		Vector(0,0,0), -- unknown
		true -- unknown, true
	)
	ParticleManager:SetParticleControlEnt(
		self.effect_cast,
		1,
		self.target,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(0,0,0), -- unknown
		true -- unknown, true
	)
	ParticleManager:SetParticleControl( self.effect_cast, 2, Vector( speed, 0, 0 ) )
	ParticleManager:SetParticleControl( self.effect_cast, 5, Vector( self.time, 0, 0 ) )
end

function modifier_ability_shadow_realm_buff:StopEffects( dodge )
	-- destroy effects
	ParticleManager:DestroyParticle( self.effect_cast, dodge )
	ParticleManager:ReleaseParticleIndex( self.effect_cast )
end