ability_untouchable = {}

LinkLuaModifier( "modifier_ability_untouchable", "heroes/enchantress/untouchable", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_untouchable_debuff", "heroes/enchantress/untouchable", LUA_MODIFIER_MOTION_NONE )

function ability_untouchable:GetIntrinsicModifierName()
	return "modifier_ability_untouchable"
end

modifier_ability_untouchable = {}

function modifier_ability_untouchable:IsHidden()
	return true
end

function modifier_ability_untouchable:IsPurgable()
	return false
end

function modifier_ability_untouchable:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_START,
	}

	return funcs
end

function modifier_ability_untouchable:OnAttackStart( params )
	if IsServer() then
		if params.target~=self:GetParent() then return end
		if params.attacker:IsMagicImmune() then return end
		if self:GetParent():PassivesDisabled() then return end

		params.attacker:AddNewModifier(
			self:GetParent(),
			self:GetAbility(),
			"modifier_ability_untouchable_debuff",
			nil
		)
	end
end

modifier_ability_untouchable_debuff = {}

function modifier_ability_untouchable_debuff:IsHidden()
	return false
end

function modifier_ability_untouchable_debuff:IsDebuff()
	return true
end

function modifier_ability_untouchable_debuff:IsStunDebuff()
	return false
end

function modifier_ability_untouchable_debuff:IsPurgable()
	return true
end

function modifier_ability_untouchable_debuff:OnCreated( kv )
	self.slow = self:GetAbility():GetSpecialValueFor( "slow_attack_speed" )
	self.duration = self:GetAbility():GetSpecialValueFor( "slow_duration" )
end

function modifier_ability_untouchable_debuff:OnRefresh( kv )
	self.slow = self:GetAbility():GetSpecialValueFor( "slow_attack_speed" )
	self.duration = self:GetAbility():GetSpecialValueFor( "slow_duration" )
end

function modifier_ability_untouchable_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PRE_ATTACK,
		MODIFIER_EVENT_ON_ATTACK,
		MODIFIER_EVENT_ON_ATTACK_FINISHED,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end

function modifier_ability_untouchable_debuff:GetModifierPreAttack( params )
	if IsServer() then
		if not self.HasAttacked then
			self.record = params.record
		end

		if params.target~=self:GetCaster() then
			self.attackOther = true
		end
	end
end

function modifier_ability_untouchable_debuff:OnAttack( params )
	if IsServer() then
		if params.record~=self.record then return end

		self:SetDuration(self.duration, true)
		self.HasAttacked = true
	end
end

function modifier_ability_untouchable_debuff:OnAttackFinished( params )
	if IsServer() then
		if params.attacker~=self:GetParent() then return end
		
		if not self.HasAttacked then
			self:Destroy()
		end

		if self.attackOther then
			self:Destroy()
		end
	end
end

function modifier_ability_untouchable_debuff:GetModifierAttackSpeedBonus_Constant()
	if IsServer() then
		if self:GetParent():GetAggroTarget()==self:GetCaster() then
			return self.slow
		else
			return 0
		end
	end

	return self.slow
end

function modifier_ability_untouchable_debuff:GetEffectName()
	return "particles/units/heroes/hero_enchantress/enchantress_untouchable.vpcf"
end

function modifier_ability_untouchable_debuff:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end