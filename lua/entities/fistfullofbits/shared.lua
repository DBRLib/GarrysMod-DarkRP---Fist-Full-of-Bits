//-----------------------------------------------------------------------------------------------
//
//shared file for information revolving the entity of Fist Full Of Bits and its location in the spawn menu
//
//@author Deven Ronquilloa
//@version 6/2/17
//-----------------------------------------------------------------------------------------------
ENT.Type = "ai"
ENT.Base = "base_ai"

ENT.Spawnable = true
ENT.AdminSpawnable = true

ENT.Author = "Luna <3"

ENT.Category = "Fist Full Of Bits"
ENT.PrintName = "Unknown's Bit Stash"
ENT.Instructions = "This is a joke, aye Blondie?"

function ENT:SetupDataTables()

    self:NetworkVar("Float",0,"Money")
end