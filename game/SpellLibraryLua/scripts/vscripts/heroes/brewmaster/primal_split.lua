ability_primal_split = class({})
LinkLuaModifier('modifier_ability_primal_split_hide', 'heroes/brewmaster/primal_split', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('modifier_primal_split_unit', 'heroes/brewmaster/primal_split', LUA_MODIFIER_MOTION_NONE)

function ability_primal_split:OnAbilityPhaseInterrupted()
    self:GetCaster():EmitSound('Hero_Brewmaster.PrimalSplit.Cast')
    return true 
end 

function ability_primal_split:OnSpellStart()
    local allAuras = self:GetCaster():FilterModifiers(function(modifier)
        return not not (modifier.IsAura and modifier:IsAura() )
    end )
    local caster = self:GetCaster()
    local abilityLvl = self:GetLevel()
    local origin = caster:GetOrigin()
    local earth_position = origin + caster:GetForwardVector() * 100
    local duration = self:GetSpecialValueFor('duration')
    local creeps = {
        storm =  CreateUnitByName('npc_dota_brewmaster_storm_' .. abilityLvl, RotatePosition(origin, QAngle(0, 90, 0), earth_position), true, caster, caster, caster:GetTeamNumber()),
        earth = CreateUnitByName('npc_dota_brewmaster_earth_' .. abilityLvl, earth_position, true, caster, caster, caster:GetTeamNumber()),
        fire =  CreateUnitByName('npc_dota_brewmaster_fire_' .. abilityLvl, RotatePosition(origin, QAngle(0, -90, 0), earth_position), true, caster, caster, caster:GetTeamNumber()),
    }

    if not (creeps.storm or creeps.earth or creeps.fire) then 
        return 
    end     

    local LearnAllAbilitiesExcluding = function( unit, level)
        local excludedAbilityNames = {
            brewmaster_thunder_clap = true,
            brewmaster_drunken_haze = true,
            brewmaster_drunken_brawler = true,
        }
        for i=0,15 do
            local ability = unit:GetAbilityByIndex(i)
            if ability and not excludedAbilityNames[ability:GetAbilityName()] then
                ability:SetLevel(level)
            end
        end
    end
    local i = 0;
    for k,v in pairs(creeps) do 
        i = i + 1
        v:SetControllableByPlayer(caster:GetPlayerID(), true)
        v:SetForwardVector(caster:GetForwardVector())
        LearnAllAbilitiesExcluding(v,abilityLvl)
        v:AddNewModifier(caster, self, 'modifier_kill', {duration = duration})
        v:AddNewModifier(caster,self,'modifier_primal_split_unit',{duration = duration + (i * 0.1)})
        for _,modifier in pairs(allAuras) do
            v:AddNewModifier(caster,self,modifier:GetName(),{duration = modifier:GetDuration()})
        end 
    end 

    self:GetCaster():EmitSound('Hero_Brewmaster.PrimalSplit.Spawn')
    caster.__brew_creeps__ = creeps
    caster.__selected_brew_creep = creeps.earth
    caster:AddNewModifier(caster,self,'modifier_ability_primal_split_hide',{duration = duration})
    -- PlayerResource:SetOverrideSelectionEntity(caster:GetPlayerID(),caster.__selected_brew_creep) -- WARNING
end 

modifier_primal_split_unit = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    AllowIllusionDuplicate  = function(self) return false end,
    IsPermanent             = function(self) return true end,  
    DeclareFunctions        = function(self) return {
        MODIFIER_EVENT_ON_DEATH,
    } end,
})

function modifier_primal_split_unit:OnCreated()
    self.parent = self:GetParent()
end


function modifier_primal_split_unit:OnDeath(data)
    if data.unit == self.parent then 
        local owner = data.unit:GetOwner()
        local unitName = data.unit:GetUnitName()

        local names = {
            npc_dota_brewmaster_storm_ = 'storm',
            npc_dota_brewmaster_earth_ = 'earth',
            npc_dota_brewmaster_fire_ = 'fire',

        }   
        local name = nil
        for k,v in pairs(names) do
            if string.match(data.unit:GetUnitName(),k) then 
                name = v
                break
            end 

        end 
        owner.__brew_creeps__[name] = nil
        if not owner.__brew_creeps__ then return end 
        if table.length(owner.__brew_creeps__) == 0 then 
            if data.attacker ~= self.parent then 
                -- PlayerResource:SetOverrideSelectionEntity(owner:GetPlayerID(),owner)
                owner:RemoveModifierByName('modifier_ability_primal_split_hide')

                FindClearSpaceForUnit(owner, self:GetParent():GetOrigin(), true)
                owner:Kill(data.ability, data.attacker)
                return 
            end

            FindClearSpaceForUnit(owner, self:GetParent():GetOrigin(), true)
            
        end 
    end 
end 

modifier_ability_primal_split_hide = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    AllowIllusionDuplicate  = function(self) return false end,
    IsPermanent             = function(self) return true end,
    CheckState              = function(self) return {
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_INVISIBLE] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_BLIND] = true,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_OUT_OF_GAME] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_MUTED] = true,
        [MODIFIER_STATE_HEXED] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    } end,
    OnCreated                  = function(self)
        if IsClient() then return end
        local origin = self:GetParent():GetOrigin()
        self:GetParent():SetOrigin(Vector(origin.x,origin.y,origin.z - 322))
    end,
})