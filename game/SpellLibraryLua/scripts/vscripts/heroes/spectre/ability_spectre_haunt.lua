LinkLuaModifier( "modifier_ability_spectre_haunt_illusions_buff", "heroes/spectre/ability_spectre_haunt" ,LUA_MODIFIER_MOTION_NONE )

if ability_spectre_haunt == nil then
    ability_spectre_haunt = class({})
end

--------------------------------------------------------------------------------

function ability_spectre_haunt:OnUpgrade()
    local caster = self:GetCaster() 

    local ability = caster:FindAbilityByName("ability_spectre_reality")
    if ability then
        if self:GetLevel() ~= ability:GetLevel() then
            ability:SetLevel(1)
        end
    end
end

function ability_spectre_haunt:OnAbilityPhaseStart()
    EmitSoundOn("Hero_Spectre.HauntCast", self:GetCaster()) 
    return true
end

function ability_spectre_haunt:OnAbilityPhaseInterrupted()
    StopSoundOn("Hero_Spectre.HauntCast", self:GetCaster())
end

function ability_spectre_haunt:OnSpellStart()
    EmitGlobalSound("Hero_Spectre.Haunt")

    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")
    local illusion_damage_outgoing = self:GetSpecialValueFor("illusion_damage_outgoing")
    local illusion_damage_incoming = self:GetSpecialValueFor("illusion_damage_incoming")
    local attack_delay = self:GetSpecialValueFor("attack_delay")

    local all = FindUnitsInRadius(caster:GetTeam(), 
    caster:GetOrigin(), 
    nil, 
    99999,
    DOTA_UNIT_TARGET_TEAM_ENEMY, 
    DOTA_UNIT_TARGET_HERO, 
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD + DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS,
    FIND_ANY_ORDER, 
    false)

    self.startTime = GameRules:GetGameTime()

    for _, unit in ipairs(all) do
        local illusions = CreateIllusions(caster, caster, { duration = duration, outgoing_damage = illusion_damage_outgoing, incoming_damage = illusion_damage_incoming }, 1, 0, false, true )
        for k,v in ipairs(illusions) do
            v:SetAbsOrigin(unit:GetAbsOrigin() + RandomVector(100))
            FindClearSpaceForUnit(v, v:GetAbsOrigin(), false)
            Timers:CreateTimer(attack_delay, function()
                ExecuteOrderFromTable({
                    UnitIndex = v:entindex(),
                    OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
                    TargetIndex = unit:entindex(),
                    Queue = false,
                })
                v:SetForceAttackTarget(unit)
            end)
            v:AddNewModifier(caster, self, "modifier_ability_spectre_haunt_illusions_buff", {duration=inf})
            v.ISSPECTRE_ILLUSION_HAUNT = true
        end
    end
end

function ability_spectre_haunt:GetAssociatedSecondaryAbilities()
    return "ability_spectre_reality"
end

--------------------------------------------------------------------------------


modifier_ability_spectre_haunt_illusions_buff = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
            MODIFIER_PROPERTY_DISABLE_AUTOATTACK
        }
    end,
    CheckState              = function(self)
        return {
            [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
            [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
            [MODIFIER_STATE_COMMAND_RESTRICTED] = true
        }
    end,
})


--------------------------------------------------------------------------------

if IsServer() then
    function modifier_ability_spectre_haunt_illusions_buff:OnCreated()
        self:StartIntervalThink(0.1)
    end

    function modifier_ability_spectre_haunt_illusions_buff:OnIntervalThink()
        local parent = self:GetParent()
        if parent:GetForceAttackTarget() and not parent:GetForceAttackTarget():IsAlive() then
            parent:Kill(self:GetAbility(), self:GetCaster())
        end
    end
end

function modifier_ability_spectre_haunt_illusions_buff:GetModifierMoveSpeed_Absolute() return 400 end
function modifier_ability_spectre_haunt_illusions_buff:GetDisableAutoAttack() return 1 end