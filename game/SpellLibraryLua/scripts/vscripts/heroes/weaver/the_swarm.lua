LinkLuaModifier("modifier_the_swarm_beetle", "heroes/weaver/the_swarm", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_the_swarm_debuff", "heroes/weaver/the_swarm", LUA_MODIFIER_MOTION_NONE)

ability_the_swarm = class({})

function ability_the_swarm:OnSpellStart()
    if(not IsServer()) then
        return
    end
    self.caster = self:GetCaster()
    local cursor_position = self:GetCursorPosition()
    local caster_position = self.caster:GetAbsOrigin()
    self.caster_team = self.caster:GetTeamNumber()
    if cursor_position == caster_position then
        self.caster:SetCursorPosition(cursor_position + self.caster:GetForwardVector())
    end
    self.caster:EmitSound("Hero_Weaver.Swarm.Cast")
    if RollPercentage(75) then
        self.caster:EmitSound("weaver_weav_ability_swarm_0" .. RandomInt(1, 6))
    end
    local start_position, projectile, projectile_id
    local speed = self:GetSpecialValueFor("speed")
    for beetles = 1, self:GetSpecialValueFor("count") do
        local thinker = CreateModifierThinker(
                self.caster,
                self,
                nil,
                {},
                caster_position,
                self.caster_team,
                false)
        start_position = caster_position + RandomVector(RandomInt(0, self:GetSpecialValueFor("spawn_radius")))
        projectile = {
            Ability = self,
            EffectName = "particles/units/heroes/hero_weaver/weaver_swarm_projectile.vpcf",
            vSpawnOrigin = start_position,
            fDistance = (speed * self:GetSpecialValueFor("travel_time")) + self.caster:GetCastRangeBonus(),
            fStartRadius = self.radius,
            fEndRadius = self.radius,
            Source = self.caster,
            bHasFrontalCone = false,
            bReplaceExisting = false,
            iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
            iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NO_INVIS,
            iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            fExpireTime = GameRules:GetGameTime() + 10.0,
            bDeleteOnHit = false,
            vVelocity = (cursor_position - caster_position):Normalized() * speed * Vector(1, 1, 0),
            bProvidesVision = true,
            iVisionRadius = 321,
            iVisionTeamNumber = self.caster_team,
            ExtraData = {
                thinker_index = thinker:entindex()
            }
        }
        if (beetles == 1) then
            thinker:EmitSound("Hero_Weaver.Swarm.Projectile")
        end
        projectile_id = ProjectileManager:CreateLinearProjectile(projectile)
        thinker.projectile_id = projectile_id
    end
end

function ability_the_swarm:OnProjectileThink_ExtraData(location, data)
    if(not IsServer()) then
        return
    end
    local thinker = EntIndexToHScript(data.thinker_index)
    if (thinker and not thinker:IsNull()) then
        thinker:SetAbsOrigin(location)
    end
end

function ability_the_swarm:OnProjectileHit_ExtraData(target, location, data)
    if(not IsServer()) then
        return
    end
    local thinker = EntIndexToHScript(data.thinker_index)
    if (target) then
        if (not target:HasModifier("modifier_the_swarm_debuff")) then
            target:EmitSound("Hero_Weaver.SwarmAttach")
            local target_position = target:GetAbsOrigin()
            local beetle = CreateUnitByName(
                    "npc_dota_weaver_swarm",
                    target_position + target:GetForwardVector() * 64,
                    false,
                    self.caster,
                    self.caster,
                    self.caster_team
            )
            beetle:AddNewModifier(
                    self.caster,
                    self,
                    "modifier_the_swarm_beetle",
                    {
                        target_entindex = target:entindex()
                    }
            )
            target:AddNewModifier(
                    self.caster,
                    self,
                    "modifier_the_swarm_debuff",
                    {
                        beetle_entindex = beetle:entindex(),
                        duration = self:GetSpecialValueFor("duration")
                    }
            )
            beetle:SetForwardVector((target_position - beetle:GetAbsOrigin()):Normalized())
            ProjectileManager:DestroyLinearProjectile(thinker.projectile_id)
            thinker:StopSound("Hero_Weaver.Swarm.Projectile")
            UTIL_Remove(thinker)
        end
    else
        thinker:StopSound("Hero_Weaver.Swarm.Projectile")
        UTIL_Remove(thinker)
    end
end

modifier_the_swarm_beetle = class({
    IsHidden = function()
        return true
    end,
    IsPurgable = function()
        return false
    end,
    DeclareFunctions = function()
        return
        {
            MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
            MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
            MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
            MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
            MODIFIER_EVENT_ON_ATTACKED
        }
    end,
    CheckState = function()
        return {
            [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
            [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        }
    end,
    GetAbsoluteNoDamagePhysical = function()
        return 1
    end,
    GetAbsoluteNoDamageMagical = function()
        return 1
    end,
    GetAbsoluteNoDamagePure = function()
        return 1
    end,
    GetOverrideAnimation = function()
        return ACT_DOTA_IDLE
    end,
    GetAttributes = function()
        return MODIFIER_ATTRIBUTE_PERMANENT
    end,
})

function modifier_the_swarm_beetle:OnCreated(params)
    if(not IsServer()) then
        return
    end
    self.target = EntIndexToHScript(params.target_entindex)
    self.beetle = self:GetParent()
    self.ability = self:GetAbility()
    self.health_increments = self.beetle:GetMaxHealth() / self.ability:GetSpecialValueFor("destroy_attacks")
    self.hero_attack_multiplier = self.ability:GetSpecialValueFor("hero_attack_multiplier")
    self:StartIntervalThink(FrameTime())
end

function modifier_the_swarm_beetle:OnIntervalThink()
    if (self.target and not self.target:IsNull()) then
        if (self.target:IsInvisible() and not self.beetle:CanEntityBeSeenByMyTeam(self.target)) or self.beetle:HasModifier("modifier_faceless_void_chronosphere_freeze") then
            self.beetle:ForceKill(false)
            self:Destroy()
        elseif self.target:IsAlive() then
            local target_position = self.target:GetAbsOrigin()
            self.beetle:SetAbsOrigin(target_position + self.target:GetForwardVector() * 64)
            self.beetle:SetForwardVector((target_position - self.beetle:GetAbsOrigin()):Normalized())
        end
    end
end

function modifier_the_swarm_beetle:OnDestroy()
    if self.target and not self.target:IsNull() and self.target:HasModifier("modifier_the_swarm_debuff") then
        self.target:RemoveModifierByName("modifier_the_swarm_debuff")
    end
end

function modifier_the_swarm_beetle:OnAttacked(keys)
    if (keys.target == self.beetle) then
        local newBeetleHp = self.beetle:GetHealth()
        if (keys.attacker:IsHero()) then
            newBeetleHp = newBeetleHp - (self.health_increments * self.hero_attack_multiplier)
        else
            newBeetleHp = newBeetleHp - self.health_increments
        end
        self.beetle:SetHealth(newBeetleHp)
        if (newBeetleHp <= 0) then
            self.beetle:Kill(nil, keys.attacker)
            self:Destroy()
        end
    end
end

modifier_the_swarm_debuff = class({
    IsHidden = function()
        return false
    end,
    IsDebuff = function()
        return true
    end,
    IsPurgable = function()
        return false
    end,
    GetEffectName = function()
        return "particles/units/heroes/hero_weaver/weaver_swarm_infected_debuff.vpcf"
    end,
    DeclareFunctions = function()
        return {
            MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
        }
    end
})

function modifier_the_swarm_debuff:OnCreated(params)
    self.ability = self:GetAbility()
    self.armor_reduction = self.ability:GetSpecialValueFor("armor_reduction") * (-1)
    if(not IsServer()) then
        return
    end
    self.beetle = EntIndexToHScript(params.beetle_entindex)
    self.damage_table = {
        victim = self:GetParent(),
        damage = self.ability:GetSpecialValueFor("damage"),
        damage_type = self.ability:GetAbilityDamageType(),
        damage_flags = DOTA_DAMAGE_FLAG_NONE,
        attacker = self.ability.caster,
        ability = self.ability
    }
    self:OnIntervalThink()
    self:StartIntervalThink(self.ability:GetSpecialValueFor("attack_rate"))
end

function modifier_the_swarm_debuff:OnIntervalThink()
    self:IncrementStackCount()
    ApplyDamage(self.damage_table)
end

function modifier_the_swarm_debuff:OnDestroy()
    if (self.beetle and not self.beetle:IsNull() and self.beetle:IsAlive()) then
        self.beetle:ForceKill(false)
    end
end

function modifier_the_swarm_debuff:GetModifierPhysicalArmorBonus()
    return self.armor_reduction * self:GetStackCount()
end