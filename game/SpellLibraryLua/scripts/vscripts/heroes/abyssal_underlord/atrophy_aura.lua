ability_atrophy_aura = {}

LinkLuaModifier( "modifier_ability_atrophy_aura", "heroes/abyssal_underlord/atrophy_aura", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_atrophy_aura_debuff", "heroes/abyssal_underlord/atrophy_aura", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_atrophy_aura_stack", "heroes/abyssal_underlord/atrophy_aura", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_atrophy_aura_permanent_stack", "heroes/abyssal_underlord/atrophy_aura", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_atrophy_aura_scepter", "heroes/abyssal_underlord/atrophy_aura", LUA_MODIFIER_MOTION_NONE )

function ability_atrophy_aura:GetIntrinsicModifierName()
	return "modifier_ability_atrophy_aura"
end

modifier_ability_atrophy_aura_stack = class({})

function modifier_ability_atrophy_aura_stack:IsHidden()
	return true
end

function modifier_ability_atrophy_aura_stack:IsDebuff()
	return false
end

function modifier_ability_atrophy_aura_stack:IsPurgable()
	return false
end

function modifier_ability_atrophy_aura_stack:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE 
end

function modifier_ability_atrophy_aura_stack:RemoveOnDeath()
	return false
end

function modifier_ability_atrophy_aura_stack:OnDestroy()
	if not IsServer() then return end
	self.parent:RemoveStack( self.bonus )
end

modifier_ability_atrophy_aura_scepter = {}

function modifier_ability_atrophy_aura_scepter:IsHidden()
	return self:GetStackCount()==0
end

function modifier_ability_atrophy_aura_scepter:IsDebuff()
	return false
end

function modifier_ability_atrophy_aura_scepter:IsStunDebuff()
	return false
end

function modifier_ability_atrophy_aura_scepter:IsPurgable()
	return false
end

function modifier_ability_atrophy_aura_scepter:RemoveOnDeath()
	return false
end

function modifier_ability_atrophy_aura_scepter:OnCreated( kv )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
	self.bonus_pct = 50

	if not IsServer() then return end

	self.modifier = self:GetCaster():FindModifierByNameAndCaster( "modifier_ability_atrophy_aura", self:GetCaster() )
end

function modifier_ability_atrophy_aura_scepter:OnRefresh( kv )
	self:OnCreated( kv )
end

function modifier_ability_atrophy_aura_scepter:OnRemoved()
end

function modifier_ability_atrophy_aura_scepter:OnDestroy()
end

function modifier_ability_atrophy_aura_scepter:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}

	return funcs
end

function modifier_ability_atrophy_aura_scepter:GetModifierPreAttack_BonusDamage()
	if self:GetParent()==self:GetCaster() then return 0 end

	if IsServer() then
		local bonus = self.modifier:GetStackCount()
		bonus = math.floor( bonus*self.bonus_pct/100 )

		self:SetStackCount( bonus )
	end

	return self:GetStackCount()
end

function modifier_ability_atrophy_aura_scepter:IsAura()
	local caster = self:GetCaster()

	if not caster:HasScepter() then return false end

	return self:GetParent() == caster
end

function modifier_ability_atrophy_aura_scepter:GetModifierAura()
	return "modifier_ability_atrophy_aura_scepter"
end

function modifier_ability_atrophy_aura_scepter:GetAuraRadius()
	return self.radius
end

function modifier_ability_atrophy_aura_scepter:GetAuraDuration()
	return 0.5
end

function modifier_ability_atrophy_aura_scepter:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_ability_atrophy_aura_scepter:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO
end

function modifier_ability_atrophy_aura_scepter:GetAuraSearchFlags()
	return 0
end

function modifier_ability_atrophy_aura_scepter:IsAuraActiveOnDeath()
	return false
end

function modifier_ability_atrophy_aura_scepter:GetAuraEntityReject( hEntity )
	return false
end

modifier_ability_atrophy_aura_permanent_stack = {}

function modifier_ability_atrophy_aura_permanent_stack:IsHidden()
	return false
end

function modifier_ability_atrophy_aura_permanent_stack:IsDebuff()
	return false
end

function modifier_ability_atrophy_aura_permanent_stack:IsPurgable()
	return false
end

function modifier_ability_atrophy_aura_permanent_stack:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_ability_atrophy_aura_permanent_stack:RemoveOnDeath()
	return false
end

function modifier_ability_atrophy_aura_permanent_stack:OnCreated( kv )
	if not IsServer() then return end
	self:SetStackCount( kv.bonus )
end

function modifier_ability_atrophy_aura_permanent_stack:OnRefresh( kv )
	if not IsServer() then return end
	self:SetStackCount( self:GetStackCount() + kv.bonus )
end

function modifier_ability_atrophy_aura_permanent_stack:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}

	return funcs
end

function modifier_ability_atrophy_aura_permanent_stack:GetModifierPreAttack_BonusDamage()
	return self:GetStackCount()
end

modifier_ability_atrophy_aura_debuff = {}

function modifier_ability_atrophy_aura_debuff:IsHidden()
	return false
end

function modifier_ability_atrophy_aura_debuff:IsDebuff()
	return true
