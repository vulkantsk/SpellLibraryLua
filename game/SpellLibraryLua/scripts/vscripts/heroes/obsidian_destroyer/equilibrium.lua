LinkLuaModifier( "modifier_ability_equilibrium", "heroes/obsidian_destroyer/astral_imprisonment", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_equilibrium_buff", "heroes/obsidian_destroyer/astral_imprisonment", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_equilibrium_debuff", "heroes/obsidian_destroyer/astral_imprisonment", LUA_MODIFIER_MOTION_NONE )

ability_equilibrium = {}

function ability_equilibrium:GetIntrinsicModifierName()
	return "modifier_ability_equilibrium"
end

function ability_equilibrium:OnSpellStart()
	print( "qasd" )
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor( "duration" )

	print( "wtf" )

	caster:AddNewModifier(
		caster,
		self,
		"modifier_ability_equilibrium_buff",
		{ duration = duration }
	)

	EmitSoundOn( "Hero_ObsidianDestroyer.Equilibrium.Cast", caster )
	print( "eshkere" )
end

modifier_ability_equilibrium = {}

function modifier_ability_equilibrium:IsHidden()
	return true
end

function modifier_ability_equilibrium:IsDebuff()
	return false
end

function modifier_ability_equilibrium:IsStunDebuff()
	return false
end

function modifier_ability_equilibrium:IsPurgable()
	return false
end

function modifier_ability_equilibrium:OnCreated( kv )
	self.parent = self:GetParent()
	self.mana_steal = self:GetAbility():GetSpecialValueFor( "mana_steal" )
	self.mana_steal_active = self:GetAbility():GetSpecialValueFor( "mana_steal_active" )
	self.slow_duration = self:GetAbility():GetSpecialValueFor( "slow_duration" )
end

modifier_ability_equilibrium.OnRefresh = modifier_ability_equilibrium.OnCreated

function modifier_ability_equilibrium:DeclareFunctions()
	return { MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_ability_equilibrium:OnTakeDamage( params )
	if not IsServer() then return end
	if params.attacker~=self.parent then return end

	local active = self.parent:HasModifier( "modifier_ability_equilibrium_buff" )
	if active then
		local mana = params.damage * self.mana_steal_active/100
		self.parent:GiveMana( mana )

		params.unit:AddNewModifier(
			self.parent,
			self:GetAbility(),
			"modifier_ability_equilibrium_debuff",
			{ duration = self.slow_duration }
		)

		local effect_cast = ParticleManager:CreateParticle(
			"particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_matter_debuff.vpcf",
			PATTACH_ABSORIGIN_FOLLOW,
			self:GetParent()
		)
		ParticleManager:SetParticleControlEnt(
			effect_cast,
			0,
			params.unit,
			PATTACH_POINT_FOLLOW,
			"attach_hitloc",
			Vector(),
			true
		)
		ParticleManager:SetParticleControlEnt(
			effect_cast,
			1,
			self.parent,
			PATTACH_POINT_FOLLOW,
			"attach_hitloc",
			Vector(),
			true
		)
		ParticleManager:SetParticleControl( effect_cast, 2, params.unit:GetAbsOrigin() )
		ParticleManager:ReleaseParticleIndex( effect_cast )

		EmitSoundOn( "Hero_ObsidianDestroyer.Equilibrium.Damage", params.unit )

		local effect_cast = ParticleManager:CreateParticle(
			"particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_essence_effect.vpcf",
			PATTACH_ABSORIGIN_FOLLOW,
			self.parent
		)
		ParticleManager:ReleaseParticleIndex( effect_cast )
	else
		local mana = params.damage * self.mana_steal/100
		self.parent:GiveMana( mana )

		local effect_cast = ParticleManager:CreateParticle(
			"particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_matter_manasteal.vpcf",
			PATTACH_ABSORIGIN_FOLLOW,
			params.unit
		)
		ParticleManager:ReleaseParticleIndex( effect_cast )
	end
end

modifier_ability_equilibrium_buff = {}

function modifier_ability_equilibrium_buff:IsHidden()
	return false
end

function modifier_ability_equilibrium_buff:IsDebuff()
	return false
end

function modifier_ability_equilibrium_buff:IsPurgable()
	return true
end

function modifier_ability_equilibrium_buff:GetEffectName()
	return "particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_matter_buff.vpcf"
end

function modifier_ability_equilibrium_buff:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_ability_equilibrium_buff:GetStatusEffectName()
	return "particles/status_fx/status_effect_obsidian_matter.vpcf"
end

modifier_ability_equilibrium_debuff = {}

function modifier_ability_equilibrium_debuff:IsHidden()
	return false
end

function modifier_ability_equilibrium_debuff:IsDebuff()
	return true
end

function modifier_ability_equilibrium_debuff:IsStunDebuff()
	return false
end

function modifier_ability_equilibrium_debuff:IsPurgable()
	return true
end

function modifier_ability_equilibrium_debuff:OnCreated( kv )
	self.slow = self:GetAbility():GetSpecialValueFor( "movement_slow" )
end

modifier_ability_equilibrium_debuff.OnRefresh = modifier_ability_equilibrium_debuff.OnCreated

function modifier_ability_equilibrium_debuff:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_ability_equilibrium_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end

function modifier_ability_equilibrium_debuff:GetStatusEffectName()
	return "particles/status_fx/status_effect_obsidian_matter_debuff.vpcf"
end