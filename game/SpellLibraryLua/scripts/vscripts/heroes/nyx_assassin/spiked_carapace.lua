LinkLuaModifier( "modifier_ability_nyx_assassin_spiked_carapace", "heroes/nyx_assassin/spiked_carapace" ,LUA_MODIFIER_MOTION_NONE )

if ability_nyx_assassin_spiked_carapace == nil then
    ability_nyx_assassin_spiked_carapace = class({})
end

--------------------------------------------------------------------------------

function ability_nyx_assassin_spiked_carapace:OnSpellStart()
    local caster = self:GetCaster()

    local duration = self:GetSpecialValueFor("reflect_duration")

    EmitSoundOn("Hero_NyxAssassin.SpikedCarapace", caster)

    caster:AddNewModifier(caster, self, "modifier_ability_nyx_assassin_spiked_carapace", {duration=duration})
end


--------------------------------------------------------------------------------


modifier_ability_nyx_assassin_spiked_carapace = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_AVOID_DAMAGE
        }
    end,
})


--------------------------------------------------------------------------------

function modifier_ability_nyx_assassin_spiked_carapace:OnCreated()
    self.stun_duration = self:GetAbility():GetSpecialValueFor("stun_duration")
    self.damage_reflect_pct = self:GetAbility():GetSpecialValueFor("damage_reflect_pct")

    if IsServer() then
        self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_spiked_carapace.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self:GetCaster())
        ParticleManager:SetParticleControlEnt(self.fx, 0, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetCaster():GetAbsOrigin(), true)
        self:AddParticle(self.fx, false, false, -1, false, false)
    end

    self.Table_affected = {}
end

function HasAffected(table, target)
    for k,v in pairs(table) do
        if v == target then
            return true
        end
    end
    return false
end

function modifier_ability_nyx_assassin_spiked_carapace:GetModifierAvoidDamage(k)
    local target = k.target
    local caster = self:GetCaster()
    local attacker = k.attacker
    local original_damage = k.original_damage
    local damage_type = k.damage_type
    local damage_flags = k.damage_flags
    if caster == target and attacker:IsHero() and not HasAffected(self.Table_affected, attacker) and caster:GetTeamNumber() ~= attacker:GetTeamNumber() and bit.band(damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) ~= DOTA_DAMAGE_FLAG_REFLECTION and bit.band(damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) ~= DOTA_DAMAGE_FLAG_HPLOSS then
        table.insert(self.Table_affected, attacker)

        EmitSoundOn("Hero_NyxAssassin.SpikedCarapace.Stun", target)

        attacker:AddNewModifier(caster, self:GetAbility(), "modifier_stunned", {duration=self.stun_duration})

        local damageTable = {
            victim = attacker,
            attacker = caster, 
            damage = original_damage / 100 * self.damage_reflect_pct,
            damage_type = damage_type,
            damage_flags = DOTA_DAMAGE_FLAG_REFLECTION + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL,
            ability = self:GetAbility()
        }

        ApplyDamage(damageTable) 

        return original_damage
    end
end