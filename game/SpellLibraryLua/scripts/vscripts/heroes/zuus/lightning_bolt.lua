LinkLuaModifier( "modifier_ability_zuus_lightning_bolt_thinker", "heroes/zuus/lightning_bolt" ,LUA_MODIFIER_MOTION_NONE )

if ability_zuus_lightning_bolt == nil then
    ability_zuus_lightning_bolt = class({})
end

function ability_zuus_lightning_bolt:OnAbilityPhaseStart()
    self:GetCaster():EmitSound("Hero_Zuus.LightningBolt.Cast")

    return true
end

function ability_zuus_lightning_bolt:OnAbilityPhaseInterrupted()
    self:GetCaster():StopSound("Hero_Zuus.LightningBolt.Cast")
end

--------------------------------------------------------------------------------

function ability_zuus_lightning_bolt:OnSpellStart()
    local caster = self:GetCaster()
    local position = self:GetCursorPosition()
    local target = self:GetCursorTarget()
    local location = target ~= nil and target:GetAbsOrigin() or position

    local spread_aoe = self:GetSpecialValueFor("spread_aoe")
    if target then
        if target:TriggerSpellAbsorb(self) then 

            local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_lightning_bolt.vpcf", PATTACH_WORLDORIGIN, caster)
            ParticleManager:SetParticleControl(fx, 0, Vector(location.x, location.y, location.z))
            ParticleManager:SetParticleControl(fx, 1, Vector(location.x, location.y, 2000))
            ParticleManager:SetParticleControl(fx, 2, Vector(location.x, location.y, location.z))

            return 
        end
    else
        local all = FindUnitsInRadius(caster:GetTeam(), 
        location, 
        nil, 
        spread_aoe,
        DOTA_UNIT_TARGET_TEAM_ENEMY, 
        DOTA_UNIT_TARGET_HERO, 
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER, 
        false)

        local Nearest = nil
        local distance = nil
        for _, hero in ipairs(all) do
            local distanceToHero = (location - hero:GetOrigin()):Length()
            if hero:IsAlive() and (distance == nil or distanceToHero < distance) and distanceToHero <= spread_aoe then
                distance = distanceToHero
                Nearest = hero
            end
        end
        target = Nearest
    end

    local sight_duration = self:GetSpecialValueFor("sight_duration")
    local sight_radius = self:GetSpecialValueFor("sight_radius_night")
    if GameRules:IsDaytime() then
        sight_radius = self:GetSpecialValueFor("sight_radius_day") 
    end

    EmitSoundOnLocationWithCaster(location, "Hero_Zuus.LightningBolt", caster)
    AddFOWViewer(caster:GetTeamNumber(), location, sight_radius, sight_duration, false)
    CreateModifierThinker(caster, self, "modifier_ability_zuus_lightning_bolt_thinker", {duration = sight_duration}, location, caster:GetTeam(), false)

    if target then
        local pos = target:GetAbsOrigin()

        if target:TriggerSpellAbsorb(self) then return end

        local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_lightning_bolt.vpcf", PATTACH_WORLDORIGIN, caster)
        ParticleManager:SetParticleControl(fx, 0, Vector(pos.x, pos.y, pos.z))
        ParticleManager:SetParticleControl(fx, 1, Vector(pos.x, pos.y, 2000))
        ParticleManager:SetParticleControl(fx, 2, Vector(pos.x, pos.y, pos.z))

        local field = caster:FindAbilityByName("ability_zuus_static_field")
        if field then field:ApplyStaticField(target) end

        ApplyDamage({
            victim = target,
            attacker = caster,
            damage = self:GetAbilityDamage(),
            damage_type = self:GetAbilityDamageType(),
            ability = self
        })

        target:AddNewModifier(caster, self, "modifier_stunned", {duration=0.2})
    else
        local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_lightning_bolt.vpcf", PATTACH_WORLDORIGIN, caster)
        ParticleManager:SetParticleControl(fx, 0, Vector(location.x, location.y, location.z))
        ParticleManager:SetParticleControl(fx, 1, Vector(location.x, location.y, 2000))
        ParticleManager:SetParticleControl(fx, 2, Vector(location.x, location.y, location.z))
    end
end

--------------------------------------------------------------------------------


modifier_ability_zuus_lightning_bolt_thinker = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
})


--------------------------------------------------------------------------------

function modifier_ability_zuus_lightning_bolt_thinker:IsAura()
    return true
end

function modifier_ability_zuus_lightning_bolt_thinker:GetModifierAura()
    return "modifier_truesight"
end

function modifier_ability_zuus_lightning_bolt_thinker:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("true_sight_radius")
end

function modifier_ability_zuus_lightning_bolt_thinker:GetAuraSearchTeam()    
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_ability_zuus_lightning_bolt_thinker:GetAuraDuration()    
    return 0.5
end

function modifier_ability_zuus_lightning_bolt_thinker:GetAuraSearchType()    
    return DOTA_UNIT_TARGET_ALL
end

function modifier_ability_zuus_lightning_bolt_thinker:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end
