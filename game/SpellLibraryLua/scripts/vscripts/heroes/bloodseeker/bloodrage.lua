LinkLuaModifier( "modifier_ability_bloodseeker_bloodrage", "heroes/bloodseeker/bloodseeker_bloodrage" ,LUA_MODIFIER_MOTION_NONE )

if ability_bloodseeker_bloodrage == nil then
    ability_bloodseeker_bloodrage = class({})
end

--------------------------------------------------------------------------------

function ability_bloodseeker_bloodrage:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    if target:TriggerSpellAbsorb(self) then return end

    local duration = self:GetSpecialValueFor("duration")

    target:AddNewModifier(caster, self, "modifier_ability_bloodseeker_bloodrage", {duration=duration})
    
    caster:EmitSound("hero_bloodseeker.bloodRage")
end

--------------------------------------------------------------------------------


modifier_ability_bloodseeker_bloodrage = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
            MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
            MODIFIER_EVENT_ON_DEATH
        }
    end,
    GetEffectName           = function(self) return "particles/units/heroes/hero_bloodseeker/bloodseeker_bloodrage.vpcf" end,
    GetEffectAttachType     = function(self) return PATTACH_ABSORIGIN_FOLLOW end,
    GetStatusEffectName     = function(self) return "particles/status_fx/status_effect_bloodrage.vpcf" end,
    StatusEffectPriority    = function(self) return 8 end,
})


--------------------------------------------------------------------------------

function modifier_ability_bloodseeker_bloodrage:OnRefresh()
    self:OnCreated()
end 

function modifier_ability_bloodseeker_bloodrage:OnCreated()
    self.damage_increase_outgoing_pct = self:GetAbility():GetSpecialValueFor("damage_increase_outgoing_pct")
    self.damage_increase_incoming_pct = self:GetAbility():GetSpecialValueFor("damage_increase_incoming_pct")
    self.health_bonus_pct = self:GetAbility():GetSpecialValueFor("health_bonus_pct")
    self.health_bonus_creep_pct = self:GetAbility():GetSpecialValueFor("health_bonus_creep_pct")
    self.health_bonus_aoe = self:GetAbility():GetSpecialValueFor("health_bonus_aoe")
    self.health_bonus_share_percent = self:GetAbility():GetSpecialValueFor("health_bonus_share_percent")
end

function modifier_ability_bloodseeker_bloodrage:OnDeath(k)
    local parent = self:GetParent()
    local unit = k.unit
    local attacker = k.attacker

    local pct = self.health_bonus_pct
    if not unit:IsHero() then
        pct = self.health_bonus_creep_pct
    end

    local UnitMaxHealth = unit:GetMaxHealth()
    local Heal = UnitMaxHealth / 100 * pct

    local distance = (unit:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D()

    if not unit:IsIllusion() and not unit:IsTempestDouble() and not unit:IsBuilding() and not unit:IsOther() then
        if attacker == parent then
            parent:Heal(Heal, parent)

            SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, parent, Heal, nil)

            local p = "particles/units/heroes/hero_bloodseeker/bloodseeker_bloodbath.vpcf"
            local part = ParticleManager:CreateParticle(p, PATTACH_ABSORIGIN_FOLLOW, parent)
            ParticleManager:ReleaseParticleIndex(part)

        elseif attacker ~= parent and distance <= self.health_bonus_aoe then
            Heal = Heal / 100 * self.health_bonus_share_percent
            parent:Heal(Heal, parent)

            SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, parent, Heal, nil)

            local p = "particles/units/heroes/hero_bloodseeker/bloodseeker_bloodbath.vpcf"
            local part = ParticleManager:CreateParticle(p, PATTACH_ABSORIGIN_FOLLOW, parent)
            ParticleManager:ReleaseParticleIndex(part)
        end
    end
end

function modifier_ability_bloodseeker_bloodrage:GetModifierTotalDamageOutgoing_Percentage() return self.damage_increase_outgoing_pct end
function modifier_ability_bloodseeker_bloodrage:GetModifierIncomingDamage_Percentage() return self.damage_increase_incoming_pct end

function modifier_ability_bloodseeker_bloodrage:IsDebuff()
    if self:GetParent():GetTeamNumber() == self:GetCaster():GetTeamNumber() then
        return false
    end
    return true
end
