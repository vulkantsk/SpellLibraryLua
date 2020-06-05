ability_phantasm = class({})
LinkLuaModifier('modifier_chaos_knight_phantasm_lua', 'heroes/chaos_knight/phantasm', LUA_MODIFIER_MOTION_NONE)
function ability_phantasm:OnSpellStart()
	local inv_duration = self:GetSpecialValueFor("invuln_duration")

	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_chaos_knight_phantasm_lua", { 
        duration = 0.5 
    })
end 

modifier_chaos_knight_phantasm_lua  = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return true end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    AllowIllusionDuplicate  = function(self) return false end,
    CheckState              = function(self) return {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_OUT_OF_GAME] = true,
        [MODIFIER_STATE_ROOTED] = true,
        [MODIFIER_STATE_UNTARGETABLE] = true,

    }
    end,
})

function modifier_chaos_knight_phantasm_lua:OnCreated( kv )

	self.image_count = self:GetAbility():GetSpecialValueFor( "images_count" )
	self.image_duration = self:GetAbility():GetSpecialValueFor( "illusion_duration" )
    self.incoming_damage = self:GetAbility():GetSpecialValueFor( "incoming_damage" )
    self.outgoing_damage = self:GetAbility():GetSpecialValueFor( "outgoing_damage" )
    self.magic_resistance = self:GetAbility():GetSpecialValueFor( "magic_resistance" )

	if IsServer() then
		-- Generate data
		local caster = self:GetParent()
		self.illusions = {}
        self:GetParent():Purge( false, true, false, false, false )

		self:GetParent():Stop()
		for _,illusion in pairs(self:GetAbility().illusions or {}) do
			if (not illusion:IsNull()) and illusion:IsAlive() then
				illusion:ForceKill( false )
			end
			illusion = nil
		end
		self:GetAbility().illusions = {}

		local distance = 135 
		local spawn = {}
		spawn[1] = caster:GetOrigin()
		spawn[2] = spawn[1] + caster:GetRightVector():Normalized() * distance
		spawn[3] = spawn[1] + caster:GetRightVector():Normalized() * -distance
		spawn[4] = spawn[1] + caster:GetForwardVector():Normalized() * -distance
		spawn[5] = spawn[1] + caster:GetForwardVector():Normalized() * distance

		-- Move real one to random position
        local realPos = RandomInt( 1, #spawn )
		self.spawnSelf = spawn[realPos]
        print(self.spawnSelf)
		-- set other spawn's location
		self.spawnLoc = {}
		for i=1,self.image_count do
			local sp = i
			if sp==realPos then sp = self.image_count+1 end
			self.spawnLoc[i] = spawn[sp]
		end
		self.spawnedUnits = 0

		self.effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_chaos_knight/chaos_knight_phantasm.vpcf", PATTACH_ABSORIGIN, self:GetParent() )
		ParticleManager:SetParticleControl( self.effect_cast, 0, spawn[1] )
		self:AddParticle(self.effect_cast,false,false,-1,false,false)
		EmitSoundOn(  "Hero_ChaosKnight.Phantasm", self:GetParent() )
	end
end

function modifier_chaos_knight_phantasm_lua:CreateIllusionAndAdd( caster, location )
	-- optimization: use async unit creation
	local ability = self:GetAbility()
	local modifyIllusion = function ( illusion )
		illusion:SetForwardVector( caster:GetForwardVector() )
		while illusion:GetLevel() < caster:GetLevel() do
			illusion:HeroLevelUp( false )
		end
		illusion:SetAbilityPoints( 0 )
		for i=0,24 do
			local ability = caster:GetAbilityByIndex(i)
			if ability and illusion:GetAbilityByIndex(i) then
				illusion:GetAbilityByIndex(i):SetLevel( ability:GetLevel() )
			end
		end
		for slot=DOTA_ITEM_SLOT_1,DOTA_ITEM_SLOT_6 do
			local item = caster:GetItemInSlot(slot)
			if item then
                illusion:AddItemByName( item:GetName() )
            end
		end

		-- make illusion
		illusion:MakeIllusion()
		illusion:SetControllableByPlayer( caster:GetPlayerID(), false ) -- (playerID, bSkipAdjustingPosition)
		illusion:SetOwner( caster )
		illusion:SetPlayerID( caster:GetPlayerID() )

		-- Add illusion modifier
		illusion:AddNewModifier(caster,self,"modifier_illusion",{
			duration = self.image_duration,
			outgoing_damage = self.outgoing_damage,
			incoming_damage = self.incoming_damage,
        })
        
        illusion:SetBaseMagicalResistanceValue(self.magic_resistance)

		table.insert( ability.illusions, illusion )
	end

	local illusion = CreateUnitByNameAsync(caster:GetUnitName(),location, false, caster,caster, caster:GetTeamNumber(),modifyIllusion)

	return illusion
end

function modifier_chaos_knight_phantasm_lua:OnDestroy( kv )
    if IsServer() then
        print(self.spawnSelf)
		FindClearSpaceForUnit( self:GetParent(), self.spawnSelf, true )

		local loop = true
		while loop do
			local illusion = self:CreateIllusionAndAdd( self:GetParent(), self.spawnLoc[self.spawnedUnits + 1] )
			self.spawnedUnits = self.spawnedUnits + 1
			if self.spawnedUnits >= self.image_count then
				loop = false
			end
		end
	end
end