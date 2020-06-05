LinkLuaModifier( "modifier_ability_vengefulspirit_wave_of_terror", "heroes/vengefulspirit/ability_vengefulspirit_wave_of_terror" ,LUA_MODIFIER_MOTION_NONE )

if ability_vengefulspirit_wave_of_terror == nil then
    ability_vengefulspirit_wave_of_terror = class({})
end

--------------------------------------------------------------------------------

function ability_vengefulspirit_wave_of_terror:OnSpellStart()
    local caster = self:GetCaster()
    local position = self:GetCursorPosition()
    local direction = (position - caster:GetAbsOrigin()):Normalized()

    local speed = self:GetSpecialValueFor("wave_speed")
    local width = self:GetSpecialValueFor("wave_width")
    self.vision_aoe = self:GetSpecialValueFor("vision_aoe")
    self.vision_duration = self:GetSpecialValueFor("vision_duration")

    caster:EmitSound("Hero_VengefulSpirit.WaveOfTerror")

    local proj = "particles/units/heroes/hero_vengeful/vengeful_wave_of_terror.vpcf"

    local info = {
        Ability = self,
        EffectName = proj,
        vSpawnOrigin = caster:GetAbsOrigin(),
        fDistance = 1400,
        fStartRadius = width,
        fEndRadius = width,
        Source = caster,
        bHasFrontalCone = false,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        bDeleteOnHit = false,
        vVelocity = direction * speed,
        bProvidesVision = true,
        iVisionRadius = self.vision_aoe,
        iVisionTeamNumber = caster:GetTeamNumber(),
    }

    ProjectileManager:CreateLinearProjectile( info )
end

function ability_vengefulspirit_wave_of_terror:OnProjectileHit(Target, Location)
    if Target ~= nil and not Target:IsInvulnerable() then
        local damage = self:GetAbilityDamage()
        local armor_reduction_duration = self:GetDuration()

        ApplyDamage({
            victim = Target,
            attacker = self:GetCaster(),
            damage = damage,
            damage_type = self:GetAbilityDamageType(),
            ability = self
        })

        Target:AddNewModifier(self:GetCaster(), self, "modifier_ability_vengefulspirit_wave_of_terror", {duration=armor_reduction_duration})
    end
    return false
end

function ability_vengefulspirit_wave_of_terror:OnProjectileThink(vLocation)
    local caster = self:GetCaster()

    AddFOWViewer(caster:GetTeamNumber(), vLocation, self.vision_aoe, self.vision_duration, false)
end

--------------------------------------------------------------------------------


modifier_ability_vengefulspirit_wave_of_terror = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return true end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
        }
    end,
    GetEffectName           = function(self) return "particles/units/heroes/hero_vengeful/vengeful_wave_of_terror_recipient.vpcf" end,
    GetEffectAttachType     = function(self) return PATTACH_POINT_FOLLOW end,
})


--------------------------------------------------------------------------------

function modifier_ability_vengefulspirit_wave_of_terror:OnCreated()
    self.armor_reduction = self:GetAbility():GetSpecialValueFor("armor_reduction")
end

function modifier_ability_vengefulspirit_wave_of_terror:GetModifierPhysicalArmorBonus() return self.armor_reduction end