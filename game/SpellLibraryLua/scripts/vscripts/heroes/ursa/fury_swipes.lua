ability_fury_swipes = {}

LinkLuaModifier( "modifier_ability_fury_swipes", "heroes/ursa/fury_swipes", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_fury_swipes_debuff", "heroes/ursa/fury_swipes", LUA_MODIFIER_MOTION_NONE )

function ability_fury_swipes:GetIntrinsicModifierName()
	return "modifier_ability_fury_swipes"
end

modifier_ability_fury_swipes = {}

function modifier_ability_fury_swipes:IsHidden()
	return true
end

function modifier_ability_fury_swipes:IsDebuff()
	return false
end

function modifier_ability_fury_swipes:IsPurgable()
	return false
end

function modifier_ability_fury_swipes:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL,
	}
end

function modifier_ability_fury_swipes:GetModifierProcAttack_BonusDamage_Physical( params )
	if IsServer() then
		local target = params.target if target==nil then target = params.unit end
		if target:GetTeamNumber()==self:GetParent():GetTeamNumber() then
			return 0
		end

		local stack = 0
		local modifier = target:FindModifierByNameAndCaster("modifier_ability_fury_swipes_debuff", self:GetAbility():GetCaster())

		if modifier==nil then
			if not self:GetParent():PassivesDisabled() then
				local duration = self:GetAbility():GetSpecialValueFor("bonus_reset_time")

				if params.target:GetUnitName()=="npc_dota_roshan" then
					duration = self:GetAbility():GetSpecialValueFor("bonus_reset_time_roshan")
				end

				target:AddNewModifier(
					self:GetAbility():GetCaster(),
					self:GetAbility(),
					"modifier_ability_fury_swipes_debuff",
					{ duration = duration }
				)

				stack = 1
			end
		else
			modifier:IncrementStackCount()
			modifier:ForceRefresh()

			stack = modifier:GetStackCount()
		end

		return stack * self:GetAbility():GetSpecialValueFor("damage_per_stack")
	end
end

modifier_ability_fury_swipes_debuff = {}

function modifier_ability_fury_swipes_debuff:IsHidden()
	return false
end

function modifier_ability_fury_swipes_debuff:IsDebuff()
	return true
end

function modifier_ability_fury_swipes_debuff:IsPurgable()
	return false
end

function modifier_ability_fury_swipes_debuff:OnCreated( kv )
	self:SetStackCount(1)
end

function modifier_ability_fury_swipes_debuff:GetEffectName()
	return "particles/units/heroes/hero_ursa/ursa_fury_swipes_debuff.vpcf"
end

function modifier_ability_fury_swipes_debuff:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end