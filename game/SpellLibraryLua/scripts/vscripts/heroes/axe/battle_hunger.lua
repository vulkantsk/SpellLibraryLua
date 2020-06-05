ability_battle_hunger = class({})

function ability_battle_hunger:OnAbilityPhaseStart()
	local cast_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_battle_hunger_cast.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControlEnt(cast_particle, 0, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_attack1", self:GetCaster():GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(cast_particle)

	return true
end

-- original Dota Imba
-- https://github.com/EarthSalamander42/dota_imba/blob/master/game/dota_addons/dota_imba_reborn/scripts/vscripts/components/abilities/heroes/hero_axe.lua
--

LinkLuaModifier('modifier_ability_battle_hunger_haste', 'heroes/axe/battle_hunger', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('modifier_imba_battle_hunger_debuff_dot', 'heroes/axe/battle_hunger', LUA_MODIFIER_MOTION_NONE)

function ability_battle_hunger:OnSpellStart()
	local caster                    =       self:GetCaster()
	local target                    =       self:GetCursorTarget()
	local ability                   =       self
	
	caster:EmitSound("axe_axe_ability_battlehunger_0"..RandomInt(1,3))
    if target:GetTeamNumber() ~= caster:GetTeamNumber() then
        if target:TriggerSpellAbsorb(ability) then
            return nil
        end
    end
    target:EmitSound("Hero_Axe.Battle_Hunger")

	local duration = self:GetSpecialValueFor("duration")
    if not self:GetCursorTarget():HasModifier('modifier_imba_battle_hunger_debuff_dot') then 
        self:GetCaster():AddStackModifier({
            ability = self,
            modifier = "modifier_ability_battle_hunger_haste",
            duration = duration,
            updateStack = true,
            count = self:GetSpecialValueFor("speed_bonus"),
            caster = self:GetCaster(),
        })
    end
    self:GetCursorTarget():AddNewModifier(self:GetCaster(), self, 'modifier_imba_battle_hunger_debuff_dot', {
        duration = duration,
    })

end

modifier_ability_battle_hunger_haste = class({})

function modifier_ability_battle_hunger_haste:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
end

function modifier_ability_battle_hunger_haste:GetModifierMoveSpeedBonus_Percentage()
	return self:GetStackCount()
end

function modifier_ability_battle_hunger_haste:IsHidden()
	return false
end

function modifier_ability_battle_hunger_haste:IsPurgable()
	return false
end

modifier_imba_battle_hunger_debuff_dot = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return true end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    AllowIllusionDuplicate  = function(self) return true end,
    DeclareFunctions        = function(self) return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    } end,
    GetModifierMoveSpeedBonus_Percentage = function(self) return self.reduction_movespeed end,

    GetEffectName           = function(self) return 'particles/units/heroes/hero_axe/axe_battle_hunger.vpcf' end,
    GetEffectAttachType     = function(self) return PATTACH_OVERHEAD_FOLLOW end,
})

function modifier_imba_battle_hunger_debuff_dot:OnRefresh()
    self.reduction_movespeed = self:GetAbility():GetSpecialValueFor('slow')
    self.damage = self:GetAbility():GetSpecialValueFor('damage_per_second')
end 

function modifier_imba_battle_hunger_debuff_dot:OnCreated()
    self.reduction_movespeed = self:GetAbility():GetSpecialValueFor('slow')
    self.damage = self:GetAbility():GetSpecialValueFor('damage_per_second')

    self:StartIntervalThink(1)
end 

function modifier_imba_battle_hunger_debuff_dot:OnIntervalThink()
    if IsClient() then return end

    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = self.damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility(),
    })
end 