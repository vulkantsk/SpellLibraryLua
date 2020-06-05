LinkLuaModifier( "modifier_ability_dispersion", "heroes/spectre/dispersion" ,LUA_MODIFIER_MOTION_NONE )

if ability_dispersion == nil then
    ability_dispersion = class({})
end

--------------------------------------------------------------------------------

function ability_dispersion:GetIntrinsicModifierName()
	return "modifier_ability_dispersion"
end

--------------------------------------------------------------------------------


modifier_ability_dispersion = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    AllowIllusionDuplicate  = function(self) return false end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_EVENT_ON_TAKEDAMAGE,
            MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
        }
    end,
})


--------------------------------------------------------------------------------

function modifier_ability_dispersion:OnTakeDamage(k)
    local target = k.unit
    local caster = self:GetParent()
    local original_damage = k.original_damage
    local damage_type = k.damage_type
    if target == caster and not caster:PassivesDisabled() then
	    local damage_reflection_pct = self:GetAbility():GetSpecialValueFor("damage_reflection_pct")
		local min_radius = self:GetAbility():GetSpecialValueFor("min_radius")
		local max_radius = self:GetAbility():GetSpecialValueFor("max_radius")

    	local all = FindUnitsInRadius(target:GetTeam(), 
        caster:GetOrigin(), 
        nil, 
        max_radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY, 
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        FIND_ANY_ORDER, 
        false)

        for _, hero in ipairs(all) do
            local part = ParticleManager:CreateParticle("particles/units/heroes/hero_spectre/spectre_dispersion.vpcf", PATTACH_CUSTOMORIGIN, hero)
            ParticleManager:SetParticleControl(part, 0, hero:GetAbsOrigin() + Vector(0,0,50))
            ParticleManager:SetParticleControl(part, 1, caster:GetAbsOrigin() + Vector(0,0,50))
            ParticleManager:SetParticleControl(part, 2, caster:GetAbsOrigin() + Vector(0,0,50))
            ParticleManager:ReleaseParticleIndex(part)

            local distance = (caster:GetAbsOrigin() - hero:GetAbsOrigin()):Length2D()
            local dif = distance - 300
            local reflect = distance <= min_radius and damage_reflection_pct or damage_reflection_pct - (0.0175 * dif)

            local damage = original_damage / 100 * reflect

            ApplyDamage({
                victim = hero,
                attacker = caster,
                damage = damage,
                damage_type = damage_type,
                damage_flags = DOTA_DAMAGE_FLAG_HPLOSS,
                ability = self:GetAbility()
            })
        end
    end
end

function modifier_ability_dispersion:GetModifierIncomingDamage_Percentage() return self:GetAbility():GetSpecialValueFor("damage_reflection_pct") * -1 end