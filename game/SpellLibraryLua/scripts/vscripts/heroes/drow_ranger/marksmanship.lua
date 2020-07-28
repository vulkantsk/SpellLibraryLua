LinkLuaModifier( "modifier_ability_drow_ranger_marksmanship", "heroes/drow_ranger/marksmanship" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_drow_ranger_marksmanship_proj", "heroes/drow_ranger/marksmanship" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_drow_ranger_marksmanship_reduction", "heroes/drow_ranger/marksmanship" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_drow_ranger_marksmanship_aura", "heroes/drow_ranger/marksmanship" ,LUA_MODIFIER_MOTION_NONE )

if ability_drow_ranger_marksmanship == nil then
    ability_drow_ranger_marksmanship = class({})
end

--------------------------------------------------------------------------------

function ability_drow_ranger_marksmanship:GetIntrinsicModifierName()
    return "modifier_ability_drow_ranger_marksmanship"
end

--------------------------------------------------------------------------------


modifier_ability_drow_ranger_marksmanship = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return false end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_EVENT_ON_ATTACK_START,
            MODIFIER_EVENT_ON_ATTACK_RECORD,
            MODIFIER_EVENT_ON_ATTACK_LANDED,
            MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY,
            MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL
        }
    end,
    CheckState              = function(self)
        return {
            [MODIFIER_STATE_CANNOT_MISS] = self:GetStackCount() == 1 and true or false
        }
    end,
})


--------------------------------------------------------------------------------

function modifier_ability_drow_ranger_marksmanship:OnCreated()
    self.disable = self:GetAbility():GetSpecialValueFor( "disable_range" )
    self.radius = self:GetAbility():GetSpecialValueFor( "agility_range" )

    self:SetStackCount(0)
    self.active = true
    self.records = {}

    self:PlayEffects1()

    self:StartIntervalThink(0.1)
end

function modifier_ability_drow_ranger_marksmanship:OnRefresh()
    self.disable = self:GetAbility():GetSpecialValueFor( "disable_range" )
    self.radius = self:GetAbility():GetSpecialValueFor( "agility_range" )
end

function modifier_ability_drow_ranger_marksmanship:GetModifierProcAttack_BonusDamage_Physical(k)
    if self.records[k.record] then
        return self:GetAbility():GetSpecialValueFor("bonus_damage")
    end
end

function modifier_ability_drow_ranger_marksmanship:OnAttackStart(k)
    local caster = self:GetParent()
    local target = k.target
    local attacker = k.attacker
    if caster == attacker and not caster:IsIllusion() then
        caster:RemoveModifierByName("modifier_ability_drow_ranger_marksmanship_proj")

        self:SetStackCount(0)

        if not self.active then return end

        local chance = self:GetAbility():GetSpecialValueFor("chance")
        local modif = caster:FindModifierByName("modifier_ability_drow_ranger_frost_arrows")

        if RollPercentage(chance) then
            self:SetStackCount(1)
            local drow_proj = modif:ShouldLaunch( target ) and 4 or 3
            caster:AddNewModifier(caster, self:GetAbility(), "modifier_ability_drow_ranger_marksmanship_proj", {drow_proj=drow_proj})
        else
            local drow_proj = modif:ShouldLaunch( target ) and 2 or 1
            caster:AddNewModifier(caster, self:GetAbility(), "modifier_ability_drow_ranger_marksmanship_proj", {drow_proj=drow_proj})
        end
    end
end

function modifier_ability_drow_ranger_marksmanship:OnAttackRecord(k)
    local caster = self:GetParent()
    local target = k.target
    local attacker = k.attacker
    if caster == attacker and not caster:IsIllusion() then
        caster:RemoveModifierByName("modifier_ability_drow_ranger_marksmanship_proj")

        if self:GetStackCount() > 0 then
            self.records[k.record] = true
        end
    end
end

function modifier_ability_drow_ranger_marksmanship:OnAttackLanded(k)
    local caster = self:GetParent()
    local target = k.target
    local attacker = k.attacker
    if caster == attacker and not caster:IsIllusion() then
        if self.records[k.record] then
            local modifier = target:AddNewModifier(caster, self:GetAbility(), "modifier_ability_drow_ranger_marksmanship_reduction", {duration=0.5})
            EmitSoundOn("Hero_DrowRanger.Marksmanship.Target", target)

            self.records[k.record] = modifier
        end
    end
end

function modifier_ability_drow_ranger_marksmanship:OnAttackRecordDestroy( k )
    if not self.records[k.record] then return end

    local modifier = self.records[k.record]
    if type(modifier)=='table' and not modifier:IsNull() then modifier:Destroy() end
    self.records[k.record] = nil
end

