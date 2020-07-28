LinkLuaModifier( "modifier_ability_drow_ranger_wave_of_silence", "heroes/drow_ranger/wave_of_silence" ,LUA_MODIFIER_MOTION_NONE )

if ability_drow_ranger_wave_of_silence == nil then
    ability_drow_ranger_wave_of_silence = class({})
end

--------------------------------------------------------------------------------

function ability_drow_ranger_wave_of_silence:OnSpellStart()
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()
    local wave_speed = self:GetSpecialValueFor("wave_speed")
    local wave_width = self:GetSpecialValueFor("wave_width")
    local wave_distance = self:GetCastRange(caster:GetAbsOrigin(), caster)

    local vector = point-caster:GetOrigin()

    local projectile_direction = vector
    projectile_direction.z = 0
    projectile_direction = projectile_direction:Normalized()

    local info = {
        Ability = self,
        EffectName = "particles/units/heroes/hero_drow/drow_silence_wave.vpcf",
        vSpawnOrigin = caster:GetAbsOrigin(),
        fDistance = wave_distance,
        fStartRadius = wave_width,
        fEndRadius = wave_width,
        Source = caster,
        bHasFrontalCone = false,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        bDeleteOnHit = false,
        vVelocity = projectile_direction * wave_speed,
        bProvidesVision = false,
        iVisionRadius = 0,
        iVisionTeamNumber = caster:GetTeamNumber(),
    }

    ProjectileManager:CreateLinearProjectile( info )

    EmitSoundOn("Hero_DrowRanger.Silence", caster)
end

function ability_drow_ranger_wave_of_silence:OnProjectileHit(Target, Location)
    if Target ~= nil and not Target:IsInvulnerable() then
        local duration = self:GetSpecialValueFor("silence_duration")
        local knockback_duration = self:GetSpecialValueFor("knockback_duration")
        local knockback_distance_max = self:GetSpecialValueFor("knockback_distance_max")
        local knockback_height = self:GetSpecialValueFor("knockback_height")

        local caster = self:GetCaster()

        local dist = (Target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()

        local distance = knockback_distance_max - (knockback_distance_max / self:GetCastRange(caster:GetAbsOrigin(), caster) * dist)
        if distance <= 0 then
            distance = 1
        end

        local knockbackProperties =
        {
            center_x = caster:GetAbsOrigin().x,
            center_y = caster:GetAbsOrigin().y,
            center_z = caster:GetAbsOrigin().z,
            duration = knockback_duration,
            knockback_duration = knockback_duration,
            knockback_distance = distance,
            knockback_height = knockback_height,
            should_stun = false
        }

        Target:AddNewModifier( caster, self, "modifier_knockback", knockbackProperties )

        Target:AddNewModifier( caster, self, "modifier_ability_drow_ranger_wave_of_silence", {duration=duration} )

        local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_drow/drow_hero_silence.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
        ParticleManager:SetParticleControlEnt(fx, 0, Target, PATTACH_ABSORIGIN_FOLLOW, nil, Vector(0,0,0), true)
        ParticleManager:ReleaseParticleIndex(fx)
    end
    return false
end

--------------------------------------------------------------------------------


modifier_ability_drow_ranger_wave_of_silence = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return true end,
    IsPurgeException        = function(self) return true end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    CheckState              = function(self)
        return {
            [MODIFIER_STATE_SILENCED] = true
        }
    end,
    GetEffectName           = function(self) return "particles/generic_gameplay/generic_silenced.vpcf" end,
    GetEffectAttachType     = function(self) return PATTACH_OVERHEAD_FOLLOW end,
})


--------------------------------------------------------------------------------