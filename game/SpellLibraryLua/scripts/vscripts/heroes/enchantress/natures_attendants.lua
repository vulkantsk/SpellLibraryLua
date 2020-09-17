ability_natures_attendants = {}

LinkLuaModifier( "modifier_ability_natures_attendants", "heroes/enchantress/natures_attendants", LUA_MODIFIER_MOTION_NONE )

function ability_natures_attendants:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetDuration()

	caster:AddNewModifier(
		caster,
		self,
		"modifier_ability_natures_attendants",
		{ duration = duration }
	)
end

modifier_ability_natures_attendants = {}

function modifier_ability_natures_attendants:IsHidden()
	return false
end

function modifier_ability_natures_attendants:IsDebuff()
	return false
end

function modifier_ability_natures_attendants:IsPurgable()
	return false
end

function modifier_ability_natures_attendants:OnCreated( kv )
	self.count = self:GetAbility():GetSpecialValueFor( "wisp_count" )
	self.heal = self:GetAbility():GetSpecialValueFor( "heal" )
	self.interval = self:GetAbility():GetSpecialValueFor( "heal_interval" )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )

	if IsServer() then
		self:SetDuration(kv.duration+0.1,false)

		self:StartIntervalThink( self.interval )

		EmitSoundOn( "Hero_Enchantress.NaturesAttendantsCast", self:GetParent() )
	end
end

function modifier_ability_natures_attendants:OnRefresh( kv )
	self.count = self:GetAbility():GetSpecialValueFor( "wisp_count" )
	self.heal = self:GetAbility():GetSpecialValueFor( "heal" )
	self.interval = self:GetAbility():GetSpecialValueFor( "heal_interval" )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )

	if IsServer() then
		self:SetDuration(kv.duration+0.1,false)
		
		self:StartIntervalThink( self.interval )
	end	
end

function modifier_ability_natures_attendants:OnDestroy( kv )
	if IsServer() then
		StopSoundOn( "Hero_Enchantress.NaturesAttendantsCast", self:GetParent() )
	end
end

function modifier_ability_natures_attendants:OnIntervalThink()
	local allies = FindUnitsInRadius(
		self:GetParent():GetTeamNumber(),
		self:GetParent():GetOrigin(),
		nil,
		self.radius,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
		0,
		false
	)

	local targets = {}
	for i,ally in pairs(allies) do
		if ally:GetHealthPercent()<100 then
			table.insert( targets, i )
		end
	end
	if #targets<1 then return end
	local n = #targets

	for i=1,self.count do
		allies[targets[RandomInt(1,n)]]:Heal( self.heal, self:GetAbility() )
	end
end