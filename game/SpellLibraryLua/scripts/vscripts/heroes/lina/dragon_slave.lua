if ability_lina_dragon_slave == nil then
    ability_lina_dragon_slave = class({})
end

--------------------------------------------------------------------------------

function ability_lina_dragon_slave:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local position = target and target:GetAbsOrigin() or self:GetCursorPosition()

    EmitSoundOn("Hero_Lina.DragonSlave", caster)

    local speed = self:GetSpecialValueFor("dragon_slave_speed")
    local width_initial = self:GetSpecialValueFor("dragon_slave_width_initial")
    local width_end = self:GetSpecialValueFor("dragon_slave_width_end")
    local distance = self:GetSpecialValueFor("dragon_slave_distance")

    local proj = "particles/units/heroes/hero_lina/lina_spell_dragon_slave.vpcf"

    local direction = (position - caster:GetAbsOrigin()):Normalized()

    local info = {
        Ability = self,
        EffectName = proj,
        vSpawnOrigin = caster:GetAbsOrigin(),
        fDistance = distance,
        fStartRadius = width_initial,
        fEndRadius = width_end,
        Source = caster,
        bHasFrontalCone = false,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        bDeleteOnHit = false,
        vVelocity = direction * speed,
        bProvidesVision = false
    }

    ProjectileManager:CreateLinearProjectile( info )
end

function ability_lina_dragon_slave:OnProjectileHit(Target, Location)
    if Target ~= nil and not Target:IsInvulnerable() then
        ApplyDamage({
            victim = Target,
            attacker = self:GetCaster(),
            damage = self:GetAbilityDamage(),
            damage_type = self:GetAbilityDamageType(),
            ability = self
        })
    end
    return false
end