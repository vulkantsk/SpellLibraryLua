LinkLuaModifier( "modifier_ability_essence_shift", "heroes/slark/essence_shift", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_essence_shift_debuff", "heroes/slark/essence_shift", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_essence_shift_stack", "heroes/slark/essence_shift", LUA_MODIFIER_MOTION_NONE )

ability_essence_shift = {}

function ability_essence_shift:GetIntrinsicModifierName()
	return "modifier_ability_essence_shift"
end

modifier_ability_essence_shift = {}

function modifier_ability_essence_shift:IsHidden()
	return false
end

function modifier_ability_essence_shift:IsDebuff()
	return false
end

function modifier_ability_essence_shift:IsPurgable()
	return false
end

function modifier_ability_essence_shift:OnCreated( kv )
	self.agi_gain = self:GetAbility():GetSpecialValueFor( "agi_gain" )
	self.duration = self:GetAbility():GetSpecialValueFor( "duration" )
end

modifier_ability_essence_shift.OnRefresh = modifier_ability_essence_shift.OnCreated

function modifier_ability_essence_shift:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
	}
end

function modifier_ability_essence_shift:GetModifierProcAttack_Feedback( params )
	if IsServer() and not self:GetParent():PassivesDisabled() then
		local target = params.target

		if not target:IsHero() or target:IsIllusion() then
			return
		end

		local debuff = params.target:AddNewModifier(
			self:GetParent(),
			self:GetAbility(),
			"modifier_ability_essence_shift_debuff",
			{
				stack_duration = self.duration,
			}
		)

		self:AddStack( duration )

		self:PlayEffects( params.target )
	end
end

function modifier_ability_essence_shift:GetModifierBonusStats_Agility()
	return self:GetStackCount() * self.agi_gain
end

function modifier_ability_essence_shift:AddStack( duration )
	local mod = self:GetParent():AddNewModifier(
		self:GetParent(),
		self:GetAbility(),
		"modifier_ability_essence_shift_stack",
		{
			duration = self.duration,
		}
	)
	mod.modifier = self

	self:IncrementStackCount()
end

function modifier_ability_essence_shift:RemoveStack()
	self:DecrementStackCount()
end

function modifier_ability_essence_shift:PlayEffects( target )
	local particle_cast = "particles/units/heroes/hero_slark/slark_essence_shift.vpcf"

	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
	ParticleManager:SetParticleControl( effect_cast, 1, self:GetParent():GetOrigin() + Vector( 0, 0, 64 ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )
end

modifier_ability_essence_shift_debuff = {}

function modifier_ability_essence_shift_debuff:IsHidden()
	return false
end

function modifier_ability_essence_shift_debuff:IsDebuff()
	return true
end

function modifier_ability_essence_shift_debuff:IsPurgable()
	return false
end

function modifier_ability_essence_shift_debuff:OnCreated( kv )
	self.stat_loss = self:GetAbility():GetSpecialValueFor( "stat_loss" )
	self.duration = kv.stack_duration

	if IsServer() then
		self:AddStack( self.duration )
	end
end

function modifier_ability_essence_shift_debuff:OnRefresh( kv )
	self.stat_loss = self:GetAbility():GetSpecialValueFor( "stat_loss" )
	self.duration = kv.stack_duration

	if IsServer() then
		self:AddStack( self.duration )
	end
end

function modifier_ability_essence_shift_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}
end

function modifier_ability_essence_shift_debuff:GetModifierBonusStats_Strength()
	return self:GetStackCount() * -self.stat_loss
end

function modifier_ability_essence_shift_debuff:GetModifierBonusStats_Agility()
	return self:GetStackCount() * -self.stat_loss
end

function modifier_ability_essence_shift_debuff:GetModifierBonusStats_Intellect()
	return self:GetStackCount() * -self.stat_loss
end

function modifier_ability_essence_shift_debuff:AddStack( duration )
	local mod = self:GetParent():AddNewModifier(
		self:GetParent(),
		self:GetAbility(),
		"modifier_ability_essence_shift_stack",
		{
			duration = self.duration,
		}
	)
	mod.modifier = self

	self:IncrementStackCount()
end

function modifier_ability_essence_shift_debuff:RemoveStack()
	self:DecrementStackCount()

	if self:GetStackCount()<=0 then
		self:Destroy()
	end
end

modifier_ability_essence_shift_stack = {}

function modifier_ability_essence_shift_stack:IsHidden()
	return true
end

function modifier_ability_essence_shift_stack:IsPurgable()
	return false
end
function modifier_ability_essence_shift_stack:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_ability_essence_shift_stack:OnCreated( kv )
end

function modifier_ability_essence_shift_stack:OnRemoved()
	if IsServer() then
		self.modifier:RemoveStack()
	end
end