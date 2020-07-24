LinkLuaModifier( "modifier_ability_tidehunter_anchor_smash", "heroes/tidehunter/anchor_smash" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_tidehunter_anchor_smash_reduction", "heroes/tidehunter/anchor_smash" ,LUA_MODIFIER_MOTION_NONE )

if ability_tidehunter_anchor_smash == nil then
    ability_tidehunter_anchor_smash = class({})
end

--------------------------------------------------------------------------------

function ability_tidehunter_anchor_smash:OnSpellStart()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("reduction_duration")
    local radius = self:GetSpecialValueFor("radius")

    EmitSoundOn("Hero_Tidehunter.AnchorSmash", caster)

    local all = FindUnitsInRadius(caster:GetTeam(), 
    caster:GetOrigin(), 
    nil, 
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY, 
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER, 
    false)

    caster:AddNewModifier(caster, self, "modifier_ability_tidehunter_anchor_smash", {})

    for _, unit in ipairs(all) do
        unit:AddNewModifier(caster, self, "modifier_ability_tidehunter_anchor_smash_reduction", {duration=duration})

        caster:PerformAttack(unit, false, true, true, false, false, false, true)
    end

    caster:RemoveModifierByName("modifier_ability_tidehunter_anchor_smash")

    local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_tidehunter/tidehunter_anchor_hero.vpcf", PATTACH_ABSORIGIN, caster)
    ParticleManager:SetParticleControl(fx, 0, caster:GetAbsOrigin())
end

--------------------------------------------------------------------------------


modifier_ability_tidehunter_anchor_smash = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
            MODIFIER_PROPERTY_SUPPRESS_CLEAVE
        }
    end,
})


--------------------------------------------------------------------------------

function modifier_ability_tidehunter_anchor_smash:OnCreated()
    self.attack_damage = self:GetAbility():GetSpecialValueFor("attack_damage")
end

function modifier_ability_tidehunter_anchor_smash:OnRefresh()
    self:OnCreated()
end

function modifier_ability_tidehunter_anchor_smash:GetModifierPreAttack_BonusDamage() return self.attack_damage end
function modifier_ability_tidehunter_anchor_smash:GetSuppressCleave() return 1 end

--------------------------------------------------------------------------------


modifier_ability_tidehunter_anchor_smash_reduction = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return true end,
    IsPurgeException        = function(self) return true end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE
        }
    end,
})


--------------------------------------------------------------------------------

function modifier_ability_tidehunter_anchor_smash_reduction:OnCreated()
    self.damage_reduction = self:GetAbility():GetSpecialValueFor("damage_reduction")

    if IsServer() then
        self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_tidehunter/tidehunter_anchor.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
        ParticleManager:SetParticleControlEnt(self.fx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
        self:AddParticle(self.fx, false, false, -1, false, false)
    end
end

function modifier_ability_tidehunter_anchor_smash_reduction:OnRefresh()
    self:OnCreated()
end

function modifier_ability_tidehunter_anchor_smash_reduction:GetModifierBaseDamageOutgoing_Percentage() return self.damage_reduction end