LinkLuaModifier( "modifier_ability_sniper_shrapnel", "heroes/sniper/shrapnel" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_sniper_shrapnel_slow", "heroes/sniper/shrapnel" ,LUA_MODIFIER_MOTION_NONE )

if ability_sniper_shrapnel == nil then
    ability_sniper_shrapnel = class({})
end

--------------------------------------------------------------------------------

function ability_sniper_shrapnel:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function ability_sniper_shrapnel:OnSpellStart()
    local caster = self:GetCaster()
    local position = self:GetCursorPosition()

    local cast_response = {"sniper_snip_ability_shrapnel_01", "sniper_snip_ability_shrapnel_03"}
    local group_cast_response = {"sniper_snip_ability_shrapnel_02", "sniper_snip_ability_shrapnel_04", "sniper_snip_ability_shrapnel_06"}
    local rare_group_cast_response = "sniper_snip_ability_shrapnel_06"
    local sound_cast = "Hero_Sniper.ShrapnelShoot"
    local sound_shrapnel = "Hero_Sniper.ShrapnelShatter"
    local particle_launch = "particles/units/heroes/hero_sniper/sniper_shrapnel_launch.vpcf"
    local modifier_shrapnel_aura = "modifier_ability_sniper_shrapnel"

    local damage_delay = self:GetSpecialValueFor("damage_delay")
    local duration = self:GetSpecialValueFor("duration")
    local radius = self:GetSpecialValueFor("radius")

    local enemies = FindUnitsInRadius(caster:GetTeamNumber(),
        position,
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS + DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        FIND_ANY_ORDER,
        false)

    if #enemies >= 4 then
        if RollPercentage(5) then
            EmitSoundOn(rare_group_cast_response, caster)
        elseif RollPercentage(75) then
            EmitSoundOn(group_cast_response[math.random(1, #group_cast_response)], caster)
        end
    elseif RollPercentage(75) then
        EmitSoundOn(cast_response[math.random(1,#cast_response)], caster)
    end

    EmitSoundOn(sound_cast, caster)

    EmitSoundOnLocationWithCaster(position, sound_shrapnel, caster)

    local distance = (position - caster:GetAbsOrigin()):Length2D()
    local direction = (position - caster:GetAbsOrigin()):Normalized()
    local pos = caster:GetAbsOrigin() + direction * (distance / 2)

    local fx = ParticleManager:CreateParticle(particle_launch, PATTACH_CUSTOMORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControlEnt(fx, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl(fx, 1, Vector(pos.x, pos.y, pos.z + 1000))
    ParticleManager:ReleaseParticleIndex(fx)

    Timers:CreateTimer(damage_delay, function()
        CreateModifierThinker(caster, self, modifier_shrapnel_aura, {duration = duration}, position, caster:GetTeamNumber(), false)

        AddFOWViewer(caster:GetTeamNumber(), position, radius, duration, false)
    end)
end

--------------------------------------------------------------------------------


modifier_ability_sniper_shrapnel = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
})


--------------------------------------------------------------------------------

function modifier_ability_sniper_shrapnel:IsAura()
    return true
end

function modifier_ability_sniper_shrapnel:GetModifierAura()
    return "modifier_ability_sniper_shrapnel_slow"
end

function modifier_ability_sniper_shrapnel:GetAuraRadius()
    return self.radius
end

function modifier_ability_sniper_shrapnel:GetAuraSearchTeam()    
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_ability_sniper_shrapnel:GetAuraSearchType()    
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_ability_sniper_shrapnel:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_ability_sniper_shrapnel:GetAuraDuration()
    return 0.5
end

function modifier_ability_sniper_shrapnel:OnCreated()
    local point = self:GetParent():GetAbsOrigin()
    self.radius = self:GetAbility():GetSpecialValueFor("radius")

    self.particle_shrapnel = "particles/units/heroes/hero_sniper/sniper_shrapnel.vpcf"

    if IsServer() then
        self.fx = ParticleManager:CreateParticle(self.particle_shrapnel, PATTACH_WORLDORIGIN, self:GetParent())
        ParticleManager:SetParticleControl(self.fx, 0, point)
        ParticleManager:SetParticleControl(self.fx, 1, Vector(self.radius, self.radius, 0))
        ParticleManager:SetParticleControl(self.fx, 2, point)
        self:AddParticle(self.fx, false, false, -1, false, false)
    end
end

--------------------------------------------------------------------------------


modifier_ability_sniper_shrapnel_slow = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
        }
    end,
})


--------------------------------------------------------------------------------

function modifier_ability_sniper_shrapnel_slow:OnCreated()
    self.slow_movement_speed = self:GetAbility():GetSpecialValueFor("slow_movement_speed")
    self.shrapnel_damage = self:GetAbility():GetSpecialValueFor("shrapnel_damage")

    if IsServer() then
        self:ShrapnelTickDamage()

        self:StartIntervalThink(1.0)
    end
end

function modifier_ability_sniper_shrapnel_slow:OnIntervalThink()
    self:ShrapnelTickDamage()
end

function modifier_ability_sniper_shrapnel_slow:ShrapnelTickDamage()
    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = self.shrapnel_damage,
        damage_type = self:GetAbility():GetAbilityDamageType(),
        ability = self:GetAbility()
    })
end

function modifier_ability_sniper_shrapnel_slow:GetModifierMoveSpeedBonus_Percentage() return self.slow_movement_speed end