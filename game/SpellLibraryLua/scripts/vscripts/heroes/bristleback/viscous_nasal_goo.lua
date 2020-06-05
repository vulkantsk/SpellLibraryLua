ability_viscous_nasal_goo = class({})
LinkLuaModifier('modifier_ability_viscous_nasal_goo_debuff', 'heroes/bristleback/viscous_nasal_goo', LUA_MODIFIER_MOTION_NONE)
function ability_viscous_nasal_goo:OnSpellStart()
    
    local target = self:GetCursorTarget()
    local caster = self:GetCaster()
    local goo_speed = self:GetSpecialValueFor('goo_speed')

    ProjectileManager:CreateTrackingProjectile({
        Target 				= target,
        Source 				= caster,
        Ability 			= self,
        EffectName 			= "particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_goo.vpcf",
        iMoveSpeed 			= goo_speed,
        vSourceLoc			= caster:GetAbsOrigin(),
        bDrawsOnMinimap		= false,
        bDodgeable			= true,
        bIsAttack 			= false,
        bVisibleToEnemies	= true,
        bReplaceExisting 	= false,
        flExpireTime 		= GameRules:GetGameTime() + 10,
        bProvidesVision 	= false,
        iVisionRadius 		= 0,
        iVisionTeamNumber 	= caster:GetTeamNumber()
    })
    caster:EmitSound("bristleback_bristle_nasal_goo_0"..RandomInt(1,7))
end

function ability_viscous_nasal_goo:OnProjectileHit(hTarget, vLocation)
    if hTarget ~= nil and hTarget:IsAlive() and not hTarget:IsMagicImmune() then
        local debuff = hTarget:FindModifierByName('modifier_ability_viscous_nasal_goo_debuff')
        if not debuff or debuff:GetStackCount() <= self:GetSpecialValueFor('stack_limit') then 
            hTarget:AddStackModifier({
                ability = self,
                modifier = 'modifier_ability_viscous_nasal_goo_debuff',
                duration = self:GetSpecialValueFor('goo_duration'),
                updateStack = true,
                caster = self:GetCaster(),
            })
            hTarget:EmitSound("Hero_Bristleback.ViscousGoo.Target")
        end
	end
end

modifier_ability_viscous_nasal_goo_debuff = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return true end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    AllowIllusionDuplicate  = function(self) return false end,
    DeclareFunctions        = function(self) return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }  end,

    GetModifierPhysicalArmorBonus = function(self) return -(self.base_armor + (self.armor_per_stack * self:GetStackCount())) end,
    GetModifierMoveSpeedBonus_Percentage = function(self) if IsClient() then return end return -(self.base_move_slow + (self.move_slow_per_stack * self:GetStackCount())) end,
    GetEffectName   = function(self) return "particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_goo_debuff.vpcf" end,
    GetStatusEffectName = function(self) return "particles/status_fx/status_effect_goo.vpcf" end,
})

function modifier_ability_viscous_nasal_goo_debuff:OnCreated()
    local ability = self:GetAbility()
    self.base_armor = ability:GetSpecialValueFor('base_armor')
    self.armor_per_stack = ability:GetSpecialValueFor('armor_per_stack')
    self.base_move_slow = ability:GetSpecialValueFor('base_move_slow')
    self.move_slow_per_stack = ability:GetSpecialValueFor('move_slow_per_stack')
    if not self.particle then 
        self.particle = self.particle or ParticleManager:CreateParticle("particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_stack.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent())
        ParticleManager:SetParticleControl(self.particle, 1, Vector(0, 1, 0))
    end
end 

function modifier_ability_viscous_nasal_goo_debuff:OnDestroy()
    if self.particle then 
        ParticleManager:DestroyParticle(self.particle, true)
    end 
end 

function modifier_ability_viscous_nasal_goo_debuff:OnRefresh()
    local ability = self:GetAbility()
    self.base_armor = ability:GetSpecialValueFor('base_armor')
    self.armor_per_stack = ability:GetSpecialValueFor('armor_per_stack')
    self.base_move_slow = ability:GetSpecialValueFor('base_move_slow')
    self.move_slow_per_stack = ability:GetSpecialValueFor('move_slow_per_stack')
    ParticleManager:SetParticleControl(self.particle, 1, Vector(0, self:GetStackCount(), 0))
end