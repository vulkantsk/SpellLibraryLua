ability_overpower = {}

LinkLuaModifier( "modifier_ability_overpower", "heroes/ursa/overpower", LUA_MODIFIER_MOTION_NONE )

function ability_overpower:OnSpellStart()
	local bonus_duration = self:GetDuration()

	self:GetCaster():AddNewModifier(
		self:GetCaster(),
		self,
		"modifier_ability_overpower",
		{ duration = self:GetDuration() }
	)

	EmitSoundOn("Hero_Ursa.Overpower", self:GetCaster())
end

modifier_ability_overpower = {}

function modifier_ability_overpower:IsDebuff()
	return false
end

function modifier_ability_overpower:OnCreated( kv )
	self.bonus = self:GetAbility():GetSpecialValueFor("attack_speed_bonus")
	self.max_attacks = self:GetAbility():GetSpecialValueFor("max_attacks")

	if IsServer() then
		self:SetStackCount(self.max_attacks)

		self:AddEffects()
	end
end

function modifier_ability_overpower:OnRefresh( kv )
	self.bonus = self:GetAbility():GetSpecialValueFor("attack_speed_bonus")
	self.max_attacks = self:GetAbility():GetSpecialValueFor("max_attacks")

	if IsServer() then
		self:SetStackCount(self.max_attacks)
	end
end

function modifier_ability_overpower:OnDestroy( kv )
	if IsServer() then
		self:RemoveEffects()
	end
end

function modifier_ability_overpower:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
	}
end

function modifier_ability_overpower:GetModifierAttackSpeedBonus_Constant()
	return self.bonus
end

function modifier_ability_overpower:GetModifierProcAttack_Feedback( params )
	if IsServer() then
		self:DecrementStackCount()

		if self:GetStackCount() < 1 then
			self:Destroy()
		end
	end
end

function modifier_ability_overpower:AddEffects()
	local particle_buff = "particles/units/heroes/hero_ursa/ursa_overpower_buff.vpcf"

	self.effect_cast = ParticleManager:CreateParticle( particle_buff, PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControlEnt( self.effect_cast, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_head", self:GetParent():GetOrigin(), true)
	ParticleManager:SetParticleControlEnt( self.effect_cast, 3, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetOrigin(), true)

	self:AddParticle(
		self.effect_cast,
		false,
		false,
		-1,
		false,
		false
	)
end

function modifier_ability_overpower:RemoveEffects()
	ParticleManager:DestroyParticle( self.effect_cast, false )
	ParticleManager:ReleaseParticleIndex( self.effect_cast )
end