ability_enchant = {}

LinkLuaModifier( "modifier_ability_enchant", "heroes/enchantress/enchant", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_enchant_slow", "heroes/enchantress/enchant", LUA_MODIFIER_MOTION_NONE )

function ability_enchant:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if target:IsRealHero() then
		local duration = self:GetDuration()

		target:AddNewModifier(
			caster,
			self,
			"modifier_ability_enchant_slow",
			{ duration = duration }
		)

		target:Purge( true, false, false, false, false )

		EmitSoundOn( "Hero_Enchantress.EnchantHero", target )
	else
		target:AddNewModifier(
			caster,
			self,
			"modifier_ability_enchant",
			{} 
		)
		target:AddNewModifier(
			caster,
			self,
			"modifier_kill",
			{ duration = self:GetSpecialValueFor( "dominate_duration" ) }
		)

		target:Purge( false, true, false, false, false )

		EmitSoundOn( "Hero_Enchantress.EnchantCreep", target )
	end

	EmitSoundOn( "Hero_Enchantress.EnchantCast", caster )
end

modifier_ability_enchant = class({})

function modifier_ability_enchant:IsHidden()
	return false
end

function modifier_ability_enchant:IsDebuff()
	return false
end

function modifier_ability_enchant:IsPurgable()
	return false
end

function modifier_ability_enchant:OnCreated( kv )
	if IsServer() then
		local parent = self:GetParent()
		local caster = self:GetCaster()

		parent:SetTeam( caster:GetTeamNumber() )
		parent:SetOwner( caster )
		parent:SetControllableByPlayer( caster:GetPlayerOwnerID(), true )
	end
end

function modifier_ability_enchant:OnDestroy( kv )
	if IsServer() then
		self:GetParent():ForceKill( false )
	end
end

function modifier_ability_enchant:CheckState()
	return {
		[MODIFIER_STATE_DOMINATED] = true,
	}
end

function modifier_ability_enchant:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_HEALTH_BONUS
	}
end

function modifier_ability_enchant:GetModifierHealthBonus()
	return self:GetAbility():GetSpecialValueFor( "enchant_health" )
end

function modifier_ability_enchant:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor( "enchant_armor" )
end

function modifier_ability_enchant:GetModifierBaseAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor( "enchant_damage" )
end

modifier_ability_enchant_slow = {}

function modifier_ability_enchant_slow:IsHidden()
	return false
end

function modifier_ability_enchant_slow:IsDebuff()
	return true
end

function modifier_ability_enchant_slow:IsPurgable()
	return true
end

function modifier_ability_enchant_slow:OnCreated( kv )
	self.slow = self:GetAbility():GetSpecialValueFor( "slow_movement_speed" )
end

function modifier_ability_enchant_slow:OnRefresh( kv )
	self.slow = self:GetAbility():GetSpecialValueFor( "slow_movement_speed" )
end

function modifier_ability_enchant_slow:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_ability_enchant_slow:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end

function modifier_ability_enchant_slow:GetEffectName()
	return "particles/units/heroes/hero_enchantress/enchantress_enchant_slow.vpcf"
end

function modifier_ability_enchant_slow:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end