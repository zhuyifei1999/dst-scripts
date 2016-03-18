-- AUTOGENERATED CODE BY export_accountitems.lua

PREFAB_SKINS = {
	backpack = 
	{
		"backpack_basic_blue_catcoon",
		"backpack_basic_green_olive",
		"backpack_bat",
		"backpack_beefalo",
		"backpack_buckle_grey_pewter",
		"backpack_buckle_navy_phthalo",
		"backpack_buckle_red_rook",
		"backpack_camping_green_viridian",
		"backpack_camping_orange_carrot",
		"backpack_camping_red_koalefant",
		"backpack_dragonfly_fire",
		"backpack_mushy",
		"backpack_poop",
		"backpack_rabbit",
		"backpack_smallbird",
		"backpack_spider",
	},
	cookpot = 
	{
		"cookpot_survival",
	},
	torch = 
	{
		"torch_rag",
	},
	wathgrithr = 
	{
		"wathgrithr_none",
		"wathgrithr_formal",
		"wathgrithr_survivor",
	},
	webber = 
	{
		"webber_none",
		"webber_formal",
		"webber_survivor",
	},
	wendy = 
	{
		"wendy_none",
		"wendy_formal",
		"wendy_survivor",
	},
	wes = 
	{
		"wes_none",
		"wes_formal",
		"wes_survivor",
	},
	wickerbottom = 
	{
		"wickerbottom_none",
		"wickerbottom_formal",
		"wickerbottom_survivor",
	},
	willow = 
	{
		"willow_none",
		"willow_formal",
		"willow_survivor",
	},
	wilson = 
	{
		"wilson_none",
		"wilson_formal",
		"wilson_survivor",
	},
	wolfgang = 
	{
		"wolfgang_none",
		"wolfgang_formal",
		"wolfgang_survivor",
	},
	woodie = 
	{
		"woodie_none",
		"woodie_formal",
		"woodie_survivor",
	},
	wx78 = 
	{
		"wx78_none",
		"wx78_formal",
		"wx78_survivor",
	},

}

PREFAB_SKINS_IDS = {}
for prefab,skins in pairs(PREFAB_SKINS) do
	PREFAB_SKINS_IDS[prefab] = {}
	for k,v in pairs(skins) do
		PREFAB_SKINS_IDS[prefab][v] = k
	end
end
