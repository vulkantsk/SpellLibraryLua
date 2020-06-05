ability_mist_coil = class({})

function ability_mist_coil:CastFilterResultTarget(hTarget)
    if hTarget == self:GetCaster() then
        return UF_FAIL_CUSTOM
    end

    return UF_SUCCESS
end

function ability_mist_coil:GetCustomCastErrorTarget()
    return 'dota_hud_error_cant_cast_on_self'
end

function ability_mist_coil:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    caster:EmitSound('Hero_Abaddon.DeathCoil.Cast')
    
    ApplyDamage({
        victim = caster,
        attacker = caster,
        damage = self:GetSpecialValueFor('self_damage'),
        damage_type = self:GetAbilityDamageType(),
        damage_flags = DOTA_DAMAGE_FLAG_NON_LETHAL,
        ability = self,
    })

    ProjectileManager:CreateTrackingProjectile({
        Target = target,
        Source = caster,
        Ability = self,	
        EffectName = "particles/units/heroes/hero_abaddon/abaddon_death_coil.vpcf",
        iMoveSpeed = self:GetSpecialValueFor('missile_speed'),
        vSourceLoc= caster:GetAbsOrigin(),
        bDodgeable = false,
    })
end

function ability_mist_coil:OnProjectileHit(hTarget, vLocation)
    if not hTarget then return end

    hTarget:EmitSound('Hero_Abaddon.DeathCoil.Target')

    if hTarget:GetTeam() ~= self:GetCaster():GetTeam() then 
        ApplyDamage({
            victim = hTarget,
            attacker = self:GetCaster(),
            damage = self:GetSpecialValueFor('target_damage'),
            damage_type = self:GetAbilityDamageType(),
            damage_flags = DOTA_DAMAGE_FLAG_NONE,
            ability = self,
        })
        return true
    end

    hTarget:Heal(self:GetSpecialValueFor('heal_amount'), self:GetCaster())
end