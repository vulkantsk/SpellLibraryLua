LinkLuaModifier( "modifier_ability_liquid_fire_orb", "heroes/jakiro/liquid_fire", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_liquid_fire", "heroes/jakiro/liquid_fire", LUA_MODIFIER_MOTION_NONE )

ability_liquid_fire = {}

function ability_liquid_fire:GetIntrinsicModifierName()
	return "modifier_ability_liquid_fire_orb"
end

function ability_liquid_fire:GetProjectileName()
	return "particles/units/heroes/hero_jakiro/jakiro_base_attack_fire.vpcf"
end

function ability_liquid_fire:OnOrbFire( params )
	EmitSoundOn( "Hero_Jakiro.LiquidFire", self:GetCaster() )
end

function ability_liquid_fire:OnOrbImpact( params )
	local caster = self:GetCaster()
	local duration = self:GetDuration()
	local radius = self:GetSpecialValueFor( "radius" )

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		params.target:GetOrigin(),
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_BUILDING,
		0,
		0,
		false
	)

	for _,enemy in pairs(enemies) do
		enemy:AddNewModifier(
			caster,
			self,
			"modifier_ability_liquid_fire",
			{ duration = duration }
		)
		
	end

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_jakiro/jakiro_liquid_fire_explosion.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		params.target
	)
	ParticleManager:SetParticleControl( effect_cast, 1, Vector( radius, radius, radius ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_Jakiro.LiquidFire", self:GetCaster() )
end

modifier_ability_liquid_fire = {}

function modifier_ability_liquid_fire:IsHidden()
	return false
end

function modifier_ability_liquid_fire:IsDebuff()
	return true
end

function modifier_ability_liquid_fire:IsStunDebuff()
	return false
end

function modifier_ability_liquid_fire:IsPurgable()
	return true
end

function modifier_ability_liquid_fire:OnCreated( kv )
	local damage = self:GetAbility():GetSpecialValueFor( "damage" )
	self.slow = self:GetAbility():GetSpecialValueFor( "slow_attack_speed_pct" )

	if not IsServer() then return end

	self.damageTable = {
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage = damage,
		damage_type = self:GetAbility():GetAbilityDamageType(),
		ability = self:GetAbility(),
	}

	self:StartIntervalThink( 0.5 )
end

function modifier_ability_liquid_fire:OnRefresh( kv )
	local damage = self:GetAbility():GetSpecialValueFor( "damage" )
	self.slow = self:GetAbility():GetSpecialValueFor( "slow_attack_speed_pct" )

	if not IsServer() then return end

	self.damageTable.damage = damage	
end

function modifier_ability_liquid_fire:DeclareFunctions()
	return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end

function modifier_ability_liquid_fire:GetModifierAttackSpeedBonus_Constant()
	return self.slow
end

function modifier_ability_liquid_fire:OnIntervalThink()
	ApplyDamage( self.damageTable )
end

function modifier_ability_liquid_fire:GetEffectName()
	return "particles/units/heroes/hero_jakiro/jakiro_liquid_fire_debuff.vpcf"
end

function modifier_ability_liquid_fire:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

modifier_ability_liquid_fire_orb = {}

function modifier_ability_liquid_fire_orb:IsHidden()
	return true
end

function modifier_ability_liquid_fire_orb:IsDebuff()
	return false
end

function modifier_ability_liquid_fire_orb:IsPurgable()
	return false
end

function modifier_ability_liquid_fire_orb:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_ability_liquid_fire_orb:OnCreated( kv )
	self.ability = self:GetAbility()
	self.cast = false
	self.records = {}
end

function modifier_ability_liquid_fire_orb:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK,
		MODIFIER_EVENT_ON_ATTACK_FAIL,
		MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
		MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY,
		MODIFIER_EVENT_ON_ORDER,
		MODIFIER_PROPERTY_PROJECTILE_NAME
	}
end

function modifier_ability_liquid_fire_orb:OnAttack( params )
	if params.attacker ~= self:GetParent() then return end

	if self:ShouldLaunch( params.target ) then
		self.ability:UseResources( true, false, true )

		self.records[params.record] = true

		if self.ability.OnOrbFire then self.ability:OnOrbFire( params ) end
	end

	self.cast = false
end

function modifier_ability_liquid_fire_orb:GetModifierProcAttack_Feedback( params )
	if self.records[params.record] then
		if self.ability.OnOrbImpact then self.ability:OnOrbImpact( params ) end
	end
end

function modifier_ability_liquid_fire_orb:OnAttackFail( params )
	if self.records[params.record] then
		if self.ability.OnOrbFail then self.ability:OnOrbFail( params ) end
	end
end

function modifier_ability_liquid_fire_orb:OnAttackRecordDestroy( params )
	self.records[params.record] = nil
end

function modifier_ability_liquid_fire_orb:OnOrder( params )
	if params.unit~=self:GetParent() then return end

	if params.ability then
		if params.ability==self:GetAbility() then
			self.cast = true
			return
		end

		local pass = false
		local behavior = params.ability:GetBehavior()
		if self:FlagExist( behavior, DOTA_ABILITY_BEHAVIOR_DONT_CANCEL_CHANNEL ) or 
			self:FlagExist( behavior, DOTA_ABILITY_BEHAVIOR_DONT_CANCEL_MOVEMENT ) or
			self:FlagExist( behavior, DOTA_ABILITY_BEHAVIOR_IGNORE_CHANNEL )
		then
			local pass = true
		end

		if self.cast and (not pass) then
			self.cast = false
		end
	else
		if self.cast then
			if self:FlagExist( params.order_type, DOTA_UNIT_ORDER_MOVE_TO_POSITION ) or
				self:FlagExist( params.order_type, DOTA_UNIT_ORDER_MOVE_TO_TARGET )	or
				self:FlagExist( params.order_type, DOTA_UNIT_ORDER_ATTACK_MOVE ) or
				self:FlagExist( params.order_type, DOTA_UNIT_ORDER_ATTACK_TARGET ) or
				self:FlagExist( params.order_type, DOTA_UNIT_ORDER_STOP ) or
				self:FlagExist( params.order_type, DOTA_UNIT_ORDER_HOLD_POSITION )
			then
				self.cast = false
			end
		end
	end
end

function modifier_ability_liquid_fire_orb:GetModifierProjectileName()
	if not self.ability.GetProjectileName then return end

	if self:ShouldLaunch( self:GetCaster():GetAggroTarget() ) then
		return self.ability:GetProjectileName()
	end
end

function modifier_ability_liquid_fire_orb:ShouldLaunch( target )
	if self.ability:GetAutoCastState() then
		if self.ability.CastFilterResultTarget~=CDOTA_Ability_Lua.CastFilterResultTarget then
			if self.ability:CastFilterResultTarget( target )==UF_SUCCESS then
				self.cast = true
			end
		else
			local nResult = UnitFilter(
				target,
				self.ability:GetAbilityTargetTeam(),
				self.ability:GetAbilityTargetType(),
				self.ability:GetAbilityTargetFlags(),
				self:GetCaster():GetTeamNumber()
			)
			if nResult == UF_SUCCESS then
				self.cast = true
			end
		end
	end

	if self.cast and self.ability:IsFullyCastable() and (not self:GetParent():IsSilenced()) then
		return true
	end

	return false
end

function modifier_ability_liquid_fire_orb:FlagExist(a,b)
	a=tonumber(a)
	b=tonumber(b)
	local p,c,d=1,0,b
	while a>0 and b>0 do
		local ra,rb=a%2,b%2
		if ra+rb>1 then c=c+p end
		a,b,p=(a-ra)/2,(b-rb)/2,p*2
	end
	return c==d
end