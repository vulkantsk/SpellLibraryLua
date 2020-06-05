function GetDirectoryFromPath(path)
	return path:match("(.*[/\\])")
end

function ModuleRequire(path,file)
	return require(GetDirectoryFromPath(path) .. file)
end

function math.round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

function math.symbolsCount(num)
	return #(string.gsub(tostring(num),"%p+",''))
end

function GetMultipleBountyBonus(hUnit)
	local bonus = 0

	for _,modifier in pairs(hUnit:FindAllModifiers()) do
		if modifier.GetBountyMultiplyBonus then 
			bonus = bonus + modifier:GetBountyMultiplyBonus()
		end 
	end
	return bonus
end 

function table.length(tbl)
	local count = 0 

	for k,v in pairs(tbl) do
		count = count + 1
	end 

	return count
end 

function CDOTA_BaseNPC:FilterModifiers(callback)
	local list = {}
	if not callback then print('[FilterModifiers] Error! Callback not found') return list end
	for k,v in pairs(self:FindAllModifiers()) do
		if callback(v) then 
			table.insert(list,v)
		end 
	end 

	return list
end 

--[[
	ability
	modifier
	duration
	count
	updateStack
	caster
	data
]]
function CDOTA_BaseNPC:AddStackModifier(data)
	data.data = data.data or {}
	data.data.duration = (data.duration or -1)
	if self:HasModifier(data.modifier) then
		local current_stack = self:GetModifierStackCount( data.modifier, data.ability )
		if data.updateStack then
			self:AddNewModifier(data.caster or self, data.ability,data.modifier,data.data)
		end
		self:SetModifierStackCount( data.modifier, data.ability, current_stack + (data.count or 1) )
		if self:GetModifierStackCount( data.modifier, data.ability ) < 1 then
			self:RemoveModifierByName(data.modifier)
		end
	else
		self:AddNewModifier(data.caster or self, data.ability,data.modifier,data.data)
		self:SetModifierStackCount( data.modifier, data.ability, (data.count or 1) )
	end
	return self:GetModifierStackCount( data.modifier, data.ability )
end

function PrintTable(t, indent, done)
	--print ( string.format ('PrintTable type %s', type(keys)) )
	if type(t) ~= "table" then return end
  
	done = done or {}
	done[t] = true
	indent = indent or 0
  
	local l = {}
	for k, v in pairs(t) do
	  table.insert(l, k)
	end
  
	table.sort(l)
	for k, v in ipairs(l) do
	  -- Ignore FDesc
	  if v ~= 'FDesc' then
		local value = t[v]
  
		if type(value) == "table" and not done[value] then
		  done [value] = true
		  print(string.rep ("\t", indent)..tostring(v)..":")
		  PrintTable (value, indent + 2, done)
		elseif type(value) == "userdata" and not done[value] then
		  done [value] = true
		  print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
		  PrintTable ((getmetatable(value) and getmetatable(value).__index) or getmetatable(value), indent + 2, done)
		else
		  if t.FDesc and t.FDesc[v] then
			print(string.rep ("\t", indent)..tostring(t.FDesc[v]))
		  else
			print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
		  end
		end
	  end
	end
  end

 -- https://github.com/Yahnich/Boss-Hunters/blob/6f1f7dc796ac2979932354353d7d5eea8a841b22/game/scripts/vscripts/libraries/utility.lua#L1825-L1853
function CDOTABaseAbility:FireLinearProjectile(FX, velocity, distance, width, data, bDelete, bVision, vision)
	local internalData = data or {}
	local delete = false
	if bDelete then delete = bDelete end
	local provideVision = true
	if bVision then provideVision = bVision end
	local info = {
		EffectName = FX,
		Ability = self,
		vSpawnOrigin = internalData.origin or self:GetCaster():GetAbsOrigin(), 
		fStartRadius = width,
		fEndRadius = internalData.width_end or width,
		vVelocity = velocity,
		fDistance = distance or 1000,
		Source = internalData.source or self:GetCaster(),
		iUnitTargetTeam = internalData.team or DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = internalData.type or DOTA_UNIT_TARGET_ALL,
		iUnitTargetFlags = internalData.type or DOTA_UNIT_TARGET_FLAG_NONE,
		iSourceAttachment = internalData.attach or DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
		bDeleteOnHit = delete,
		fExpireTime = GameRules:GetGameTime() + 10.0,
		bProvidesVision = provideVision,
		iVisionRadius = vision or 100,
		iVisionTeamNumber = self:GetCaster():GetTeamNumber(),
		ExtraData = internalData.extraData
	}
	local projectile = ProjectileManager:CreateLinearProjectile( info )
	return projectile
end

-- https://github.com/Yahnich/Boss-Hunters/blob/6f1f7dc796ac2979932354353d7d5eea8a841b22/game/scripts/vscripts/libraries/utility.lua#L180-L201
function CalculateDistance(ent1, ent2, b3D)
	local pos1 = ent1
	local pos2 = ent2
	if ent1.GetAbsOrigin then pos1 = ent1:GetAbsOrigin() end
	if ent2.GetAbsOrigin then pos2 = ent2:GetAbsOrigin() end
	local vector = (pos1 - pos2)
	if b3D then
		return vector:Length()
	else
		return vector:Length2D()
	end
end
-- https://github.com/Yahnich/Boss-Hunters/blob/6f1f7dc796ac2979932354353d7d5eea8a841b22/game/scripts/vscripts/libraries/utility.lua#L180-L201
function CalculateDirection(ent1, ent2)
	local pos1 = ent1
	local pos2 = ent2
	if ent1.GetAbsOrigin then pos1 = ent1:GetAbsOrigin() end
	if ent2.GetAbsOrigin then pos2 = ent2:GetAbsOrigin() end
	local direction = (pos1 - pos2):Normalized()
	direction.z = 0
	return direction
end
-- https://github.com/Yahnich/Boss-Hunters/blob/6f1f7dc796ac2979932354353d7d5eea8a841b22/game/scripts/vscripts/libraries/utility.lua#L1684-L1697
function CDOTA_Modifier_Lua:StartMotionController()
	if not self:GetParent():IsNull() and not self:IsNull() and self.DoControlledMotion and self:GetParent():HasMovementCapability() then
		self:GetParent():StopMotionControllers()
		self:GetParent():InterruptMotionControllers(true)
		self.controlledMotionTimer = Timers:CreateTimer(function()
			if pcall( function() self:DoControlledMotion() end ) then
				return 0.03
			elseif not self:IsNull() then
				self:Destroy()
			end
		end)
	else
	end
end

-- https://github.com/Yahnich/Boss-Hunters/blob/6f1f7dc796ac2979932354353d7d5eea8a841b22/game/scripts/vscripts/libraries/utility.lua#L1754-L1758
function CDOTA_Modifier_Lua:StopMotionController(bForceDestroy)
	FindClearSpaceForUnit(self:GetParent(), self:GetParent():GetAbsOrigin(), true)
	if self.controlledMotionTimer then Timers:RemoveTimer(self.controlledMotionTimer) end
	if bForceDestroy then self:Destroy() end
end
-- https://github.com/Yahnich/Boss-Hunters/blob/6f1f7dc796ac2979932354353d7d5eea8a841b22/game/scripts/vscripts/libraries/utility.lua#L1760-L1767
function CDOTA_BaseNPC:StopMotionControllers(bForceDestroy)
	if self.InterruptMotionControllers then self:InterruptMotionControllers(true) end
	for _, modifier in ipairs( self:FindAllModifiers() ) do
		if modifier.controlledMotionTimer then 
			modifier:StopMotionController(bForceDestroy)
		end
	end
end