end

function modifier_ability_atrophy_aura_debuff:IsStunDebuff()
	return false
end

function modifier_ability_atrophy_aura_debuff:IsPurgable()
	return true
end

function modifier_ability_atrophy_aura_debuff:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE 
end

function modifier_ability_atrophy_aura_debuff:OnCreated( kv )
	self.reduction = self:GetAbility():GetSpecialValueFor( "damage_reduction_pct" )
end

function modifier_ability_atrophy_aura_debuff:OnRefresh( kv )
	self.reduction = self:GetAbility():GetSpecialValueFor( "damage_reduction_pct" )	
end

function modifier_ability_atrophy_aura_debuff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
	}

	return funcs
end

function modifier_ability_atrophy_aura_debuff:GetModifierBaseDamageOutgoing_Percentage( params )
	return -self.reduction
end

modifier_ability_atrophy_aura = {}

function modifier_ability_atrophy_aura:IsHidden()
	return self:GetStackCount()==0
end

function modifier_ability_atrophy_aura:IsDebuff()
	return false
end

function modifier_ability_atrophy_aura:IsStunDebuff()
	return false
end

function modifier_ability_atrophy_aura:IsPurgable()
	return false
end

function modifier_ability_atrophy_aura:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_ability_atrophy_aura:RemoveOnDeath()
	return false
end

function modifier_ability_atrophy_aura:DestroyOnExpire()
	return false
end

function modifier_ability_atrophy_aura:OnCreated( kv )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
	self.hero_bonus = self:GetAbility():GetSpecialValueFor( "bonus_damage_from_hero" )
	self.creep_bonus = self:GetAbility():GetSpecialValueFor( "bonus_damage_from_creep" )
	self.bonus = self:GetAbility():GetSpecialValueFor( "permanent_bonus" )
	self.duration = self:GetAbility():GetSpecialValueFor( "bonus_damage_duration" )
	self.duration_scepter = self:GetAbility():GetSpecialValueFor( "bonus_damage_duration_scepter" )

	if not IsServer() then return end

	self.scepter_aura = self:GetParent():AddNewModifier(
		self:GetParent(),
		self:GetAbility(),
		"modifier_ability_atrophy_aura_scepter",
		{}
	)
end

function modifier_ability_atrophy_aura:OnRefresh( kv )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
	self.hero_bonus = self:GetAbility():GetSpecialValueFor( "bonus_damage_from_hero" )
	self.creep_bonus = self:GetAbility():GetSpecialValueFor( "bonus_damage_from_creep" )
	self.bonus = self:GetAbility():GetSpecialValueFor( "permanent_bonus" )
	self.duration = self:GetAbility():GetSpecialValueFor( "bonus_damage_duration" )
	self.duration_scepter = self:GetAbility():GetSpecialValueFor( "bonus_damage_duration_scepter" )

	if not IsServer() then return end

	self.scepter_aura:ForceRefresh()
end

function modifier_ability_atrophy_aura:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_DEATH,
		
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}

	return funcs
end

function modifier_ability_atrophy_aura:OnDeath( params )
	if not IsServer() then return end
	local parent = self:GetParent()

	if parent:PassivesDisabled() then return end

	if params.unit:IsIllusion() then return end

	if not params.unit:FindModifierByNameAndCaster( "modifier_ability_atrophy_aura_debuff", parent ) then return end

	local hero = params.unit:IsHero()
	local bonus
	if hero then
		bonus = self.hero_bonus
	else
		bonus = self.creep_bonus
	end

	local duration
	if parent:HasScepter() then
		duration = self.duration_scepter
	else
		duration = self.duration
	end

	self:SetStackCount( self:GetStackCount() + bonus )

	local modifier = parent:AddNewModifier(
		parent,
		self:GetAbility(),
		"modifier_ability_atrophy_aura_stack",
		{ duration = duration }
	)
	modifier.parent = self
	modifier.bonus = bonus

	self:SetDuration( self.duration, true )

	if hero then
		parent:AddNewModifier(
			parent,
			self:GetAbility(),
			"modifier_ability_atrophy_aura_permanent_stack",
			{ bonus = self.bonus }
		)
	end
end

function modifier_ability_atrophy_aura:GetModifierPreAttack_BonusDamage()
	return self:GetStackCount()
end

function modifier_ability_atrophy_aura:RemoveStack( value )
	self:SetStackCount( self:GetStackCount() - value )
end

function modifier_ability_atrophy_aura:IsAura()
	return (not self:GetCaster():PassivesDisabled())
end

function modifier_ability_atrophy_aura:GetModifierAura()
	return "modifier_ability_atrophy_aura_debuff"
end

function modifier_ability_atrophy_aura:GetAuraRadius()
	return self.radius
end

function modifier_ability_atrophy_aura:GetAuraDuration()
	return 0.5
end

function modifier_ability_atrophy_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_ability_atrophy_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_ability_atrophy_aura:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_ability_atrophy_aura:IsAuraActiveOnDeath()
	return false
end

function modifier_ability_atrophy_aura:GetAuraEntityReject( hEntity )
	if IsServer() then
		if hEntity==self:GetCaster() then return true end
	end

	return false
end