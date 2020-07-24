if ability_nyx_assassin_mana_burn == nil then
    ability_nyx_assassin_mana_burn = class({})
end

--------------------------------------------------------------------------------

function ability_nyx_assassin_mana_burn:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local float_multiplier = self:GetSpecialValueFor("float_multiplier")

    if target:TriggerSpellAbsorb(self) then return end

    EmitSoundOn("Hero_NyxAssassin.ManaBurn.Cast", caster)

    EmitSoundOn("Hero_NyxAssassin.ManaBurn.Target", target)

    local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_mana_burn.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:ReleaseParticleIndex(fx)   

    local mana = target:GetMana()
    local int = target:GetIntellect()
    local damage = int * float_multiplier
    if mana < damage then
        damage = mana
    end

    local damageTable = {
        victim = target,
        attacker = caster, 
        damage = damage,
        damage_type = self:GetAbilityDamageType(),
        ability = self
    }

    ApplyDamage(damageTable) 

    target:ReduceMana(damage)

    SendOverheadEventMessage( target, OVERHEAD_ALERT_MANA_LOSS, target, damage, nil )
end