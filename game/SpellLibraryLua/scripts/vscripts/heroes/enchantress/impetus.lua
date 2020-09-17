ability_impetus = {}

LinkLuaModifier( "modifier_ability_impetus", "heroes/enchantress/impetus", LUA_MODIFIER_MOTION_NONE )

function ability_impetus:GetIntrinsicModifierName()
	return "modifier_ability_impetus"
end

function ability_impetus:GetProjectileName()
	return "particles/units/heroes/hero_enchantress/enchantress_impetus.vpcf"
end

function ability_impetus:OnOrbFire( params )
	EmitSoundOn( "Hero_Enchantress.Impetus", self:GetCaster() )
end

function ability_impetus:OnOrbImpact( params )
	local caster = self:GetCaster()
	local target = params.target

	local distance_cap = self:GetSpecialValueFor("distance_cap")
	local distance_dmg = self:GetSpecialValueFor("distance_damage_pct")
	
	local distance = math.min( (caster:GetOrigin()-target:GetOrigin()):Length2D(), distance_cap )
	local damage = distance_dmg/100 * distance

	local damageTable = {
		victim = target,
		attacker = caster,
		damage = damage,
		damage_type = DAMAGE_TYPE_PURE,
		ability = self,
	}

	ApplyDamage(damageTable)

	EmitSoundOn( "Hero_Enchantress.ImpetusDamage", target )
end

modifier_ability_impetus = {}

function modifier_ability_impetus:IsHidden()
	return true
end

function modifier_ability_impetus:IsDebuff()
	return false
end

function modifier_ability_impetus:IsPurgable()
	return false
end

function modifier_ability_impetus:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_ability_impetus:OnCreated( kv )
	self.ability = self:GetAbility()
	self.cast = false
	self.records = {}
end

function modifier_ability_impetus:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK,
		MODIFIER_EVENT_ON_ATTACK_FAIL,
		MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
		MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY,
		MODIFIER_EVENT_ON_ORDER,
		MODIFIER_PROPERTY_PROJECTILE_NAME,
	}
end

function modifier_ability_impetus:OnAttack( params )
	if params.attacker~=self:GetParent() then return end

	if self:ShouldLaunch( params.target ) then
		self.ability:UseResources( true, false, true )

		self.records[params.record] = true

		if self.ability.OnOrbFire then self.ability:OnOrbFire( params ) end
	end

	self.cast = false
end
function modifier_ability_impetus:GetModifierProcAttack_Feedback( params )
	if self.records[params.record] then
		if self.ability.OnOrbImpact then self.ability:OnOrbImpact( params ) end
	end
end
function modifier_ability_impetus:OnAttackFail( params )
	if self.records[params.record] then
		if self.ability.OnOrbFail then self.ability:OnOrbFail( params ) end
	end
end
function modifier_ability_impetus:OnAttackRecordDestroy( params )
	self.records[params.record] = nil
end

function modifier_ability_impetus:OnOrder( params )
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

function modifier_ability_impetus:GetModifierProjectileName()
	if not self.ability.GetProjectileName then return end

	if self:ShouldLaunch( self:GetCaster():GetAggroTarget() ) then
		return self.ability:GetProjectileName()
	end
end

function modifier_ability_impetus:ShouldLaunch( target )
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

function modifier_ability_impetus:FlagExist(a,b)
	local p,c,d=1,0,b
	while a>0 and b>0 do
		local ra,rb=a%2,b%2
		if ra+rb>1 then c=c+p end
		a,b,p=(a-ra)/2,(b-rb)/2,p*2
	end
	return c==d
end