ability_berserkers_call = class({})
LinkLuaModifier('modifier_ability_berserkers_call_debuff_cmd', 'heroes/axe/berserkers_call', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('modifier_ability_berserkers_call_buff_armor', 'heroes/axe/berserkers_call', LUA_MODIFIER_MOTION_NONE)
function ability_berserkers_call:OnAbilityPhaseStart()
	if IsServer() then
		EmitSoundOn("Hero_Axe.BerserkersCall.Start", self:GetCaster())
	end

	return true
end
-- original Dota Imba
-- https://github.com/EarthSalamander42/dota_imba/blob/master/game/dota_addons/dota_imba_reborn/scripts/vscripts/components/abilities/heroes/hero_axe.lua
--
function ability_berserkers_call:OnSpellStart()
	local caster                    =       self:GetCaster()
	local ability                   =       self
    local duration                  =       ability:GetSpecialValueFor("duration")
	-- Ability specials
	local radius                    =      ability:GetSpecialValueFor("radius")
	self:GetCaster():EmitSound("Hero_Axe.Berserkers_Call")

	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_beserkers_call_owner.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 2, Vector(radius, radius, radius))
	ParticleManager:ReleaseParticleIndex(particle)

	-- find targets
	local enemies_in_radius = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	for _,target in pairs(enemies_in_radius) do
		if target:IsCreep() then
			target:SetForceAttackTarget(caster)
			target:MoveToTargetToAttack(caster)
		else
			target:Stop()
			target:Interrupt()
			ExecuteOrderFromTable({
                UnitIndex = target:entindex(),
                OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
                TargetIndex = caster:entindex()
            })
		end
		self:AddCalledTarget(target)
		target:AddNewModifier(caster, self, "modifier_ability_berserkers_call_debuff_cmd", {duration = duration})
	end

	-- if enemies table is empty play random responses_zero_enemy
	if #enemies_in_radius == 0 then
		self:GetCaster():EmitSound("axe_axe_anger_0"..RandomInt(1,3))
	else
		self:GetCaster():EmitSound("axe_axe_ability_berserk_0"..RandomInt(1,9))
	end

	caster:AddNewModifier(caster, self, "modifier_ability_berserkers_call_buff_armor", {duration = duration})

end

function ability_berserkers_call:AddCalledTarget(target)
	if not self.called_targets then
		self.called_targets = {}
	end

	self.called_targets[target:entindex()] = target
end

function ability_berserkers_call:RemoveCalledTarget(target)
	if not self.called_targets then
		return nil
	end

	self.called_targets[target:entindex()] = nil
end

function ability_berserkers_call:GetCalledUnits()
	if not self.called_targets then
		return nil
	end

	return self.called_targets
end

modifier_ability_berserkers_call_buff_armor = class({})
function modifier_ability_berserkers_call_buff_armor:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
	}
end

function modifier_ability_berserkers_call_buff_armor:GetModifierPhysicalArmorBonus()
	return self:GetStackCount()
end

function modifier_ability_berserkers_call_buff_armor:OnCreated()
	if not IsServer() then return end

	local caster_particle = ParticleManager:CreateParticle( "particles/units/heroes/hero_axe/axe_beserkers_call_owner.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControl(caster_particle, 2, Vector(0, 0, 0))
    ParticleManager:ReleaseParticleIndex(caster_particle)
    self:SetStackCount(self:GetAbility():GetSpecialValueFor( "bonus_armor"))
	return true
end

function modifier_ability_berserkers_call_buff_armor:IsPurgable()
	return false
end

function modifier_ability_berserkers_call_buff_armor:IsBuff()
	return true
end

function modifier_ability_berserkers_call_buff_armor:RemoveOnDeath()
	return true
end

-------------------------------------------
-- Berserker's Call enemy modifier
-------------------------------------------

modifier_ability_berserkers_call_debuff_cmd = class({})


function modifier_ability_berserkers_call_debuff_cmd:CheckState()
	return {[MODIFIER_STATE_COMMAND_RESTRICTED] = true}
end

function modifier_ability_berserkers_call_debuff_cmd:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH
	}
end

function modifier_ability_berserkers_call_debuff_cmd:OnDeath(event)
	if IsServer() then
		-- If Axe dies, remove this modifier.
		if event.unit == self:GetCaster() then
			self:Destroy()
		end

	end
end
function modifier_ability_berserkers_call_debuff_cmd:OnDestroy()
	if IsServer() then
		local caster = self:GetCaster()
		local parent = self:GetParent()
		local ability = self:GetAbility()

		if parent:IsCreep() then
			parent:SetForceAttackTarget(nil)
		end

		if ability and ability.RemoveCalledTarget then
			ability:RemoveCalledTarget(parent)
		end
	end
end

function modifier_ability_berserkers_call_debuff_cmd:GetStatusEffectName()
	return "particles/status_fx/status_effect_beserkers_call.vpcf"
end

function modifier_ability_berserkers_call_debuff_cmd:StatusEffectPriority()
	return 10
end

function modifier_ability_berserkers_call_debuff_cmd:IsHidden()
	return false
end

function modifier_ability_berserkers_call_debuff_cmd:IsDebuff()
	return true
end

function modifier_ability_berserkers_call_debuff_cmd:IsPurgable()
	return false
end