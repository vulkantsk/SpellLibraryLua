LinkLuaModifier("modifier_skywrath_mage_ancient_seal", "heroes/skywrath_mage/ancient_seal.lua", 0)

ability_skywrath_mage_ancient_seal = class({})

function ability_skywrath_mage_ancient_seal:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local duration = self:GetSpecialValueFor("seal_duration")

	if not target:TriggerSpellAbsorb(self) then
		target:AddNewModifier(caster, self, "modifier_skywrath_mage_ancient_seal", {duration = duration})
		target:EmitSound("Hero_SkywrathMage.AncientSeal.Target")
	end
end

modifier_skywrath_mage_ancient_seal = class({
	IsHidden = function() return false end,
	IsPurgable = function() return true end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
	} end,
	GetModifierMagicalResistanceBonus = function() return self.magic_resist_reduction end,
	CheckState = function() return {
		[MODIFIER_STATE_SILENCED] = true
	} end
})

function modifier_skywrath_mage_ancient_seal:OnCreated()
	self.magic_resist_reduction = self:GetAbility():GetSpecialValueFor("resist_debuff")

	if IsServer() then
		local parent = self:GetParent()
		local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_skywrath_mage/skywrath_mage_ancient_seal_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
		ParticleManager:SetParticleControlEnt(fx, 0, parent, PATTACH_OVERHEAD_FOLLOW, nil, Vector(0, 0, 0), true)
		ParticleManager:SetParticleControlEnt(fx, 1, parent, PATTACH_OVERHEAD_FOLLOW, nil, Vector(0, 0, 0), true)
		self:AddParticle(fx, false, false, -1, false, true)
	end
end