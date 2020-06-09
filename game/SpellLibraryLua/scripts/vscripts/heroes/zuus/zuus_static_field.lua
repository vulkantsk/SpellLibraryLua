if ability_zuus_static_field == nil then
    ability_zuus_static_field = class({})
end

--------------------------------------------------------------------------------

function ability_zuus_static_field:ApplyStaticField(target)
    local caster = self:GetCaster()
    if not caster:PassivesDisabled() then
        local damage = target:GetHealth() / 100 * self:GetSpecialValueFor("damage_health_pct")

        ApplyDamage({
            victim = target,
            attacker = caster,
            damage = damage,
            damage_type = self:GetAbilityDamageType(),
            damage_flags = DOTA_DAMAGE_FLAG_HPLOSS,
            ability = self
        })
    end
end