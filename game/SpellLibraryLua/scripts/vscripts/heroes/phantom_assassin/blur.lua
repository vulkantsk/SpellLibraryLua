LinkLuaModifier( "modifier_ability_phantom_assassin_blur", "heroes/phantom_assassin/blur" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_phantom_assassin_blur_smoke", "heroes/phantom_assassin/blur" ,LUA_MODIFIER_MOTION_NONE )

if ability_phantom_assassin_blur == nil then
    ability_phantom_assassin_blur = class({})
end

--------------------------------------------------------------------------------

function ability_phantom_assassin_blur:OnSpellStart()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")

    ProjectileManager:ProjectileDodge(caster)

    EmitSoundOn("Hero_PhantomAssassin.Blur", caster)

    caster:AddNewModifier(caster, self, "modifier_ability_phantom_assassin_blur_smoke", {duration=duration})
end

function ability_phantom_assassin_blur:GetIntrinsicModifierName()
    return "modifier_ability_phantom_assassin_blur"
end

--------------------------------------------------------------------------------


modifier_ability_phantom_assassin_blur_smoke = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    CheckState              = function(self)
        return {
            [MODIFIER_STATE_INVISIBLE] = true,
            [MODIFIER_STATE_TRUESIGHT_IMMUNE] = true
        }
    end,
    GetPriority             = function(self) return MODIFIER_PRIORITY_SUPER_ULTRA end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
            MODIFIER_EVENT_ON_ATTACK_LANDED
        }
    end,
    GetEffectName           = function(self) return "particles/units/heroes/hero_phantom_assassin/phantom_assassin_active_blur.vpcf" end,
    GetEffectAttachType     = function(self) return PATTACH_ABSORIGIN_FOLLOW end,
})


--------------------------------------------------------------------------------

if IsServer() then
function modifier_ability_phantom_assassin_blur_smoke:OnCreated()
    self.radius = self:GetAbility():GetSpecialValueFor("radius")
    self.fade_duration = self:GetAbility():GetSpecialValueFor("fade_duration")

    self.find = false

    self:StartIntervalThink(0.03)
end

function modifier_ability_phantom_assassin_blur_smoke:OnIntervalThink()
    if self.find == true then return end

    local all = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), 
    self:GetParent():GetAbsOrigin(), 
    nil, 
    self.radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY, 
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BUILDING, 
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD + DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO + DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS,
    FIND_ANY_ORDER, 
    false)

    if #all > 0 then
        self.find = true

        self:StartIntervalThink(-1)

        self:SetDuration(math.min(self.fade_duration, self:GetRemainingTime()), false)
    end
end

function modifier_ability_phantom_assassin_blur_smoke:OnDestroy()
    EmitSoundOn("Hero_PhantomAssassin.Blur.Break", self:GetParent())
end

function modifier_ability_phantom_assassin_blur_smoke:OnAttackLanded(keys)
    if keys.attacker == self:GetParent() and keys.target:IsRoshan() then
        self:SetDuration(math.min(self.fade_duration, self:GetRemainingTime()), true)
    end
end
end

function modifier_ability_phantom_assassin_blur_smoke:GetModifierInvisibilityLevel() return 1 end

--------------------------------------------------------------------------------


modifier_ability_phantom_assassin_blur = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_EVASION_CONSTANT,
        }
    end,
})


--------------------------------------------------------------------------------

function modifier_ability_phantom_assassin_blur:OnCreated()
    self.bonus_evasion = self:GetAbility():GetSpecialValueFor("bonus_evasion")
end

function modifier_ability_phantom_assassin_blur:OnRefresh()
    self:OnCreated()
end

function modifier_ability_phantom_assassin_blur:GetModifierEvasion_Constant() if not self:GetCaster():PassivesDisabled() then return self.bonus_evasion end return end