ability_warpath = class({})

function ability_warpath:GetIntrinsicModifierName() return 'modifier_ability_warpath_buff' end

LinkLuaModifier('modifier_ability_warpath_buff', 'heroes/bristleback/warpath', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('modifier_ability_warpath_buff_particle', 'heroes/bristleback/warpath', LUA_MODIFIER_MOTION_NONE)
-- Original: https://github.com/EarthSalamander42/dota_imba/blob/77d0b1f04e322812d16b0fce6e0089c24c4a38e2/game/dota_addons/dota_imba_reborn/scripts/vscripts/components/abilities/heroes/hero_bristleback.lua#L548-L628
modifier_ability_warpath_buff = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return false end,
    AllowIllusionDuplicate  = function(self) return true end,
    IsPermanent             = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
        }
    end,
})

function modifier_ability_warpath_buff:OnCreated()
	self.ability	= self:GetAbility()
	self.caster		= self:GetCaster()
    self.parent		= self:GetParent()
    
    self.stack_duration			= self.ability:GetSpecialValueFor("stack_duration")
	self.max_stacks				= self.ability:GetSpecialValueFor("max_stacks")
end


function modifier_ability_warpath_buff:OnAbilityFullyCast(keys)
	if keys.ability and keys.unit == self.parent and not self.parent:PassivesDisabled() and not keys.ability:IsItem() and keys.ability:GetName() ~= "ability_capture" then
        local modifier = self.parent:FindModifierByName('modifier_ability_warpath_buff_particle')
        local stacks = modifier and modifier:GetStackCount() or 0
        if stacks < self.max_stacks then
            self:GetParent():AddStackModifier({
                ability = self.ability,
                modifier = 'modifier_ability_warpath_buff_particle',
                duration = self.stack_duration,
                updateStack = true,
                caster = self.parent,
            })
        end 

        if modifier then 
            modifier:SetDuration(self.stack_duration,true)
        end 

	end
end

modifier_ability_warpath_buff_particle = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return false end,
    AllowIllusionDuplicate  = function(self) return true end, 
    GetEffectName           = function(self) return 'particles/units/heroes/hero_bristleback/bristleback_warpath_dust.vpcf'  end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
            MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_MODEL_SCALE,
        }
    end,
})

function modifier_ability_warpath_buff_particle:OnCreated()

    self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_bristleback/bristleback_warpath.vpcf", PATTACH_POINT_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControlEnt(self.particle, 3, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_attack1", self:GetParent():GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(self.particle, 4, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_attack2", self:GetParent():GetAbsOrigin(), true)

    -- AbilitySpecials
    self.ability                = self:GetAbility()
	self.damage_per_stack		= self.ability:GetSpecialValueFor("damage_per_stack")
	self.move_speed_per_stack	= self.ability:GetSpecialValueFor("move_speed_per_stack")

    
end 

function modifier_ability_warpath_buff_particle:OnRefresh()
    self.ability                = self:GetAbility()
	self.damage_per_stack		= self.ability:GetSpecialValueFor("damage_per_stack")
	self.move_speed_per_stack	= self.ability:GetSpecialValueFor("move_speed_per_stack")
end 

function modifier_ability_warpath_buff_particle:OnDestroy()
    if not self.particle then return end 

    ParticleManager:DestroyParticle(self.particle, true)
    ParticleManager:ReleaseParticleIndex(self.particle)
end 


function modifier_ability_warpath_buff_particle:GetModifierModelScale()
	return self:GetStackCount() * 5
end

function modifier_ability_warpath_buff_particle:GetModifierPreAttack_BonusDamage(keys)
    return (self.damage_per_stack or 0) * self:GetStackCount()
end

function modifier_ability_warpath_buff_particle:GetModifierMoveSpeedBonus_Percentage(keys)
	return (self.move_speed_per_stack or 0) * self:GetStackCount()
end
