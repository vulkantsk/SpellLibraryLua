LinkLuaModifier( "modifier_ability_tidehunter_ravage", "heroes/tidehunter/ravage" ,LUA_MODIFIER_MOTION_NONE )

if ability_tidehunter_ravage == nil then
    ability_tidehunter_ravage = class({})
end

--------------------------------------------------------------------------------

function ability_tidehunter_ravage:OnSpellStart()
    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "modifier_ability_tidehunter_ravage", {})

    EmitSoundOn("Ability.Ravage", caster)
end

--------------------------------------------------------------------------------


modifier_ability_tidehunter_ravage = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return false end,
    GetAttributes           = function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end
})


--------------------------------------------------------------------------------

if IsServer() then
function modifier_ability_tidehunter_ravage:OnCreated()
    self.duration = self:GetAbility():GetSpecialValueFor("duration")
    self.radius = self:GetAbility():GetSpecialValueFor("radius")
    self.speed = self:GetAbility():GetSpecialValueFor("speed") * 0.033

    local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_tidehunter/tidehunter_spell_ravage.vpcf", PATTACH_WORLDORIGIN, self:GetCaster())
    ParticleManager:SetParticleControl(fx, 0, self:GetCaster():GetAbsOrigin())
    ParticleManager:SetParticleControl(fx, 1, Vector(250,1,1))
    ParticleManager:SetParticleControl(fx, 2, Vector(500,1,1))
    ParticleManager:SetParticleControl(fx, 3, Vector(750,1,1))
    ParticleManager:SetParticleControl(fx, 4, Vector(1000,1,1))
    ParticleManager:SetParticleControl(fx, 5, Vector(1250,1,1))
    ParticleManager:ReleaseParticleIndex(fx)

    self.range = 250
    self.Table = {}

    self.start_point = self:GetParent():GetAbsOrigin()

    self:StartIntervalThink(0.033)
end

function modifier_ability_tidehunter_ravage:OnIntervalThink()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    if self.range >= self.radius then self:Destroy() return end

    local all = FindUnitsInRadius(caster:GetTeamNumber(), 
    self.start_point, 
    nil, 
    self.range,
    DOTA_UNIT_TARGET_TEAM_ENEMY, 
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER, 
    false)

    for _, unit in ipairs(all) do
        local distance = (unit:GetAbsOrigin() - self.start_point):Length2D()
        if not HasAffected(self.Table, unit) and distance >= self.range - 250 then
            table.insert(self.Table, unit)

            unit:RemoveModifierByName("modifier_knockback")

            local knockbackProperties =
            {
                center_x = unit:GetAbsOrigin().x,
                center_y = unit:GetAbsOrigin().y,
                center_z = unit:GetAbsOrigin().z,
                duration = 0.5,
                knockback_duration = 0.5,
                knockback_distance = 0,
                knockback_height = 350
            }

            local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_tidehunter/tidehunter_spell_ravage_hit.vpcf", PATTACH_ABSORIGIN, unit)
            ParticleManager:SetParticleControl(fx, 0, unit:GetAbsOrigin())
            ParticleManager:ReleaseParticleIndex(fx)

            unit:AddNewModifier( caster, nil, "modifier_knockback", knockbackProperties )
            Timers:CreateTimer(0.5, function()
                if not unit:IsMagicImmune() then

                    unit:AddNewModifier( caster, ability, "modifier_stunned", {duration=self.duration} )

                    local damageTable = {
                        victim = unit,
                        attacker = caster, 
                        damage = ability:GetAbilityDamage(),
                        damage_type = ability:GetAbilityDamageType(),
                        ability = ability
                    }
                
                    ApplyDamage(damageTable) 
                end   

                EmitSoundOn("Hero_Tidehunter.RavageDamage", unit)   
            end)
        end
    end
    self.range = self.range + self.speed
end
end

function HasAffected(table, target)
    for k,v in pairs(table) do
        if v == target then
            return true
        end
    end
    return false
end