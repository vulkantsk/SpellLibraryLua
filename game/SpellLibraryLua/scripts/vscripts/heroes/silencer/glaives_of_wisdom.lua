LinkLuaModifier( "modifier_ability_glaives_of_wisdom", "heroes/silencer/glaives_of_wisdom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_glaives_of_wisdom_orb", "heroes/silencer/glaives_of_wisdom", LUA_MODIFIER_MOTION_NONE )

ability_glaives_of_wisdom = {}

function ability_glaives_of_wisdom:GetIntrinsicModifierName()
	return "modifier_ability_glaives_of_wisdom"
end

function ability_glaives_of_wisdom:CastFilterResultTarget( hTarget )
	local flag = 0
	if self:GetCaster():HasScepter() then
		flag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES 
	end

	local nResult = UnitFilter(
		hTarget,
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
		flag,
		self:GetCaster():GetTeamNumber()
	)
	if nResult ~= UF_SUCCESS then
		return nResult
	end

	return UF_SUCCESS
end

function ability_glaives_of_wisdom:GetProjectileName()
	return "particles/units/heroes/hero_silencer/silencer_glaives_of_wisdom.vpcf"
end

function ability_glaives_of_wisdom:OnOrbFire( params )
	EmitSoundOn( "Hero_Silencer.GlaivesOfWisdom", self:GetCaster() )
end

function ability_glaives_of_wisdom:OnOrbImpact( params )
	local caster = self:GetCaster()
	local int_mult = self:GetSpecialValueFor( "intellect_damage_pct" )
	local damage = caster:GetIntellect() * int_mult/100
	if caster:HasScepter() then
		damage = damage*2
	end

	local damageTable = {
		victim = params.target,
		attacker = caster,
		damage = damage,
		damage_type = self:GetAbilityDamageType(),
		ability = self,
	}
	ApplyDamage(damageTable)

	SendOverheadEventMessage(
		nil,
		OVERHEAD_ALERT_BONUS_SPELL_DAMAGE,
		params.target,
		damage,
		nil
	)

	EmitSoundOn( "Hero_Silencer.GlaivesOfWisdom.Damage", params.target )
end

modifier_ability_glaives_of_wisdom = {}

function modifier_ability_glaives_of_wisdom:IsHidden()
	return false
end

function modifier_ability_glaives_of_wisdom:IsDebuff()
	return false
end

function modifier_ability_glaives_of_wisdom:IsPurgable()
	return false
end

function modifier_ability_glaives_of_wisdom:OnCreated( kv )
	self.radius = self:GetAbility():GetSpecialValueFor( "steal_range" )
	self.steal = 2

	if not IsServer() then return end

	self:GetParent():AddNewModifier(
		self:GetCaster(),
		self:GetAbility(),
		"modifier_ability_glaives_of_wisdom_orb",
		{}
	)
end

function modifier_ability_glaives_of_wisdom:OnRefresh( kv )
	self.radius = self:GetAbility():GetSpecialValueFor( "steal_range" )
	self.steal = 2

	if not IsServer() then return end
end

function modifier_ability_glaives_of_wisdom:DeclareFunctions()
	return { MODIFIER_EVENT_ON_HERO_KILLED }
end

function modifier_ability_glaives_of_wisdom:OnHeroKilled( params )
	if not IsServer() then return end

	if params.target:GetTeamNumber() == self:GetParent():GetTeamNumber() then return end

	if params.attacker==self:GetParent() then
		self:Steal( params.target )
		return
	end

	local distance = (params.target:GetOrigin()-self:GetParent():GetOrigin()):Length2D()

	if distance<=self.radius then
		self:Steal( params.target )
	end
end

function modifier_ability_glaives_of_wisdom:Steal( target )
	local steal = self.steal
	local target_int = target:GetBaseIntellect()
	if target_int<=1 then
		steal = 0
	elseif target_int-steal<1 then
		steal = target_int-1
	end

	self:GetParent():SetBaseIntellect( self:GetParent():GetBaseIntellect() + steal )
	target:SetBaseIntellect( target_int - steal )

	self:SetStackCount( self:GetStackCount() + steal )

	SendOverheadEventMessage(
		nil,
		OVERHEAD_ALERT_MANA_ADD,
		self:GetParent(),
		steal,
		nil
	)
	SendOverheadEventMessage(
		nil,
		OVERHEAD_ALERT_MANA_LOSS,
		target,
		steal,
		nil
	)
end

modifier_ability_glaives_of_wisdom_orb = {}

function modifier_ability_glaives_of_wisdom_orb:IsHidden()
	return true
end

function modifier_ability_glaives_of_wisdom_orb:IsDebuff()
	return false
end

function modifier_ability_glaives_of_wisdom_orb:IsPurgable()
	return false
end

function modifier_ability_glaives_of_wisdom_orb:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_ability_glaives_of_wisdom_orb:OnCreated( kv )
	self.ability = self:GetAbility()
	self.cast = false
	self.records = {}
end

function modifier_ability_glaives_of_wisdom_orb:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK,
		MODIFIER_EVENT_ON_ATTACK_FAIL,
		MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
		MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY,
		MODIFIER_EVENT_ON_ORDER,
		MODIFIER_PROPERTY_PROJECTILE_NAME
	}
end

function modifier_ability_glaives_of_wisdom_orb:OnAttack( params )
	if params.attacker~=self:GetParent() then return end

	if self:ShouldLaunch( params.target ) then
		self.ability:UseResources( true, false, true )

		self.records[params.record] = true

		if self.ability.OnOrbFire then
			self.ability:OnOrbFire( params )
		end
	end

	self.cast = false
end
function modifier_ability_glaives_of_wisdom_orb:GetModifierProcAttack_Feedback( params )
	if self.records[params.record] then
		if self.ability.OnOrbImpact then self.ability:OnOrbImpact( params ) end
	end
end
function modifier_ability_glaives_of_wisdom_orb:OnAttackFail( params )
	if self.records[params.record] then
		if self.ability.OnOrbFail then self.ability:OnOrbFail( params ) end
	end
end
function modifier_ability_glaives_of_wisdom_orb:OnAttackRecordDestroy( params )
	self.records[params.record] = nil
end

function modifier_ability_glaives_of_wisdom_orb:OnOrder( params )
	if params.unit~=self:GetParent() then return end

	if params.ability then
		if params.ability==self:GetAbility() then
			self.cast = true
			return
		end

		local pass = false
		local behavior = tonumber( tostring( params.ability:GetBehavior() ) )
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

function modifier_ability_glaives_of_wisdom_orb:GetModifierProjectileName()
	if not self.ability.GetProjectileName then return end

	if self:ShouldLaunch( self:GetCaster():GetAggroTarget() ) then
		return self.ability:GetProjectileName()
	end
end

function modifier_ability_glaives_of_wisdom_orb:ShouldLaunch( target )
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

function modifier_ability_glaives_of_wisdom_orb:FlagExist(a,b)
	local p,c,d=1,0,b
	while a>0 and b>0 do
		local ra,rb=a%2,b%2
		if ra+rb>1 then c=c+p end
		a,b,p=(a-ra)/2,(b-rb)/2,p*2
	end
	return c==d
end