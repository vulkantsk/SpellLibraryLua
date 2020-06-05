LinkLuaModifier( "modifier_ability_desolate_lua", "heroes/spectre/desolate" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_desolate_debuff_lua", "heroes/spectre/desolate" ,LUA_MODIFIER_MOTION_NONE )

if ability_desolate == nil then
    ability_desolate = class({})
end

--------------------------------------------------------------------------------

function ability_desolate:GetIntrinsicModifierName()
	return "modifier_ability_desolate_lua"
end

--------------------------------------------------------------------------------


modifier_ability_desolate_lua = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_EVENT_ON_ATTACK,
        }
    end,
})


--------------------------------------------------------------------------------

function modifier_ability_desolate_lua:OnAttack(k)
    local attacker = k.attacker
    local target = k.target
    local caster = self:GetParent()
    if attacker == caster and not caster:PassivesDisabled() then
	    local bonus_damage = self:GetAbility():GetSpecialValueFor("bonus_damage")
		local radius = self:GetAbility():GetSpecialValueFor("radius")
		local blind_duration = self:GetAbility():GetSpecialValueFor("blind_duration")

    	local all = FindUnitsInRadius(target:GetTeam(), 
        caster:GetOrigin(), 
        nil, 
        radius,
        DOTA_UNIT_TARGET_TEAM_FRIENDLY, 
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 
        DOTA_UNIT_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES,
        FIND_ANY_ORDER, 
        false)

        if #all == 1 and all[1] == target then
            EmitSoundOn("Hero_Spectre.Desolate", attacker)

            local part = ParticleManager:CreateParticle("particles/units/heroes/hero_spectre/spectre_desolate.vpcf", PATTACH_CUSTOMORIGIN, target)
            ParticleManager:SetParticleControl(part, 0, target:GetAbsOrigin() + Vector(0,0,50))
            ParticleManager:SetParticleControlForward(part, 0, caster:GetForwardVector())
            ParticleManager:ReleaseParticleIndex(part)

            target:AddNewModifier(caster, self:GetAbility(), "modifier_ability_desolate_debuff_lua", {Duration=blind_duration})

            ApplyDamage({
                victim = target,
                attacker = caster,
                damage = bonus_damage,
                damage_type = self:GetAbility():GetAbilityDamageType(),
                ability = self:GetAbility()
            })
        end
    end
end

--------------------------------------------------------------------------------


modifier_ability_desolate_debuff_lua = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return true end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_BONUS_VISION_PERCENTAGE,
        }
    end,

    GetEffectName           = function(self) return "particles/units/heroes/hero_spectre/spectre_desolate_debuff.vpcf" end,
    GetEffectAttachType     = function(self) return PATTACH_ABSORIGIN_FOLLOW end,
})


--------------------------------------------------------------------------------

function modifier_ability_desolate_debuff_lua:OnCreated()
	self.blind_pct = self:GetAbility():GetSpecialValueFor("blind_pct")
end

function modifier_ability_desolate_debuff_lua:GetBonusVisionPercentage() return self.blind_pct * -1 end