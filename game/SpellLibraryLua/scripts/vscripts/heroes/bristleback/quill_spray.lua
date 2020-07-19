ability_quill_spray = class({})
LinkLuaModifier('modifier_ability_quill_spray_debuff_active', 'heroes/bristleback/quill_spray', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('modifier_ability_quill_spray_debuff', 'heroes/bristleback/quill_spray', LUA_MODIFIER_MOTION_NONE)
function ability_quill_spray:OnSpellStart()
	self.caster	= self:GetCaster()
	
	local radius					= self:GetSpecialValueFor("radius")
    local projectile_speed		= self:GetSpecialValueFor("projectile_speed")
    local duration = self:GetSpecialValueFor("quill_stack_duration")
    local quill_stack_damage = self:GetSpecialValueFor("quill_stack_damage")
    local quill_base_damage = self:GetSpecialValueFor("quill_base_damage")
    local caster = self:GetCaster()
		
	if not IsServer() then return end
	
    local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_bristleback/bristleback_quill_spray.vpcf", PATTACH_ABSORIGIN, self:GetCaster())
    ParticleManager:ReleaseParticleIndex(nfx)

    for k,v in pairs(FindUnitsInRadius(self:GetCaster():GetTeam(), 
    self:GetCaster():GetOrigin(), 
    nil, 
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY, 
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
    FIND_ANY_ORDER, 
    false)) do 
        local amount = v:AddStackModifier({
            ability = self, 
            modifier = 'modifier_ability_quill_spray_debuff',
            duration = duration,
            updateStack = true,
            caster = caster,
        })

        v:AddNewModifier(caster, self, 'modifier_ability_quill_spray_debuff_active', {duration = duration})

        ApplyDamage({
            victim = v,
            attacker = caster,
            damage = quill_base_damage + amount * quill_stack_damage,
            damage_type = self:GetAbilityDamageType(),
            ability = self,
        })

    end 
	
    self.caster:EmitSound("Hero_Bristleback.QuillSpray.Cast")
end

modifier_ability_quill_spray_debuff_active = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return true end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    AllowIllusionDuplicate  = function(self) return true end,
    GetAttributes           = function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
})

function modifier_ability_quill_spray_debuff_active:OnDestroy()
    if IsClient() then return end
    self:GetParent():AddStackModifier({
        ability = self:GetAbility(), 
        modifier = 'modifier_ability_quill_spray_debuff',
        caster = self:GetCaster(),
        count = -1,
    })
end 

modifier_ability_quill_spray_debuff = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return true end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    AllowIllusionDuplicate  = function(self) return true end,
})