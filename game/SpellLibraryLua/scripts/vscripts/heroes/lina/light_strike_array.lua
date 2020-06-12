LinkLuaModifier( "modifier_ability_lina_light_strike_array", "heroes/lina/light_strike_array" ,LUA_MODIFIER_MOTION_NONE )

if ability_lina_light_strike_array == nil then
    ability_lina_light_strike_array = class({})
end

--------------------------------------------------------------------------------

function ability_lina_light_strike_array:OnSpellStart()
    local caster = self:GetCaster()
    self.position = self:GetCursorPosition()

    local delay = self:GetSpecialValueFor("light_strike_array_delay_time")

    caster:AddNewModifier(caster, self, "modifier_ability_lina_light_strike_array", {duration=delay})
end

function ability_lina_light_strike_array:GetAOERadius()
    return self:GetSpecialValueFor("light_strike_array_aoe")
end

--------------------------------------------------------------------------------


modifier_ability_lina_light_strike_array = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return false end,
    GetAttributes           = function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
})


--------------------------------------------------------------------------------

if IsServer() then
function modifier_ability_lina_light_strike_array:OnCreated()
    self.aoe = self:GetAbility():GetSpecialValueFor("light_strike_array_aoe")
    self.duration = self:GetAbility():GetSpecialValueFor("light_strike_array_stun_duration")
    self.damage = self:GetAbility():GetSpecialValueFor("light_strike_array_damage")

    self.pos = self:GetAbility().position

    EmitSoundOnLocationForAllies(self.pos, "Ability.PreLightStrikeArray", self:GetCaster())

    local part = "particles/units/heroes/hero_lina/lina_spell_light_strike_array_ray_team.vpcf"
    local fx = ParticleManager:CreateParticleForTeam(part, PATTACH_WORLDORIGIN, self:GetCaster(), self:GetCaster():GetTeamNumber())
    ParticleManager:SetParticleControl(fx, 0, self.pos)
    ParticleManager:SetParticleControl(fx, 1, Vector(self.aoe, 0, 0))
    ParticleManager:ReleaseParticleIndex(fx)
end

function modifier_ability_lina_light_strike_array:OnDestroy()
    local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_lina/lina_spell_light_strike_array.vpcf", PATTACH_CUSTOMORIGIN, self:GetCaster())
    ParticleManager:SetParticleControl(fx, 0, self.pos)
    ParticleManager:SetParticleControl(fx, 1, Vector(self.aoe, 0, 0))
    ParticleManager:ReleaseParticleIndex(fx)

    EmitSoundOnLocationWithCaster( self.pos, "Ability.LightStrikeArray", self:GetCaster() )

    local all = FindUnitsInRadius(self:GetCaster():GetTeam(), 
    self.pos, 
    nil, 
    self.aoe,
    DOTA_UNIT_TARGET_TEAM_ENEMY, 
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER, 
    false)

    GridNav:DestroyTreesAroundPoint(self.pos, self.aoe, false)

    for _, unit in ipairs(all) do
        ApplyDamage({
            victim = unit,
            attacker = self:GetCaster(),
            damage = self.damage,
            damage_type = self:GetAbility():GetAbilityDamageType(),
            ability = self:GetAbility()
        })

        unit:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_stunned", {duration=self.duration})
    end
end
end