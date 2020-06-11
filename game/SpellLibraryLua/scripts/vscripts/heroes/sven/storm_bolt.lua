if ability_sven_storm_bolt == nil then
    ability_sven_storm_bolt = class({})
end

--------------------------------------------------------------------------------

function ability_sven_storm_bolt:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    EmitSoundOn("Hero_Sven.StormBolt", caster)

    local speed = self:GetSpecialValueFor("bolt_speed")
    local vision_radius = self:GetSpecialValueFor("vision_radius")

    local proj = "particles/units/heroes/hero_sven/sven_spell_storm_bolt.vpcf"

    local info = {
        Target = target,
        Source = caster,
        Ability = self,
        EffectName = proj,
        bDodgeable = true,
        bIsAttack = false,
        bProvidesVision = true,
        iMoveSpeed = speed,
        vSpawnOrigin = caster:GetAbsOrigin(),
        iVisionRadius = vision_radius,
        iVisionTeamNumber = caster:GetTeamNumber(),
    }
    ProjectileManager:CreateTrackingProjectile( info )
end

function ability_sven_storm_bolt:OnProjectileHit(Target, Location)
    if Target ~= nil and not Target:IsInvulnerable() then
        local bolt_aoe = self:GetSpecialValueFor("bolt_aoe")
        local bolt_stun_duration = self:GetSpecialValueFor("bolt_stun_duration")

        local all = FindUnitsInRadius(self:GetCaster():GetTeam(), 
        Target:GetOrigin(), 
        nil, 
        bolt_aoe,
        DOTA_UNIT_TARGET_TEAM_ENEMY, 
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER, 
        false)

        EmitSoundOn("Hero_Sven.StormBoltImpact", Target)

        for _, unit in ipairs(all) do
            if not (unit == Target and Target:TriggerSpellAbsorb(self)) then
                ApplyDamage({
                    victim = unit,
                    attacker = self:GetCaster(),
                    damage = self:GetAbilityDamage(),
                    damage_type = self:GetAbilityDamageType(),
                    ability = self
                })

                unit:AddNewModifier(self:GetCaster(), self, "modifier_stunned", {duration=bolt_stun_duration})
            end
        end
    end
    return false
end

function ability_sven_storm_bolt:GetAOERadius()
    return self:GetSpecialValueFor("bolt_aoe")
end