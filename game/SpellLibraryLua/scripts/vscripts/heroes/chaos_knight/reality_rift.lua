ability_reality_rift = class({})
LinkLuaModifier('modifier_ability_chaos_strike_debuff', 'heroes/chaos_knight/reality_rift', LUA_MODIFIER_MOTION_NONE)
function ability_reality_rift:OnAbilityPhaseStart()
	-- unit identifier
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local min_loc = 50
    local max_loc = 55
    
	self.point = SplineVectors( caster:GetOrigin(), target:GetOrigin(), RandomInt(min_loc,max_loc)/100 )

	self.effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_chaos_knight/chaos_knight_reality_rift.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
	ParticleManager:SetParticleControlEnt(self.effect_cast,0,caster,PATTACH_ABSORIGIN_FOLLOW,"attach_hitloc",caster:GetOrigin(),true)
	ParticleManager:SetParticleControlEnt(self.effect_cast,1,target,PATTACH_POINT_FOLLOW,"attach_hitloc",target:GetOrigin(), true)
	ParticleManager:SetParticleControl( self.effect_cast, 2, self.point )
	ParticleManager:SetParticleControlForward( self.effect_cast, 2, (target:GetOrigin()-caster:GetOrigin()):Normalized() )
	ParticleManager:ReleaseParticleIndex( self.effect_cast )

	EmitSoundOn( "Hero_ChaosKnight.RealityRift", caster )

	return true 
end

function ability_reality_rift:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	-- cancel if linken
	if target:TriggerSpellAbsorb( self ) then
		return
	end

	-- load data
	local point = self.point
	local bDuration = self:GetSpecialValueFor("duration")
	
	local search_radius = 1375
	local distance = 64
	self.point = nil

	local selfLoc = point + ((point - caster:GetOrigin()):Normalized() * distance)

	local heroes = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),
		caster:GetOrigin(),	
		nil,	
		search_radius,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO,	
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)
	local illusions = {}
	for _,hero in pairs(heroes) do
		if hero:IsIllusion() and hero:GetPlayerOwnerID() == caster:GetPlayerOwnerID() then
			table.insert( illusions, hero )
		end
	end

	FindClearSpaceForUnit( target, point, true )
	FindClearSpaceForUnit( caster, selfLoc, true )
	caster:SetForwardVector( (target:GetOrigin()-caster:GetOrigin()):Normalized() )
    caster:MoveToTargetToAttack( target )
    
	for _,illusion in pairs(illusions) do
		FindClearSpaceForUnit( illusion, point, false )
		illusion:SetForwardVector( (target:GetOrigin()-illusion:GetOrigin()):Normalized() )
		illusion:MoveToTargetToAttack( target )
	end

	target:AddNewModifier(caster,self, "modifier_ability_chaos_strike_debuff", { duration = bDuration })
	EmitSoundOn( "Hero_ChaosKnight.RealityRift.Target", target )

end

modifier_ability_chaos_strike_debuff = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return true end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    AllowIllusionDuplicate  = function(self) return true end,
    DeclareFunctions        = function(self) return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    } end,
    GetModifierPhysicalArmorBonus = function(self) return self.armor end,
})

function modifier_ability_chaos_strike_debuff:OnCreated()
    self.armor = -self:GetAbility():GetSpecialValueFor('armor_reduction')
end 
