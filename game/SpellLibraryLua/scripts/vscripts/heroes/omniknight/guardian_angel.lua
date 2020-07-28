LinkLuaModifier( "modifier_ability_omniknight_guardian_angel", "heroes/omniknight/guardian_angel" ,LUA_MODIFIER_MOTION_NONE )

if ability_omniknight_guardian_angel == nil then
    ability_omniknight_guardian_angel = class({})
end

--------------------------------------------------------------------------------

function ability_omniknight_guardian_angel:OnSpellStart()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")
    local radius = self:GetSpecialValueFor("radius")
    local cast_response = {"omniknight_omni_ability_guard_04", "omniknight_omni_ability_guard_05", "omniknight_omni_ability_guard_06", "omniknight_omni_ability_guard_10"}

    local all = FindUnitsInRadius(caster:GetTeamNumber(), 
    caster:GetAbsOrigin(), 
    nil, 
    radius,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY, 
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER, 
    false)

    for _, unit in ipairs(all) do
        unit:AddNewModifier(caster, self, "modifier_ability_omniknight_guardian_angel", {duration=duration})

        EmitSoundOn("Hero_Omniknight.GuardianAngel", unit)
    end

    EmitSoundOn(cast_response[math.random(1, #cast_response)], caster)

    EmitSoundOn("Hero_Omniknight.GuardianAngel.Cast", caster)
end

--------------------------------------------------------------------------------


modifier_ability_omniknight_guardian_angel = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return true end,
    IsPurgeException        = function(self) return true end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL
        }
    end,
    GetStatusEffectName     = function(self) return "particles/status_fx/status_effect_guardian_angel.vpcf" end,
    StatusEffectPriority    = function(self) return MODIFIER_PRIORITY_HIGH end,
})


--------------------------------------------------------------------------------

function modifier_ability_omniknight_guardian_angel:OnCreated()
    local parent = self:GetParent()
    local caster = self:GetCaster()

    if parent == caster then
        self.wings_fx = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_guardian_angel_omni.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
        ParticleManager:SetParticleControl(self.wings_fx, 0, parent:GetAbsOrigin())
        ParticleManager:SetParticleControlEnt(self.wings_fx, 5, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
        self:AddParticle(self.wings_fx, false, false, -1, false, false)    

        self.halo_fx = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_guardian_angel_halo_buff.vpcf", PATTACH_OVERHEAD_FOLLOW, parent)
        ParticleManager:SetParticleControlEnt(self.halo_fx, 0, parent, PATTACH_OVERHEAD_FOLLOW, nil, parent:GetAbsOrigin(), true)    
        self:AddParticle(self.halo_fx, false, false, -1, false, false)    
    else
        self.ally_fx = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_guardian_angel_ally.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
        ParticleManager:SetParticleControl(self.ally_fx, 0, parent:GetAbsOrigin())
        self:AddParticle(self.ally_fx, false, false, -1, false, false)  

        self.wings_ally_fx = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_guardian_angel_wings_buff.vpcf", PATTACH_OVERHEAD_FOLLOW, parent)
        ParticleManager:SetParticleControlEnt(self.wings_ally_fx, 0, parent, PATTACH_OVERHEAD_FOLLOW, nil, parent:GetAbsOrigin(), true)    
        self:AddParticle(self.wings_ally_fx, false, false, -1, false, false)     
    end 
end

function modifier_ability_omniknight_guardian_angel:GetAbsoluteNoDamagePhysical() return 1 end