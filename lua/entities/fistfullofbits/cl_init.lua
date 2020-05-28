//-----------------------------------------------------------------------------------------------
//
//Client side script of Fist Full Of Bits, responsible for constructing gui
//
//@author Deven Ronquillo
//@version 24/9/17
//-----------------------------------------------------------------------------------------------
include("shared.lua")

//-----------------------------------------------------------------------------------------------
//global vars
//
//-----------------------------------------------------------------------------------------------

surface.CreateFont( "ffobBigFont", {
	font = "Arial", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = 100,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

surface.CreateFont( "ffobSmallFont", {
	font = "Arial", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = 25,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

function ENT:Draw()

	self:DrawModel()

	if LocalPlayer():GetPos():Distance(self:GetPos()) <= 500 then

		local ang = LocalPlayer():GetAngles()

		ang.y = LocalPlayer():GetAngles().y - 90
		ang.p = 0

		ang:RotateAroundAxis( ang:Right(), 0)
		ang:RotateAroundAxis( ang:Forward(), 90)

		cam.Start3D2D( self:GetPos(), ang, 0.1)

			draw.RoundedBox(0,-500,-1325,1000,350,string.ToColor(GetConVar("cl_colorZone3"):GetString()))
			draw.RoundedBox(0,-480,-1225,960,230,string.ToColor(GetConVar("cl_colorZone1"):GetString()))

			draw.SimpleText("Unknown's Bit Stash","ffobBigFont",0,-1270,Color(255,255,255),1,1)
			draw.SimpleText("$"..self:GetMoney(),"ffobBigFont",0,-1100,Color(255,255,255),1,1)
			draw.SimpleText("Touches the butt ^.^ *sirens blare*","ffobSmallFont",0,-1020,Color(255,255,255),1,1)

		cam.End3D2D()
	end
end
		
function Confirmation()

	if( !IsValid(confirmationFrame)) then

		local bitsStash = net.ReadEntity()

		local width = 350
		local height = 200

		confirmationFrame = vgui.Create( "DFrame" )//Main fram for the confimation box ui

		confirmationFrame:SetPos(ScrW()/2 - width/2, ScrH()/2 - height/2)
		confirmationFrame:SetSize( width, height)
		confirmationFrame:SetTitle( "" )
		confirmationFrame:SetDraggable( false )
		confirmationFrame:ShowCloseButton( false )
		confirmationFrame:SetVisible( true )
		confirmationFrame:MakePopup()

		confirmationFrame.Paint = function( self, w, h )
			draw.RoundedBox( 0, 0, 0, w, h, string.ToColor(GetConVar("cl_colorZone3"):GetString()))
			draw.RoundedBox( 0, 5, 5, w-10, h-10, string.ToColor(GetConVar("cl_colorZone1"):GetString()))
		end

		local confirmationText = vgui.Create("DLabel", confirmationFrame)//displays the confimation text

		confirmationText:SetPos(0,75)
		confirmationText:SetSize(340, 25)
		confirmationText:SetFont("ffobSmallFont")
		confirmationText:SetText("Begin the raid?")
		confirmationText:SetColor(Color(255,255,255))
		confirmationText:SetContentAlignment(5)


		local confirmationYesButton = vgui.Create("DButton", confirmationFrame)//the yes buttom

		confirmationYesButton:SetPos(10,160)
		confirmationYesButton:SetSize(80, 30)
		confirmationYesButton:SetFont("ffobSmallFont")
		confirmationYesButton:SetText("Yes")

		confirmationYesButton.DoClick = function ()

			confirmationFrame:Close()

			hook.Add("PostDrawOpaqueRenderables", "ActiveRaidZone", function()

				local ang = bitsStash:GetAngles()

				ang:RotateAroundAxis( bitsStash:GetAngles():Right(), 180)
				ang:RotateAroundAxis( bitsStash:GetAngles():Forward(), 180)
				ang:RotateAroundAxis( bitsStash:GetAngles():Up(), 0)

				cam.Start3D2D( bitsStash:GetPos(), ang, 1)

					//surface.DrawCircle(0,0, 50, string.ToColor(GetConVar("cl_colorZone1"):GetString()))
					surface.SetDrawColor( string.ToColor(GetConVar("cl_colorZone1"):GetString()))
					draw.NoTexture()
					draw.Circle( 0, 0, 400, 25)

				cam.End3D2D()

			end)

			net.Start("FFoB_Raid")

				net.WriteEntity(LocalPlayer())
				net.WriteEntity(bitsStash)
			net.SendToServer()
		end

		local confirmationNohButton = vgui.Create("DButton", confirmationFrame)//the noh button

		confirmationNohButton:SetPos(260, 160)
		confirmationNohButton:SetSize(80, 30)
		confirmationNohButton:SetFont("ffobSmallFont")
		confirmationNohButton:SetText("Noh")

		confirmationNohButton.DoClick = function()

			confirmationFrame:Close()
		end
	end	
end

net.Receive("FFoB_Confirmation",Confirmation)	
net.Receive("FFoB_RaidComplete", function() hook.Remove("PostDrawOpaqueRenderables", "ActiveRaidZone") end)

//--------------------------------------------------------------------------------------
//Helper functions
//--------------------------------------------------------------------------------------

function draw.Circle( x, y, radius, seg )
	local cir = {}

	table.insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
	for i = 0, seg do
		local a = math.rad( ( i / seg ) * -360 )
		table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
	end

	local a = math.rad( 0 ) -- This is needed for non absolute segment counts
	table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )

	surface.DrawPoly( cir )
end
