LinkLuaModifier( "modifier_ability_zuus_thundergods_wrath_thinker", "heroes/zuus/thundergods_wrath" ,LUA_MODIFIER_MOTION_NONE )

if ability_zuus_thundergods_wrath == nil then
    ability_zuus_thundergods_wrath = class({})
end

--------------------------------------------------------------------------------

function ability_zuus_thundergods_wrath:OnAbilityPhaseStart()
    EmitGlobalSound("Hero_Zuus.GodsWrath.PreCast")
    local part = "particles/units/heroes/hero_zuus/zuus_thundergods_wrath_start.vpcf"
    self.p = ParticleManager:CreateParticle(part, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
    ParticleManager:SetParticleControl(self.p, 0, self:GetCaster():GetAbsOrigin())
    ParticleManager:SetParticleControl(self.p, 1, self:GetCaster():GetAbsOrigin() + Vector(0,0,75))
    ParticleManager:SetParticleControl(self.p, 2, self:GetCaster():GetAbsOrigin() + Vector(0,0,75))
    ParticleManager:SetParticleControl(self.p, 61, Vector(0,0,0))
    return true
end

function ability_zuus_thundergods_wrath:OnAbilityPhaseInterrupted()
    self:GetCaster():StopSound("Hero_Zuus.GodsWrath.PreCast")
    ParticleManager:DestroyParticle(self.p, false)
    ParticleManager:ReleaseParticleIndex(self.p)
end

function ability_zuus_thundergods_wrath:OnSpellStart()
    local caster = self:GetCaster()

    local sight_duration = self:GetSpecialValueFor("sight_duration")
    local damage = self:GetSpecialValueFor("damage")

    local sight_radius = self:GetSpecialValueFor("sight_radius_night")
    if GameRules:IsDaytime() then
        sight_radius = self:GetSpecialValueFor("sight_radius_day") 
    end

    local all = FindUnitsInRadius(caster:GetTeam(), 
    caster:GetAbsOrigin(), 
    nil, 
    99999,
    DOTA_UNIT_TARGET_TEAM_ENEMY, 
    DOTA_UNIT_TARGET_HERO, 
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO,
    FIND_ANY_ORDER, 
    false)

    for _, hero in ipairs(all) do
        if not hero:IsClone() and not hero:IsIllusion() then
            if (not hero:IsInvisible() or UnitFilter(hero, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, caster:GetTeamNumber()) == UF_SUCCESS) and not hero:IsMagicImmune() then
                local field = caster:FindAbilityByName("ability_zuus_static_field")
                if field then field:ApplyStaticField(hero) end

                ApplyDamage({
                    victim = hero,
                    attacker = caster,
                    damage = damage,
                    damage_type = self:GetAbilityDamageType(),
                    ability = self
                })
            end
            local pos = hero:GetAbsOrigin()

            local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_thundergods_wrath.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
            ParticleManager:SetParticleControl(fx, 0, Vector(pos.x, pos.y, pos.z + hero:GetBoundingMaxs().z))
            ParticleManager:SetParticleControl(fx, 1, Vector(pos.x, pos.y, 2000))
            ParticleManager:SetParticleControl(fx, 2, Vector(pos.x, pos.y, pos.z + hero:GetBoundingMaxs().z))

            hero:EmitSound("Hero_Zuus.GodsWrath.Target")

            AddFOWViewer(caster:GetTeam(), hero:GetAbsOrigin(), sight_radius, sight_duration, false)
            CreateModifierThinker(caster, self, "modifier_ability_zuus_thundergods_wrath_thinker", {duration = sight_duration}, hero:GetAbsOrigin(), caster:GetTeam(), false)
            ScreenShake(hero:GetAbsOrigin(), 300, 300, 0.3, 1800, 0, true)
        end
    end
    EmitGlobalSound("Hero_Zuus.GodsWrath")
end

--------------------------------------------------------------------------------


modifier_ability_zuus_thundergods_wrath_thinker = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
})


--------------------------------------------------------------------------------

function modifier_ability_zuus_thundergods_wrath_thinker:IsAura()
    return true
end

function modifier_ability_zuus_thundergods_wrath_thinker:GetModifierAura()
    return "modifier_truesight"
end

function modifier_ability_zuus_thundergods_wrath_thinker:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("sight_radius_day")
end

function modifier_ability_zuus_thundergods_wrath_thinker:GetAuraSearchTeam()    
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_ability_zuus_thundergods_wrath_thinker:GetAuraDuration()    
    return 0.5
end

function modifier_ability_zuus_thundergods_wrath_thinker:GetAuraSearchType()    
    return DOTA_UNIT_TARGET_ALL
end

function modifier_ability_zuus_thundergods_wrath_thinker:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end