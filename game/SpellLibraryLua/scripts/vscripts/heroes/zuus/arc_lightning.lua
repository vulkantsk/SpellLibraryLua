LinkLuaModifier( "modifier_ability_zuus_arc_lightning", "heroes/zuus/arc_lightning" ,LUA_MODIFIER_MOTION_NONE )

if ability_zuus_arc_lightning == nil then
    ability_zuus_arc_lightning = class({})
end

--------------------------------------------------------------------------------

function ability_zuus_arc_lightning:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    if target:TriggerSpellAbsorb(self) then return end

    EmitSoundOn("Hero_Zuus.ArcLightning.Cast", caster)
    
    caster:AddNewModifier(caster, self, "modifier_ability_zuus_arc_lightning", {
        starting_unit_entindex  = target:entindex()
    })
end

--------------------------------------------------------------------------------


modifier_ability_zuus_arc_lightning = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return false end,
    GetAttributes           = function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
})


--------------------------------------------------------------------------------

if IsServer() then
function modifier_ability_zuus_arc_lightning:OnCreated(kv)
    self.delay = self:GetAbility():GetSpecialValueFor("jump_delay")
    self.jump_count = self:GetAbility():GetSpecialValueFor("jump_count")
    self.radius = self:GetAbility():GetSpecialValueFor("radius")
    self.damage = self:GetAbility():GetSpecialValueFor("arc_damage")

    self.count = 0
    self.actual_unit = EntIndexToHScript(kv.starting_unit_entindex)
    self.affected_units = {}

    self:CreateArcLightning(self.actual_unit)

    self:StartIntervalThink(self.delay)
end

function modifier_ability_zuus_arc_lightning:OnIntervalThink()
    local caster = self:GetCaster()

    local all = FindUnitsInRadius(caster:GetTeam(), 
    self.actual_unit:GetOrigin(), 
    nil, 
    self.radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY, 
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 
    DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
    FIND_ANY_ORDER, 
    false)

    local old_actual_unit = self.actual_unit

    for _, unit in ipairs(all) do
        if not HasAffected(self.affected_units, unit) then
            unit:EmitSound("Hero_Zuus.ArcLightning.Target")
            self:CreateArcLightning(unit)

            break
        end
    end
    if old_actual_unit == self.actual_unit or self.count >= self.jump_count then
        self:Destroy()
    end
end

function modifier_ability_zuus_arc_lightning:CreateArcLightning(target)
    self.count = self.count + 1
    local caster = self:GetCaster()
    local OldTarget = self.actual_unit
    if self.count == 1 then
        OldTarget = caster
    end

    local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_arc_lightning_head.vpcf", PATTACH_ABSORIGIN_FOLLOW, OldTarget)
    ParticleManager:SetParticleControlEnt(fx, 0, OldTarget, PATTACH_POINT_FOLLOW, "attach_attack1", OldTarget:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(fx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(fx)

    local field = caster:FindAbilityByName("ability_zuus_static_field")
    if field then field:ApplyStaticField(target) end
    
    ApplyDamage({
        victim = target,
        attacker = caster,
        damage = self.damage,
        damage_type = self:GetAbility():GetAbilityDamageType(),
        ability = self:GetAbility()
    })
    self.actual_unit = target
    table.insert(self.affected_units, target)
end

function HasAffected(Table, unit)
    for k,v in pairs(Table) do
        if v == unit then
            return true
        end
    end
    return false
end
end