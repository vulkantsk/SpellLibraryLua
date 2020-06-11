LinkLuaModifier( "modifier_ability_sven_gods_strength", "heroes/sven/gods_strength" ,LUA_MODIFIER_MOTION_NONE )

if ability_sven_gods_strength == nil then
    ability_sven_gods_strength = class({})
end

--------------------------------------------------------------------------------

function ability_sven_gods_strength:OnSpellStart()
    local caster = self:GetCaster()

    local duration = self:GetDuration()

    caster:AddNewModifier(caster, self, "modifier_ability_sven_gods_strength", {duration=duration})
    caster:EmitSound("Hero_Sven.GodsStrength")
    
    if caster:GetName() == "npc_dota_hero_sven" then
        caster:EmitSound("sven_sven_ability_godstrength_0"..math.random(1,2))
    end

    local part = "particles/units/heroes/hero_sven/sven_spell_gods_strength.vpcf"
    local fx = ParticleManager:CreateParticle(part, PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:ReleaseParticleIndex(fx)
    ScreenShake(caster:GetAbsOrigin(), 100, 100, 0.2, 900, 0, true)
end

--------------------------------------------------------------------------------


modifier_ability_sven_gods_strength = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND,
            MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS
        }
    end,
    GetAttackSound          = function(self) return "Hero_Sven.GodsStrength.Attack" end,
    GetHeroEffectName       = function(self) return "particles/units/heroes/hero_sven/sven_gods_strength_hero_effect.vpcf" end,
    HeroEffectPriority      = function(self) return 10 end,
    GetStatusEffectName     = function(self) return "particles/status_fx/status_effect_gods_strength.vpcf" end,
    StatusEffectPriority    = function(self) return 10 end,
})


--------------------------------------------------------------------------------

function modifier_ability_sven_gods_strength:OnRefresh()
    self:OnCreated()
end 

function modifier_ability_sven_gods_strength:OnCreated()
    self.gods_strength_bonus_str = self:GetAbility():GetSpecialValueFor("gods_strength_bonus_str")
    self.gods_strength_damage = self:GetAbility():GetSpecialValueFor("gods_strength_damage")

    if IsServer() then
        if not self.buff_fx then
            self.buff_fx = ParticleManager:CreateParticle( "particles/units/heroes/hero_sven/sven_spell_gods_strength_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
            ParticleManager:SetParticleControlEnt( self.buff_fx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_weapon" , self:GetParent():GetOrigin(), true )
            ParticleManager:SetParticleControlEnt( self.buff_fx, 2, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_head" , self:GetParent():GetOrigin(), true )
            self:AddParticle( self.buff_fx, false, false, -1, false, true )
        end
    end
end

if IsServer() then
function modifier_ability_sven_gods_strength:OnDestroy()
    ParticleManager:DestroyParticle(self.buff_fx, false)
    ParticleManager:ReleaseParticleIndex(self.buff_fx)
end
end

function modifier_ability_sven_gods_strength:GetModifierBaseDamageOutgoing_Percentage() return self.gods_strength_damage end
function modifier_ability_sven_gods_strength:GetModifierBonusStats_Strength() return self.gods_strength_bonus_str end
