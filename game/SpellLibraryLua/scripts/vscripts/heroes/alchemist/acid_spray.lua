ability_acid_spray = class({})
LinkLuaModifier('modifier_acid_spray_lua_debuff', 'heroes/alchemist/acid_spray', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('modifier_acid_spray_lua_aura', 'heroes/alchemist/acid_spray', LUA_MODIFIER_MOTION_NONE)
function ability_acid_spray:OnSpellStart()
    local nfx = ParticleManager:CreateParticle('particles/units/heroes/hero_alchemist/alchemist_acid_spray_cast.vpcf', PATTACH_ABSORIGIN, self:GetCaster())

    ParticleManager:ReleaseParticleIndex(nfx)
    local modifier = CreateModifierThinker(self:GetCaster(), self, 'modifier_acid_spray_lua_aura', {duration = self:GetSpecialValueFor('duration')}, self:GetCursorPosition(), self:GetCaster():GetTeam(), false)
end
function ability_acid_spray:GetAOERadius() return self:GetSpecialValueFor("radius") end
modifier_acid_spray_lua_aura = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return false end,
    AllowIllusionDuplicate  = function(self) return false end,
    IsPermanent             = function(self) return true end,
    IsAura                  = function(self) return true end,
    GetAuraRadius           = function(self) return self.radius end,
    GetAuraSearchTeam       = function(self) return DOTA_UNIT_TARGET_TEAM_ENEMY end,
    GetAuraSearchFlags      = function(self) return DOTA_UNIT_TARGET_FLAG_NONE end,
    GetAuraSearchType       = function(self) return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP end,
    GetModifierAura         = function(self) return 'modifier_acid_spray_lua_debuff' end,
})

function modifier_acid_spray_lua_aura:OnCreated(table)
    local ability = self:GetAbility()
    self.radius = ability:GetSpecialValueFor('radius')
    if IsClient() then return end
    self.nfx = ParticleManager:CreateParticle('particles/units/heroes/hero_alchemist/alchemist_acid_spray.vpcf', PATTACH_ABSORIGIN, self:GetParent())
    ParticleManager:SetParticleControl(self.nfx, 0, self:GetParent():GetOrigin())
    ParticleManager:SetParticleControl(self.nfx, 1, Vector(self.radius,1,self.radius))
    self:GetParent():EmitSound('Hero_Alchemist.AcidSpray')
end

function modifier_acid_spray_lua_aura:OnDestroy()
    if self.nfx then 
        ParticleManager:DestroyParticle(self.nfx, true)
        ParticleManager:ReleaseParticleIndex(self.nfx)
    end
end

modifier_acid_spray_lua_debuff = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    AllowIllusionDuplicate  = function(self) return false end, 
    DeclareFunctions        = function(self) return {MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS} end,
    GetModifierPhysicalArmorBonus  = function(self) return self.armor_reduction end,
})


function modifier_acid_spray_lua_debuff:OnCreated()
    local ability = self:GetAbility()
    self.armor_reduction = ability:GetSpecialValueFor('armor_reduction') * -1
    self.damage = ability:GetSpecialValueFor('damage')
    self:StartIntervalThink(ability:GetSpecialValueFor('tick_rate'))
end

function modifier_acid_spray_lua_debuff:OnIntervalThink() 
    if IsClient() then return end 
    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = self.damage,
        damage_type = DAMAGE_TYPE_PHYSICAL,
        ability = self:GetAbility(),
    })
end 