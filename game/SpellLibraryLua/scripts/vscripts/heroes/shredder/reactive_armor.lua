ability_reactive_armor = {}

LinkLuaModifier( "modifier_ability_reactive_armor", "heroes/shredder/reactive_armor", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_reactive_armor_stack", "heroes/shredder/reactive_armor", LUA_MODIFIER_MOTION_NONE )

function ability_reactive_armor:GetIntrinsicModifierName()
	return "modifier_ability_reactive_armor"
end

modifier_ability_reactive_armor = {}

function modifier_ability_reactive_armor:IsHidden()
	return self:GetStackCount()==0
end

function modifier_ability_reactive_armor:IsDebuff()
	return false
end

function modifier_ability_reactive_armor:IsStunDebuff()
	return false
end

function modifier_ability_reactive_armor:IsPurgable()
	return false
end

function modifier_ability_reactive_armor:DestroyOnExpire()
	return false
end

function modifier_ability_reactive_armor:OnCreated( kv )
	self.actual_stack = 0

	self.min_stacks_particle_1	= 1
	self.min_stacks_particle_2	= 5
	self.min_stacks_particle_3	= 9
	self.min_stacks_particle_4	= 13

	self.reactive_particle_1 = ParticleManager:CreateParticle("particles/units/heroes/hero_shredder/shredder_armor_lyr1.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControlEnt(self.reactive_particle_1, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_armor", self:GetParent():GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(self.reactive_particle_1, 2, Vector(0, 0, 0))
	ParticleManager:SetParticleControlEnt(self.reactive_particle_1, 4, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_chimmney", self:GetParent():GetAbsOrigin(), true)
	self:AddParticle(self.reactive_particle_1, false, false, -1, false, false)
	
	self.reactive_particle_2 = ParticleManager:CreateParticle("particles/units/heroes/hero_shredder/shredder_armor_lyr2.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControlEnt(self.reactive_particle_2, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_armor", self:GetParent():GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(self.reactive_particle_2, 2, Vector(0, 0, 0))
	ParticleManager:SetParticleControlEnt(self.reactive_particle_2, 4, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_chimmney", self:GetParent():GetAbsOrigin(), true)
	self:AddParticle(self.reactive_particle_2, false, false, -1, false, false)

	self.reactive_particle_3 = ParticleManager:CreateParticle("particles/units/heroes/hero_shredder/shredder_armor_lyr3.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControlEnt(self.reactive_particle_3, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_armor", self:GetParent():GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(self.reactive_particle_3, 2, Vector(0, 0, 0))
	ParticleManager:SetParticleControlEnt(self.reactive_particle_3, 4, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_chimmney", self:GetParent():GetAbsOrigin(), true)
	self:AddParticle(self.reactive_particle_3, false, false, -1, false, false)

	self.reactive_particle_4 = ParticleManager:CreateParticle("particles/units/heroes/hero_shredder/shredder_armor_lyr4.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControlEnt(self.reactive_particle_4, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_armor", self:GetParent():GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(self.reactive_particle_4, 2, Vector(0, 0, 0))
	ParticleManager:SetParticleControlEnt(self.reactive_particle_4, 4, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_chimmney", self:GetParent():GetAbsOrigin(), true)
	self:AddParticle(self.reactive_particle_4, false, false, -1, false, false)
end

function modifier_ability_reactive_armor:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	}
end

function modifier_ability_reactive_armor:OnAttackLanded( params )
	if not IsServer() then return end
	if params.target~=self:GetParent() then return end

	if self:GetParent():PassivesDisabled() then return end

	self.actual_stack = self.actual_stack + 1
	if self:GetStackCount()<self:GetAbility():GetSpecialValueFor( "stack_limit" ) then
		self:IncrementStackCount()
	end

	local duration = self:GetAbility():GetSpecialValueFor( "stack_duration" )

	local modifier = self:GetParent():AddNewModifier(
		self:GetParent(),
		self:GetAbility(),
		"modifier_ability_reactive_armor_stack",
		{ duration = duration}
	)
	modifier.parent = self
	modifier:ParticleSet()
end

function modifier_ability_reactive_armor:GetModifierPhysicalArmorBonus()
	return self:GetStackCount() * self:GetAbility():GetSpecialValueFor( "bonus_armor" )
end
function modifier_ability_reactive_armor:GetModifierConstantHealthRegen()
	return self:GetStackCount() * self:GetAbility():GetSpecialValueFor( "bonus_hp_regen" )
end

function modifier_ability_reactive_armor:RemoveStack()
	self.actual_stack = self.actual_stack - 1
	if self.actual_stack <= self:GetAbility():GetSpecialValueFor( "stack_limit" ) then
		self:SetStackCount( self.actual_stack )
	end
end

modifier_ability_reactive_armor_stack = {}

function modifier_ability_reactive_armor_stack:IsHidden()
	return true
end

function modifier_ability_reactive_armor_stack:IsPurgable()
	return false
end

function modifier_ability_reactive_armor_stack:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_ability_reactive_armor_stack:OnDestroy()
	if not IsServer() then return end
	self.parent:RemoveStack()
	self:ParticleSet()
end

function modifier_ability_reactive_armor_stack:ParticleSet()
	local count = self.parent:GetStackCount()

	if self.parent.min_stacks_particle_1 <= count then
		ParticleManager:SetParticleControl(self.parent.reactive_particle_1, 2, Vector(count - self.parent.min_stacks_particle_1, 0, 0))
	end
	
	if self.parent.min_stacks_particle_2 <= count then
		ParticleManager:SetParticleControl(self.parent.reactive_particle_2, 2, Vector(count - self.parent.min_stacks_particle_2, 0, 0))
	end

	if self.parent.min_stacks_particle_3 <= count then
		ParticleManager:SetParticleControl(self.parent.reactive_particle_3, 2, Vector(count - self.parent.min_stacks_particle_3, 0, 0))
	end

	if self.parent.min_stacks_particle_4 <= count then
		ParticleManager:SetParticleControl(self.parent.reactive_particle_4, 2, Vector(count - self.parent.min_stacks_particle_4, 0, 0))
	end
end