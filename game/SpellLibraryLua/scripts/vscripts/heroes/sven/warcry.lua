LinkLuaModifier( "modifier_ability_sven_warcry", "heroes/sven/warcry" ,LUA_MODIFIER_MOTION_NONE )

if ability_sven_warcry == nil then
    ability_sven_warcry = class({})
end

--------------------------------------------------------------------------------

function ability_sven_warcry:OnSpellStart()
    local caster = self:GetCaster()

    local duration = self:GetSpecialValueFor("duration")
    local radius = self:GetSpecialValueFor("radius")

    local all = FindUnitsInRadius(caster:GetTeam(), 
    caster:GetAbsOrigin(), 
    nil, 
    radius,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY, 
    DOTA_UNIT_TARGET_HERO, 
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER, 
    false)

    for _, hero in ipairs(all) do
        hero:AddNewModifier(caster, self, "modifier_ability_sven_warcry", {duration=duration})
    end
    EmitSoundOn("Hero_Sven.WarCry", caster)

    if caster:GetName() == "npc_dota_hero_sven" then
        caster:EmitSound("sven_sven_ability_warcry_0"..math.random(1,9))
    end

    local part = "particles/units/heroes/hero_sven/sven_spell_warcry.vpcf"
    local fx = ParticleManager:CreateParticle(part, PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:ReleaseParticleIndex(fx)
    ScreenShake(caster:GetAbsOrigin(), 100, 100, 0.2, 900, 0, true)
end

--------------------------------------------------------------------------------


modifier_ability_sven_warcry = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return true end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
            MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
        }
    end,
})


--------------------------------------------------------------------------------

function modifier_ability_sven_warcry:OnRefresh()
    self:OnCreated()
end 

function modifier_ability_sven_warcry:OnCreated()
    self.movespeed = self:GetAbility():GetSpecialValueFor("movespeed")
    self.bonus_armor = self:GetAbility():GetSpecialValueFor("bonus_armor")
    self.bonus_damage = self:GetAbility():GetSpecialValueFor("bonus_damage")

    if not self.buff_fx then
        self.buff_fx = ParticleManager:CreateParticle("particles/units/heroes/hero_sven/sven_warcry_buff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
        ParticleManager:SetParticleControlEnt(self.buff_fx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, nil, self:GetParent():GetAbsOrigin(), true)
        ParticleManager:SetParticleControlEnt(self.buff_fx, 1, self:GetParent(), PATTACH_OVERHEAD_FOLLOW, nil, self:GetParent():GetAbsOrigin(), true)
        self:AddParticle(self.buff_fx, false, false, -1, false, false)
    end
end

function modifier_ability_sven_warcry:GetModifierPreAttack_BonusDamage() return self.bonus_damage end
function modifier_ability_sven_warcry:GetModifierPhysicalArmorBonus() return self.bonus_armor end

function modifier_ability_sven_warcry:GetModifierMoveSpeedBonus_Percentage() 
    if self:GetParent() == self:GetCaster() then
        return self.movespeed
    end
    return
end
