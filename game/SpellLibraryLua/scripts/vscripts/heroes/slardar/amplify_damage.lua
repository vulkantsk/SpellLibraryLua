LinkLuaModifier("modifier_ability_slardar_amplify_damage_debuff", "heroes/slardar/amplify_damage.lua", 0)

ability_slardar_amplify_damage = class({})

function ability_slardar_amplify_damage:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local duration = self:GetSpecialValueFor("duration")

	if not target:TriggerSpellAbsorb(self) then
		target:AddNewModifier(caster, self, "modifier_ability_slardar_amplify_damage_debuff", {duration = duration})
	end

	caster:EmitSound("Hero_Slardar.Amplify_Damage")
end

modifier_ability_slardar_amplify_damage_debuff = class({
	IsPurgable = function() return true end,
	IsDebuff = function() return true end,
	IsStunDebuff = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_PROVIDES_FOW_POSITION
	} end,
	GetModifierProvidesFOWVision = function() return 1 end,
	CheckState = function() return {
		[MODIFIER_STATE_INVISIBLE] = false
	} end
})

function modifier_ability_slardar_amplify_damage_debuff:OnCreated()
	local parent = self:GetParent()
	self.armor_reduction = self:GetAbility():GetSpecialValueFor("armor_reduction")

	if IsServer() then
		local particle = "particles/units/heroes/hero_slardar/slardar_amp_damage.vpcf"
		local fx = ParticleManager:CreateParticle(particle, PATTACH_OVERHEAD_FOLLOW, parent)

		ParticleManager:SetParticleControlEnt(fx, 0, parent, PATTACH_OVERHEAD_FOLLOW, nil, parent:GetOrigin(), true)
		ParticleManager:SetParticleControlEnt( fx, 1, parent, PATTACH_OVERHEAD_FOLLOW, nil, parent:GetOrigin(), true)
		ParticleManager:SetParticleControlEnt( fx, 2, parent, PATTACH_OVERHEAD_FOLLOW, nil, parent:GetOrigin(), true)
		self:AddParticle(fx, false, false, -1, false, true)
	end
end

function modifier_ability_slardar_amplify_damage_debuff:GetModifierPhysicalArmorBonus()
	return self.armor_reduction
end