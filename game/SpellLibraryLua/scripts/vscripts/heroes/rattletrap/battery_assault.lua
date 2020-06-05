ability_battery_assault = class({})


function ability_battery_assault:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_ability_battery_assault_buff", {duration = self:GetSpecialValueFor("duration")})
end

modifier_ability_battery_assault_buff = class({})
LinkLuaModifier("modifier_ability_battery_assault_buff", "heroes/rattletrap/battery_assault", LUA_MODIFIER_MOTION_NONE)

function modifier_ability_battery_assault_buff:OnCreated()
    self.ability = self:GetAbility()
    self.damage = self.ability:GetSpecialValueFor("damage")
    self.radius = self.ability:GetSpecialValueFor("radius")
    self:StartIntervalThink( self.ability:GetSpecialValueFor("interval") )
end

function modifier_ability_battery_assault_buff:OnRefresh()
    self:OnCreated()
end

function modifier_ability_battery_assault_buff:OnIntervalThink()
    if IsClient() then return end
    local parent = self:GetParent()
    local parentPos = parent:GetAbsOrigin()
    local enemies = FindUnitsInRadius(parent:GetTeamNumber(), 
    parentPos, 
    nil, 
    self.radius, 
    DOTA_UNIT_TARGET_TEAM_ENEMY, 
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 
    DOTA_UNIT_TARGET_FLAG_NONE, 
    FIND_ANY_ORDER, 
    false)
    
    local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_rattletrap/rattletrap_battery_assault.vpcf", PATTACH_POINT_FOLLOW,parent)
    ParticleManager:SetParticleControl(nfx, 1, parentPos)
    ParticleManager:ReleaseParticleIndex(nfx)
    EmitSoundOn( "Hero_Rattletrap.Battery_Assault_Launch", parent )
    local enemy = enemies[RandomInt(1,#enemies)]
    if not enemy then return end
    local targetPos = enemy:GetAbsOrigin()
    ApplyDamage({
        attacker = parent,
        victim = enemy,
        damage = self.damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self.ability,
    })

    enemy:AddNewModifier(parent,self.ability,'modifier_stunned',{duration = .15})

    local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_rattletrap/rattletrap_battery_shrapnel.vpcf", PATTACH_POINT_FOLLOW, parent)
    ParticleManager:SetParticleControl(nfx, 1, targetPos)
    ParticleManager:ReleaseParticleIndex(nfx)
    EmitSoundOn( "Hero_Rattletrap.Battery_Assault_Impact", enemy )
end
