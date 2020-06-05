ability_culling_blade = class({})
LinkLuaModifier('modifier_ability_culling_blade_buff', 'heroes/axe/culling_blade', LUA_MODIFIER_MOTION_NONE)

function ability_culling_blade:OnSpellStart()

    local target = self:GetCursorTarget()
    local caster = self:GetCaster()
    local kill_threshold = self:GetSpecialValueFor('kill_threshold')
    local damage = self:GetSpecialValueFor('damage')
    local speed_duration = self:GetSpecialValueFor('speed_duration')
    local speed_aoe = self:GetSpecialValueFor('speed_aoe')

    if target:GetHealth() <= kill_threshold then 
        target:Kill(self, attacker)
        target:EmitSound('Hero_Axe.Culling_Blade_Success')
        self:GetCaster():StartGestureWithPlaybackRate( ACT_DOTA_CAST_ABILITY_4, 1 )
        if target:IsHero() then 
            self:EndCooldown()
        end 
        local culling_kill_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_culling_blade_kill.vpcf", PATTACH_CUSTOMORIGIN, target)
        ParticleManager:SetParticleControl(culling_kill_particle, 4, target:GetOrigin())
        ParticleManager:ReleaseParticleIndex(culling_kill_particle)

        local enemies = FindUnitsInRadius(caster:GetTeamNumber(), 
        target:GetAbsOrigin(),
        nil, 
        speed_aoe, 
        DOTA_UNIT_TARGET_TEAM_FRIENDLY, 
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 
        FIND_ANY_ORDER, 
        false)

        for k,v in pairs(enemies) do
            print(v:GetUnitName())
            v:AddNewModifier(caster, self, 'modifier_ability_culling_blade_buff', {duration = speed_duration})
        end 

        return 
    end 

    ApplyDamage({
        victim = target,
        attacker = caster,
        ability = self,
        damage = damage,
        damage_type = self:GetAbilityDamageType(),
    })

    self:GetCaster():StartGestureWithPlaybackRate( ACT_DOTA_CAST_ABILITY_4, 1 )
    target:EmitSound('Hero_Axe.Culling_Blade_Fail')

end

modifier_ability_culling_blade_buff = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return true end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    AllowIllusionDuplicate  = function(self) return true end,
    DeclareFunctions        = function(self)
        return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT}
    end,
    GetModifierMoveSpeedBonus_Percentage = function(self) return self.movespeed end,
    GetModifierAttackSpeedBonus_Constant = function(self) return self.atkSpeed end,
    

})

function modifier_ability_culling_blade_buff:OnCreated()
    self.movespeed = self:GetAbility():GetSpecialValueFor('speed_bonus')
    self.atkSpeed = self:GetAbility():GetSpecialValueFor('atk_speed_bonus')
end 