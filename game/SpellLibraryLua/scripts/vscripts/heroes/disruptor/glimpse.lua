LinkLuaModifier( "modifier_ability_disruptor_glimpse_aura", "heroes/disruptor/glimpse" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_disruptor_glimpse", "heroes/disruptor/glimpse" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_disruptor_glimpse_thinker", "heroes/disruptor/glimpse" ,LUA_MODIFIER_MOTION_NONE )

if ability_disruptor_glimpse == nil then
    ability_disruptor_glimpse = class({})
end

--------------------------------------------------------------------------------

function ability_disruptor_glimpse:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    if target:TriggerSpellAbsorb(self) then return end

    if target:IsIllusion() then
        target:Kill(self, self:GetCaster())
        return nil
    end

    if RollPercentage(75) then
        EmitSoundOn("disruptor_dis_glimpse_0"..math.random(1,5), caster)
    end

    local modif = target:FindModifierByName("modifier_ability_disruptor_glimpse")
    if modif then

        EmitSoundOn("Hero_Disruptor.Glimpse.Target", target) 

        local pos = modif.all_possible_positions[1]
        local vVelocity = ( pos - target:GetOrigin())
        vVelocity.z = 0.0

        local flDist = vVelocity:Length2D()
        vVelocity = vVelocity:Normalized()

        local flDuration = math.max(0.05, math.min(1.8, flDist / 600))

        local projectile =
        {
            Ability = self,
            EffectName = "particles/units/heroes/hero_disruptor/disruptor_glimpse_travel.vpcf",
            vSpawnOrigin = target:GetOrigin(), 
            fDistance = flDist,
            Source = self:GetCaster(),                              
            vVelocity = vVelocity * ( flDist / flDuration ),
            fStartRadius = 0,
            fEndRadius = 0,             
            bProvidesVision = true,
            iVisionRadius = 300,
            iVisionTeamNumber = caster:GetTeamNumber(),
        }             

        ProjectileManager:CreateLinearProjectile(projectile)     

        CreateModifierThinker(caster, self, "modifier_ability_disruptor_glimpse_thinker", {duration=flDuration, targetIndex=target:entindex()}, pos, caster:GetTeam(), false)
    end
end

function ability_disruptor_glimpse:GetIntrinsicModifierName()
    return "modifier_ability_disruptor_glimpse_aura"
end

--------------------------------------------------------------------------------


modifier_ability_disruptor_glimpse_aura = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    IsPassive               = function(self) return true end,
    IsAuraActiveOnDeath     = function(self) return true end,
    RemoveOnDeath           = function(self) return false end,
})


--------------------------------------------------------------------------------

function modifier_ability_disruptor_glimpse_aura:IsAura()
    return true
end

function modifier_ability_disruptor_glimpse_aura:GetModifierAura()
    return "modifier_ability_disruptor_glimpse"
end

function modifier_ability_disruptor_glimpse_aura:GetAuraRadius()
    return 99999
end

function modifier_ability_disruptor_glimpse_aura:GetAuraSearchTeam()    
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_ability_disruptor_glimpse_aura:GetAuraSearchType()    
    return DOTA_UNIT_TARGET_HERO
end

function modifier_ability_disruptor_glimpse_aura:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD
end

--------------------------------------------------------------------------------


modifier_ability_disruptor_glimpse = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return false end,
})


--------------------------------------------------------------------------------

function modifier_ability_disruptor_glimpse:OnCreated()
    self.backtrack_time = self:GetAbility():GetSpecialValueFor("backtrack_time")

    self.all_possible_positions = {}
    self.all_ticks = self.backtrack_time / 0.1

    for i = 1, self.all_ticks do
        table.insert(self.all_possible_positions, self:GetParent():GetAbsOrigin())
    end

    self:StartIntervalThink(0.1)
end

function modifier_ability_disruptor_glimpse:OnIntervalThink()

    for i = 1, #self.all_possible_positions-1 do
        self.all_possible_positions[i] = self.all_possible_positions[i+1]
    end

    self.all_possible_positions[ #self.all_possible_positions ] = self:GetParent():GetAbsOrigin()
end

--------------------------------------------------------------------------------


modifier_ability_disruptor_glimpse_thinker = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return false end,
})


--------------------------------------------------------------------------------

if IsServer() then
function modifier_ability_disruptor_glimpse_thinker:OnCreated(kv)
    self.target = EntIndexToHScript(kv.targetIndex)

    local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_disruptor/disruptor_glimpse_travel.vpcf", PATTACH_CUSTOMORIGIN, nil )
    ParticleManager:SetParticleControlEnt( nFXIndex, 0, self.target, PATTACH_ABSORIGIN_FOLLOW, nil, self.target:GetOrigin(), true )
    ParticleManager:SetParticleControl( nFXIndex, 1, self:GetParent():GetAbsOrigin() )
    ParticleManager:SetParticleControl( nFXIndex, 2, Vector( self:GetDuration(), self:GetDuration(), self:GetDuration() ) )
    self:AddParticle( nFXIndex, false, false, -1, false, false )

    local nFXIndex2 = ParticleManager:CreateParticle( "particles/units/heroes/hero_disruptor/disruptor_glimpse_targetend.vpcf", PATTACH_CUSTOMORIGIN, nil )
    ParticleManager:SetParticleControlEnt( nFXIndex2, 0, self.target, PATTACH_ABSORIGIN_FOLLOW, nil, self.target:GetOrigin(), true )
    ParticleManager:SetParticleControl( nFXIndex2, 1, self:GetParent():GetAbsOrigin() )
    ParticleManager:SetParticleControl( nFXIndex2, 2, Vector( self:GetDuration(), self:GetDuration(), self:GetDuration() ) )
    self:AddParticle( nFXIndex2, false, false, -1, false, false )

    local nFXIndex3 = ParticleManager:CreateParticle( "particles/units/heroes/hero_disruptor/disruptor_glimpse_targetstart.vpcf", PATTACH_CUSTOMORIGIN, nil )
    ParticleManager:SetParticleControlEnt( nFXIndex3, 0, self.target, PATTACH_ABSORIGIN_FOLLOW, nil, self.target:GetOrigin(), true )
    ParticleManager:SetParticleControl( nFXIndex3, 2, Vector( self:GetDuration(), self:GetDuration(), self:GetDuration() ) )
    self:AddParticle( nFXIndex3, false, false, -1, false, false )
    
    EmitSoundOnLocationForAllies( self:GetParent():GetAbsOrigin(), "Hero_Disruptor.Glimpse.Destination", self:GetCaster() )
end

function modifier_ability_disruptor_glimpse_thinker:OnDestroy()
    if self.target and not self.target:IsMagicImmune() then
        AddFOWViewer(self:GetCaster():GetTeamNumber(), self:GetParent():GetAbsOrigin(), 300, 3.34, false)
        FindClearSpaceForUnit(self.target, self:GetParent():GetAbsOrigin(), true)
        self.target:Interrupt()

        EmitSoundOn("Hero_Disruptor.Glimpse.End", self.target) 
    end
end
end
