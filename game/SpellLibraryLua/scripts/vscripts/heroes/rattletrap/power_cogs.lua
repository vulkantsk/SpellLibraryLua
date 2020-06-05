ability_power_cogs = class({})
LinkLuaModifier('modifier_rattletrap_cog_buff', 'heroes/rattletrap/power_cogs', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('modifier_rattletrap_cog_delay', 'heroes/rattletrap/power_cogs', LUA_MODIFIER_MOTION_NONE)

function ability_power_cogs:OnSpellStart()
    local caster = self:GetCaster()
    local vOrigin = caster:GetAbsOrigin()
    local duration = self:GetSpecialValueFor('duration')
    local radius = 215

    local units = FindUnitsInRadius(caster:GetTeam(), 
    vOrigin, 
    nil, 
    radius + 60,
    DOTA_UNIT_TARGET_TEAM_BOTH, 
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
    FIND_ANY_ORDER, 
    false)

    for k,v in pairs(units) do
        FindClearSpaceForUnit(v, vOrigin, true)

    end 

    for i=1,8 do 
        local angle = math.pi * 2 / 8 * i;
        local vPos = vOrigin + Vector(math.cos(angle), math.sin(angle)) * radius   
        GridNav:DestroyTreesAroundPoint(vPos, 70, true)
        local cog = CreateUnitByName('npc_dota_rattletrap_cog', vPos, true, caster, caster, caster:GetTeam())
        cog:AddNewModifier(caster, self, 'modifier_kill', {
            duration = duration
        })
        cog:AddNewModifier(caster, self, 'modifier_rattletrap_cog_buff', {
            duration = duration,
            vCenter = vOrigin,
            radius = radius,
        })

    end

    local nfx = ParticleManager:CreateParticle('particles/units/heroes/hero_rattletrap/rattletrap_cog_deploy.vpcf', PATTACH_ABSORIGIN, caster)
    ParticleManager:ReleaseParticleIndex(nfx)
end 

modifier_rattletrap_cog_buff = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return true end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    AllowIllusionDuplicate  = function(self) return false end,
    GetEffectName           = function(self) return 'particles/units/heroes/hero_rattletrap/rattletrap_cog_ambient_loadout.vpcf' end,
    GetEffectAttachType     = function(self) return PATTACH_ABSORIGIN end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
        }
    end,
    CheckState  = function(self)
        return {
            [MODIFIER_STATE_SPECIALLY_DENIABLE] = true,
        }
    end,
})

function modifier_rattletrap_cog_buff:GetModifierIncomingDamage_Percentage(data)
    if data.attacker == self.caster and not self.parent:IsNull() then 
        self.parent:ForceKill(true)
        return 0
    end 
    self.attackCount = self.attackCount + 1
    if self.attackCount >= self.attacks_to_destroy and not self.parent:IsNull() then 
        self:OnDestroy()
        return 0
    end
    return -100
end

function modifier_rattletrap_cog_buff:OnCreated(data)
    self.parent = self:GetParent()
    self.caster = self:GetCaster()
    self.vOrigin = self.parent:GetOrigin()
    self.ability = self:GetAbility()
    self.radius = data.radius
    self.attackCount = 0
    self.trigger_distance = self.ability:GetSpecialValueFor('trigger_distance')
    self.push_length = self.ability:GetSpecialValueFor('push_length')
    self.mana_burn = self.ability:GetSpecialValueFor('mana_burn')
    self.damage = self.ability:GetSpecialValueFor('damage')
    self.attacks_to_destroy = self.ability:GetSpecialValueFor('attacks_to_destroy')
    self.push_duration =  self.ability:GetSpecialValueFor('push_duration')
    local vectorArr = {}
    for k,__ in string.gmatch(data.vCenter, "[^%s]+") do 
        table.insert(vectorArr,k)
    end

    self.vCenter = Vector(vectorArr[1],vectorArr[2],vectorArr[3])
    self:StartIntervalThink(0.03)
end 

function modifier_rattletrap_cog_buff:IsInRing(ent)
    return #(ent:GetOrigin() - self.vCenter) <= self.radius
end 

function modifier_rattletrap_cog_buff:OnIntervalThink()
    if IsClient() then  return end


    local units = FindUnitsInRadius(self.parent:GetTeam(), 
    self.vOrigin, 
    nil, 
    self.trigger_distance,
    DOTA_UNIT_TARGET_TEAM_ENEMY, 
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_CLOSEST, 
    false)

    for k,v in pairs(units) do

        if not self:IsInRing(v) and not v:HasModifier('modifier_knockback') then 

            local nfx = ParticleManager:CreateParticle('particles/units/heroes/hero_rattletrap/rattletrap_cog_attack.vpcf', PATTACH_ABSORIGIN, self.parent)
            ParticleManager:SetParticleControlEnt(nfx, 0, v, PATTACH_POINT_FOLLOW, "attach_hitloc", v:GetAbsOrigin(), true)
            ParticleManager:SetParticleControlEnt(nfx, 1, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", self.parent:GetAbsOrigin(), true)
            ParticleManager:ReleaseParticleIndex(nfx)
            v:EmitSound("Hero_Rattletrap.Power_Cogs_Impact")
            local origin = v:GetOrigin()
            local modifierKnockback = {
                center_x = self.vOrigin.x,
                center_y = self.vOrigin.y,
                center_z = self.vOrigin.z,
                should_stun = 1,
                duration = self.push_duration,
                knockback_duration = self.push_duration,
                knockback_distance = self.push_length,
                knockback_height = 0,
            }
            v:AddNewModifier(self.caster, self.ability, "modifier_knockback", modifierKnockback )
            v:AddNewModifier(self.caster, self.ability, "modifier_rattletrap_cog_delay", {
                duration = self.push_duration + 0.1,
                damage = self.damage,
                manaBurn = self.mana_burn,
            })
            self.findUnit = true
            self:Destroy()
            break

        end 

    end 
end

function modifier_rattletrap_cog_buff:OnDestroy()
    if not self.findUnit and not self.parent:IsNull() then 
        self.parent:ForceKill(false)
    end 
end 

modifier_rattletrap_cog_delay = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return true end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    AllowIllusionDuplicate  = function(self) return false end,  
})


function modifier_rattletrap_cog_delay:OnCreated(data)
    self.damage = data.damage 
    self.manaBurn = data.manaBurn
end

function modifier_rattletrap_cog_delay:OnDestroy()
    if IsClient() then return end
    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = self.damage,
        ability = self:GetAbility(),
        damage_type = DAMAGE_TYPE_MAGICAL,
    })

    self:GetParent():SpendMana(self.manaBurn, self:GetAbility())
end