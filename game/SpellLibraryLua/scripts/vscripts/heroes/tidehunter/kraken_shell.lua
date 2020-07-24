LinkLuaModifier( "modifier_ability_tidehunter_kraken_shell", "heroes/tidehunter/kraken_shell" ,LUA_MODIFIER_MOTION_NONE )

if ability_tidehunter_kraken_shell == nil then
    ability_tidehunter_kraken_shell = class({})
end

--------------------------------------------------------------------------------

function ability_tidehunter_kraken_shell:GetIntrinsicModifierName()
    return "modifier_ability_tidehunter_kraken_shell"
end

--------------------------------------------------------------------------------


modifier_ability_tidehunter_kraken_shell = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
            MODIFIER_EVENT_ON_TAKEDAMAGE
        }
    end,
})


--------------------------------------------------------------------------------

function modifier_ability_tidehunter_kraken_shell:OnCreated()
    self.damage_reduction = self:GetAbility():GetSpecialValueFor("damage_reduction")
    self.damage_cleanse = self:GetAbility():GetSpecialValueFor("damage_cleanse")
    self.damage_reset_interval = self:GetAbility():GetSpecialValueFor("damage_reset_interval")

    self.reset_timer = GameRules:GetGameTime()

    self:StartIntervalThink(0.033)
end

function modifier_ability_tidehunter_kraken_shell:OnRefresh()
    self.damage_reduction = self:GetAbility():GetSpecialValueFor("damage_reduction")
    self.damage_cleanse = self:GetAbility():GetSpecialValueFor("damage_cleanse")
    self.damage_reset_interval = self:GetAbility():GetSpecialValueFor("damage_reset_interval")
end

function modifier_ability_tidehunter_kraken_shell:OnIntervalThink()
    local now_time = GameRules:GetGameTime()

    if now_time - self.reset_timer >= self.damage_reset_interval then
        self:SetStackCount(0)
        self.reset_timer = GameRules:GetGameTime()
    end
end

function modifier_ability_tidehunter_kraken_shell:GetModifierPhysical_ConstantBlock(k)
    local target = k.target
    local attacker = k.attacker
    local caster = self:GetCaster()
    if caster == target then
        return self.damage_reduction
    end
end

function modifier_ability_tidehunter_kraken_shell:OnTakeDamage(k)
    local attacker = k.attacker
    local target = k.unit
    local caster = self:GetCaster()

    if target == caster and not caster:PassivesDisabled() and not caster:IsIllusion() and not attacker:IsOther() and (attacker:GetOwnerEntity() or attacker.GetPlayerID) then
        self:SetStackCount(self:GetStackCount() + k.damage)

        self.reset_timer = GameRules:GetGameTime()

        if self:GetStackCount() >= self.damage_cleanse then
            caster:EmitSound("Hero_Tidehunter.KrakenShell")
            
            local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_tidehunter/tidehunter_krakenshell_purge.vpcf", PATTACH_ABSORIGIN, caster)
            ParticleManager:ReleaseParticleIndex(fx)
        
            caster:Purge(false, true, false, true, true)
            
            self:SetStackCount(0)
        end
    end
end