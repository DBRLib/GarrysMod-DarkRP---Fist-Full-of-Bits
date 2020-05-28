//-----------------------------------------------------------------------------------------------
//
//Server side script for Fist Full Of Bits responsible for proccessing commands from the gui
//
//@author Deven Ronquillo
//@Professional codebreaker: MikomiHooves
//@version 24/9/17
//-----------------------------------------------------------------------------------------------
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

util.AddNetworkString('FFoB_Confirmation')
util.AddNetworkString('FFoB_Raid')
util.AddNetworkString('FFoB_RaidComplete')

teamOnly		= {'Mane-iac',"Mane-iac's Sergeant", "Mane-iac's Goon", 'The Mysterious Mare Do Well'}
lawEnforcement	= {'Equestrian Police', 'Equestrian Police Quartermaster', 'Equestrian Police Chief'}

moneyUpperBound = 25000
goldUpperBound = 288


ENT.ffob_MoneyTime 	= os.time()


//---------------------------
//RAID GLOBS

ENT.money = 0

ENT.exitCode 		= -1
ENT.activeRaid		= false

ENT.raidTime 		= 300
ENT.timerStart 		= nil
ENT.lastTimeCheck   = 1

ENT.raider = nil
ENT.raidThink = false
//----------------------------
//CHILDRENINFO

ENT.children = {}

ENT.childColumnCurrent = -19
ENT.childRowCurrent = -28
ENT.childStackCurrent = 4

ENT.childColumnCount = 1
ENT.childRowCount = 1
ENT.childStackCount = 0

ENT.lastMoneyStamp = 0

//----------------------------


function ENT:Initialize()

	self:SetModel( "models/props_mvm/sack_stack_pallet.mdl" )

	self:SetNPCState(NPC_STATE_SCRIPT)
	self:SetUseType(SIMPLE_USE)

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

	if IsValid(self:GetPhysicsObject()) then

		self:GetPhysicsObject():Wake()
	end

	self:DropToFloor()
	self:SetAngles(Angle(0, 0, 0))

	self.money = 2000
end

function ENT:AcceptInput( Name, Activator, Caller )

	local match = nil
	if Name == "Use" and Caller:IsPlayer() then

		for i, group in pairs(teamOnly) do

			if Caller:getJobTable().name == group then

				match = 1
			end
		end

		if match and !self.activeRaid then

			net.Start('FFoB_Confirmation')

				net.WriteEntity( self )
			net.Send( Caller )
		else

			DarkRP.notify( Caller, 1, 6, "You're not bad to the pone enough to use this or the raid is already active!")
		end
	end
end

function ENT:Think()

	if self.raidThink then 

		local match = 0
		for i, group in pairs(teamOnly) do

			if self.raider:getJobTable().name == group then

				match = 1
			end
		end

		if match != 1 then

			self.exitCode = -1
			self.raidThink = false
			self:RaidComplete(self.raider, self.exitCode)
			return
		end

		if !self.raider:Alive() then 

			self.exitCode = 0
			self.raidThink = false
			self:RaidComplete(self.raider, self.exitCode)
			return

		end

		if self.raider:GetPos():Distance( self:GetPos() ) > 400 then 

			self.exitCode = 2
			self.raidThink = false
			self:RaidComplete(self.raider, self.exitCode)
			return

		end

		if ((os.time() - self.timerStart ) >= self.raidTime ) then

			self.exitCode = 1
			self.raidThink = false
			self:RaidComplete(self.raider, self.exitCode)
			return
		end

		if (os.time() - self.timerStart) % 30 == 0 and (os.time() - self.lastTimeCheck) >= 1 then

			self.lastTimeCheck = os.time()
			local timeLeft = self.raidTime - (os.time() - self.timerStart)
			DarkRP.notify( self.raider, 0, 6, tostring(timeLeft).." Seconds left!")
		end
	else

		self:UpdateMoney()
	end
end

function ENT:Raid()

	if self.activeRaid then

		DarkRP.notify( self.raider, 2, 6, "Raid already in progress.")

		net.Start('FFoB_RaidComplete')
		net.Send(self.raider)

		return
	end

	local enforcement = 0

	for k, v in pairs( player.GetAll() ) do

		if table.HasValue(lawEnforcement, v:getJobTable().name) == true then

			enforcement = enforcement + 1

		end
	end

	local criminal = 0

	for k, v in pairs( player.GetAll() ) do

		if table.HasValue(teamOnly, v:getJobTable().name) == true then

			criminal = criminal + 1
		end
	end

	if criminal/enforcement >= 4/5 then
		DarkRP.notify( self.raider, 2, 6, "Too many self.raiders, not enough cops. ".. math.ceil((criminal/0.8)-enforcement) .." More guards needed to raid.")

		net.Start('FFoB_RaidComplete')
		net.Send(self.raider)
		return
	end

	for k,v in pairs(player.GetAll()) do
		if table.HasValue(lawEnforcement, v:getJobTable().name) == true then
			ffob_Wanter = v
			break
		else ffob_Wanter = Entity( 1 )
		end
	end

	self.activeRaid	= true
	self.raider:wanted(ffob_Wanter, "For taking fists full of bits", 300)
	DarkRP.notify( self.raider, 0, 6, "The raid has started, survive for 5 minutes!")

	self.timerStart = os.time()
	self.raidThink = true
	
