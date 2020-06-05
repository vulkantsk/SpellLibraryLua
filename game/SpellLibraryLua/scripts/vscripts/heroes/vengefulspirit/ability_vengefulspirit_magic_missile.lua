if ability_vengefulspirit_magic_missile == nil then
    ability_vengefulspirit_magic_missile = class({})
end

--------------------------------------------------------------------------------

function ability_vengefulspirit_magic_missile:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    local speed = self:GetSpecialValueFor("magic_missile_speed")

    caster:EmitSound("Hero_VengefulSpirit.MagicMissile")

    local proj = "particles/units/heroes/hero_vengeful/vengeful_magic_missle.vpcf"

    local info = {
        Target = target,
        Source = caster,
        Ability = self,
        EffectName = proj,
        bDodgeable = false,
        bIsAttack = false,
        bProvidesVision = true,
        iMoveSpeed = speed,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_2
    }
    ProjectileManager:CreateTrackingProjectile( info )
end

function ability_vengefulspirit_magic_missile:OnProjectileHit(Target, Location)
    if Target ~= nil and not Target:IsInvulnerable() then
        local damage = self:GetSpecialValueFor("magic_missile_damage")
        local magic_missile_stun = self:GetSpecialValueFor("magic_missile_stun")

        if Target:TriggerSpellAbsorb(self) then
            return false
        end

        ApplyDamage({
            victim = Target,
            attacker = self:GetCaster(),
            damage = damage,
            damage_type = self:GetAbilityDamageType(),
            ability = self
        })

        EmitSoundOn("Hero_VengefulSpirit.MagicMissileImpact", Target)

        Target:AddNewModifier(self:GetCaster(), self, "modifier_stunned", {duration=magic_missile_stun})
    end
    return false
end