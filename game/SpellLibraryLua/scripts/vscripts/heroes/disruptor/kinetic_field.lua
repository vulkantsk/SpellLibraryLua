LinkLuaModifier( "modifier_ability_disruptor_kinetic_field_thinker", "heroes/disruptor/kinetic_field" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_disruptor_kinetic_field", "heroes/disruptor/kinetic_field" ,LUA_MODIFIER_MOTION_NONE )

if ability_disruptor_kinetic_field == nil then
    ability_disruptor_kinetic_field = class({})
end

--------------------------------------------------------------------------------

function ability_disruptor_kinetic_field:OnSpellStart()
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    local delay = self:GetSpecialValueFor("formation_time")
    local duration = self:GetSpecialValueFor("duration")
    local radius = self:GetSpecialValueFor("radius")

    if RollPercentage(50) then
        EmitSoundOn("disruptor_dis_kineticfield_0"..math.random(1,5), caster)
    end

    EmitSoundOn("Hero_Disruptor.KineticField", caster)

    AddFOWViewer(caster:GetTeamNumber(), point, radius, delay + duration, true)

    local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_disruptor/disruptor_kineticfield_formation.vpcf", PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(fx, 0, point)
    ParticleManager:SetParticleControl(fx, 1, Vector(radius, 1, 0))
    ParticleManager:SetParticleControl(fx, 2, Vector(delay, 0, 0))
    ParticleManager:SetParticleControl(fx, 4, Vector(1, 1, 1))
    ParticleManager:SetParticleControl(fx, 15, point)   

    Timers:CreateTimer(delay, function()

        CreateModifierThinker(caster, self, "modifier_ability_disruptor_kinetic_field_thinker", {duration=duration, fx=fx}, point, caster:GetTeam(), false)
    end)
end

function ability_disruptor_kinetic_field:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

--------------------------------------------------------------------------------


modifier_ability_disruptor_kinetic_field_thinker = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
})


--------------------------------------------------------------------------------

function modifier_ability_disruptor_kinetic_field_thinker:IsAura()
    return true
end

function modifier_ability_disruptor_kinetic_field_thinker:GetModifierAura()
    return "modifier_ability_disruptor_kinetic_field"
end

function modifier_ability_disruptor_kinetic_field_thinker:GetAuraRadius()
    return 99999
end

function modifier_ability_disruptor_kinetic_field_thinker:GetAuraSearchTeam()    
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_ability_disruptor_kinetic_field_thinker:GetAuraSearchType()    
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_ability_disruptor_kinetic_field_thinker:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_NONE
end

if IsServer() then
function modifier_ability_disruptor_kinetic_field_thinker:OnCreated(kv)
    local caster = self:GetCaster()
    local point = self:GetParent():GetAbsOrigin()
    local radius = self:GetAbility():GetSpecialValueFor("radius")

    ParticleManager:DestroyParticle(kv.fx, true)
    ParticleManager:ReleaseParticleIndex(kv.fx)

    self.field_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_disruptor/disruptor_kineticfield.vpcf", PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(self.field_particle, 0, point)
    ParticleManager:SetParticleControl(self.field_particle, 1, Vector(radius, 1, 1))
    ParticleManager:SetParticleControl(self.field_particle, 2, Vector(self:GetDuration(), 0, 0))
end

function modifier_ability_disruptor_kinetic_field_thinker:OnDestroy()
    ParticleManager:DestroyParticle(self.field_particle, true)
    ParticleManager:ReleaseParticleIndex(self.field_particle)
    EmitSoundOnLocationWithCaster(self:GetParent():GetAbsOrigin(), "Hero_Disruptor.KineticField.End", self:GetCaster())
    StopSoundEvent("Hero_Disruptor.KineticField", self:GetCaster())
end
end

--------------------------------------------------------------------------------


modifier_ability_disruptor_kinetic_field = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE
        }
    end,
})


--------------------------------------------------------------------------------

if IsServer() then
function modifier_ability_disruptor_kinetic_field:OnCreated(kv)
    self.activate = false

    self:StartIntervalThink(0.03)
end

function modifier_ability_disruptor_kinetic_field:OnIntervalThink()
    local thinker = self:GetAuraOwner()
    if not thinker then self.activate = false return end
    local target = self:GetParent()
    local ability = self:GetAbility()
    local radius = ability:GetSpecialValueFor("radius")
    local duration = ability:GetSpecialValueFor("duration")
    
    local distance = (target:GetAbsOrigin() - thinker:GetAbsOrigin()):Length2D()
    local distance_from_border = distance - radius
    
    local target_angle = target:GetAnglesAsVector().y
    
    local origin_difference =  thinker:GetAbsOrigin() - target:GetAbsOrigin()
    local origin_difference_radian = math.atan2(origin_difference.y, origin_difference.x)
    
    origin_difference_radian = origin_difference_radian * 180
    local angle_from_center = origin_difference_radian / math.pi

    angle_from_center = angle_from_center + 180.0
    
    if distance_from_border <= 0 and math.abs(distance_from_border) <= 30 and (math.abs(target_angle - angle_from_center)<90 or math.abs(target_angle - angle_from_center)>270) then
        self.activate = true
        target:InterruptMotionControllers(true)
    elseif distance_from_border > 0 and math.abs(distance_from_border) <= 30 and (math.abs(target_angle - angle_from_center)>90) then
        self.activate = true
        target:InterruptMotionControllers(true)
    else
        self.activate = false
    end
end

function modifier_ability_disruptor_kinetic_field:GetModifierMoveSpeed_Absolute()
    if self.activate == true then
        return 0.1
    end
    return 
end
end