end

net.Receive("FFoB_Raid", function()

	local ply 	= net.ReadEntity()
	local bitsStash = net.ReadEntity()

	if(!bitsStash.activeRaid) then

		bitsStash.raider = ply
		bitsStash:Raid()
	else

		net.Start('FFoB_RaidComplete')
		net.Send(ply)
	end
end)

function ENT:RaidComplete()

	//Fatal error
	if self.exitCode == -1 then 

		Darkrp.notify( self.raider, 2, 6, "Invalid arguments, raid cancled.")	
	end

	if self.exitCode == 0 then 
		self:FFoB_PayThePolice()
		//Darkrp.notify( self.raider, 2, 6, "You are ded, better luck next time")-----------------------------------------------------------------------------------need halp here
	end

	//Left area
	if self.exitCode == 2 then 
		self:FFoB_PayThePolice()
		DarkRP.notify( self.raider, 2, 6, "You left the area, raid cancled.")
	end

	//you win!
	if self.exitCode == 1 then 

		DarkRP.notify( self.raider, 0, 6, "You've sucsessfully raided the stash.")
		
		self.raider:addMoney( self.money )

		self.money = 0
		self.lastMoneyStamp = 0

		self:deleteEntityChild()
		self.ffob_MoneyTime = os.time()
	end

	
	net.Start('FFoB_RaidComplete')
	net.Send(self.raider)

	self.activeRaid = false
	self.exitCode = -1
	self.raidTime = 300
	self.raider = nil
end
hook.Add("PlayerDeath", "FFoB_PlayerDed", RaidComplete)

function ENT:FFoB_PayThePolice()
	local copTable = {}



	for k, v in pairs( player.GetAll() ) do

		if table.HasValue(lawEnforcement, v:getJobTable().name) == true then

			copTable[ #copTable + 1 ] = v

		end

	end



	local copMoney = (self.money*0.05)/#copTable

	for k, v in pairs(copTable) do

		v:addMoney( math.ceil( copMoney ))
		DarkRP.notify( v, 0, 6, "You protected the bits from the raider, your reward is " .. math.ceil( copMoney ) .. " .")

	end
end

function ENT:OnRemove()

	if self.children != nil then

		table.Empty(self.children)
	end
end

function ENT:UpdateMoney()

	self.money = (math.ceil( math.Clamp(self.money + (os.time() - self.ffob_MoneyTime),0,moneyUpperBound))) //Multiply (os.time() - ffob_MoneyTime) by an int if you want to scale the money
	self:SetMoney(self.money)

	self.ffob_MoneyTime = os.time()


	if self.lastMoneyStamp < self.money then//checks the entity representation of the money.

		self:addEntityChild(self.lastMoneyStamp, self.money)
	end
end

function ENT:deleteEntityChild()


	indexStart = table.Count(self.children)

	for i = 0, (indexStart - 1) do
		
		self.children[indexStart - i]:Remove()
		table.remove(self.children, (indexStart - i))
	end 

	self.childColumnCurrent = -19
	self.childRowCurrent = -28
	self.childStackCurrent = 4

	self.childColumnCount = 1
	self.childRowCount = 1
	self.childStackCount = 0

	self:GetPhysicsObject():EnableMotion(false)
end

function ENT:addEntityChild(lastMoneyStamp,currentMoney)

	if lastMoneyStamp == currentMoney then return end

	currentPercentageMoney = currentMoney / moneyUpperBound

	if self.children == nil then

		currentPercentageGold = 0
	else

		currentPercentageGold = table.Count(self.children) / goldUpperBound
	end

	entitiesToAdd = math.floor((currentPercentageMoney - currentPercentageGold)*goldUpperBound)

	for i = 1, entitiesToAdd do

		local SelfPos,Up,Right,Forward,Ang = self:GetPos(),self:GetUp(),self:GetRight(),self:GetForward(),self:GetAngles()

		child = ents.Create( "prop_dynamic" )
   		child:SetModel("models/props_mining/ingot001.mdl" )
    	child:SetPos(SelfPos + Up*self.childStackCurrent + Right*self.childRowCurrent + Forward*self.childColumnCurrent)
    	child:SetAngles(Ang)
    	child:SetParent(self)
    	child:SetModelScale(1)

    	child:PhysicsInit(SOLID_VPHYSICS)
		child:SetSolid(SOLID_VPHYSICS)

		if IsValid(child:GetPhysicsObject()) then

			child:GetPhysicsObject():EnableMotion(false)
			child:GetPhysicsObject():Wake()
		end

    	self:DeleteOnRemove(child)

    	child:Spawn()

    	table.insert(self.children, child)

    	if self.childRowCount >= 8 then

    		self.childRowCount = 1
    		self.childRowCurrent = -28

    		if self.childColumnCount == 3 then

    			self.childColumnCount = 1
    			self.childStackCount = self.childStackCount + 1
    			self.childColumnCurrent = -19
    			self.childStackCurrent = self.childStackCurrent + 3
    		else

    			self.childColumnCount = self.childColumnCount + 1
    			self.childColumnCurrent = self.childColumnCurrent + 20

    		end
    	else

    		self.childRowCount = self.childRowCount + 1
    		self.childRowCurrent = self.childRowCurrent + 8
    	end
    end

    self.lastMoneyStamp = currentMoney
end