function modifier_ability_drow_ranger_marksmanship:OnIntervalThink()
    if not IsServer() then return end

    local enemies = FindUnitsInRadius(
        self:GetParent():GetTeamNumber(),
        self:GetParent():GetOrigin(),
        nil,
        self.disable,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS + DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD,
        0,
        false)

    local no_enemies = #enemies==0

    if no_enemies ~= self.active then
        self:PlayEffects2( no_enemies )
        self.active = no_enemies
    end
end

function modifier_ability_drow_ranger_marksmanship:IsAura()
    if not self:GetCaster():PassivesDisabled() then
        return self.active
    end
end

function modifier_ability_drow_ranger_marksmanship:GetModifierAura()
    return "modifier_ability_drow_ranger_marksmanship_aura"
end

function modifier_ability_drow_ranger_marksmanship:GetAuraRadius()
    return self.radius
end

function modifier_ability_drow_ranger_marksmanship:GetAuraDuration()
    return 0.5
end

function modifier_ability_drow_ranger_marksmanship:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_ability_drow_ranger_marksmanship:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_ability_drow_ranger_marksmanship:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_RANGED_ONLY
end

function modifier_ability_drow_ranger_marksmanship:GetAuraEntityReject( ent )
    if ent:IsIllusion() then return true end
    return false
end

function modifier_ability_drow_ranger_marksmanship:PlayEffects1()
    local particle_cast = "particles/units/heroes/hero_drow/drow_marksmanship.vpcf"
 
    self.fx = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )

    ParticleManager:SetParticleControl( self.fx, 2, Vector(2,0,0) )

    self:AddParticle(self.fx, false, false, -1, false, false)

    self:PlayEffects2( true )
end

function modifier_ability_drow_ranger_marksmanship:PlayEffects2( start )
    local state = 1
    if start then state = 2 end
    ParticleManager:SetParticleControl( self.fx, 2, Vector(state,0,0) )

    if not start then return end

    local particle_cast = "particles/units/heroes/hero_drow/drow_marksmanship_start.vpcf"

    local fx = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:ReleaseParticleIndex( fx )
end

--------------------------------------------------------------------------------


modifier_ability_drow_ranger_marksmanship_proj = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return false end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_PROJECTILE_NAME
        }
    end,
    GetPriority             = function(self) return MODIFIER_PRIORITY_HIGH end,
})


--------------------------------------------------------------------------------

function modifier_ability_drow_ranger_marksmanship_proj:OnCreated(kv)
    if kv.drow_proj == 1 then
        self.proj = "particles/units/heroes/hero_drow/drow_base_attack.vpcf"
    elseif kv.drow_proj == 2 then
        self.proj = "particles/units/heroes/hero_drow/drow_frost_arrow.vpcf"
    elseif kv.drow_proj == 3 then
        self.proj = "particles/units/heroes/hero_drow/drow_marksmanship_attack.vpcf"
    elseif kv.drow_proj == 4 then
        self.proj = "particles/units/heroes/hero_drow/drow_marksmanship_frost_arrow.vpcf"
    end
end

function modifier_ability_drow_ranger_marksmanship_proj:GetModifierProjectileName()
    return self.proj
end

--------------------------------------------------------------------------------


modifier_ability_drow_ranger_marksmanship_reduction = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_PHYSICAL_ARMOR_BASE_PERCENTAGE
        }
    end,
})


--------------------------------------------------------------------------------

function modifier_ability_drow_ranger_marksmanship_reduction:GetModifierPhysicalArmorBase_Percentage() return 0 end

--------------------------------------------------------------------------------


modifier_ability_drow_ranger_marksmanship_aura = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS
        }
    end,
})


--------------------------------------------------------------------------------

function modifier_ability_drow_ranger_marksmanship_aura:OnCreated(kv)
    self.agility_multiplier = self:GetAbility():GetSpecialValueFor("agility_multiplier")

    self:StartIntervalThink(0.5)
end

function modifier_ability_drow_ranger_marksmanship_aura:OnRefresh()
    self.agility_multiplier = self:GetAbility():GetSpecialValueFor("agility_multiplier")
end

function modifier_ability_drow_ranger_marksmanship_aura:OnIntervalThink()
    self:GetParent():CalculateStatBonus()
end

function modifier_ability_drow_ranger_marksmanship_aura:GetModifierBonusStats_Agility()
    if not IsServer() then return end

    if self:GetCaster()==self:GetParent() then
        if self.lock1 then return end

        self.lock1 = true
        local agi = self:GetCaster():GetAgility()
        self.lock1 = false

        local bonus = self.agility_multiplier*agi/100

        return bonus
    else
        local agi = self:GetCaster():GetAgility()
        agi = 100/(100+self.agility_multiplier)*agi

        local bonus = self.agility_multiplier*agi/100

        return bonus
    end
end