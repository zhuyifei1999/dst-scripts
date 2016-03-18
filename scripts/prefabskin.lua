require("class")
require("prefabs")

local BACKPACK_DECAY_TIME = 3 * TUNING.TOTAL_DAY_TIME -- will decay after this amount of time on the ground

--tuck_torso = "full" - torso goes behind pelvis slot
--tuck_torso = "none" - torso goes above the skirt
--tuck_torso = "skirt" - torso goes betwen the skirt and pelvis (the default)
BASE_TORSO_TUCK = {}

BASE_ALTERNATE_FOR_BODY = {}
BASE_ALTERNATE_FOR_SKIRT = {}

BASE_LEGS_SIZE = {}
BASE_FEET_SIZE = {}

SKIN_FX_PREFAB = {}

function backpack_dropped(inst)
	if not inst.decayed then
		inst.decay_task = inst:DoTaskInTime( BACKPACK_DECAY_TIME, backpack_decay_fn )
		inst.target_decay_time = GetTime() + BACKPACK_DECAY_TIME
		--print("target decay time ", inst.target_decay_time)
	end
end
function backpack_pickedup(inst)
	if not inst.decayed then
		if inst.decay_task then inst.decay_task:Cancel() end
		inst.target_decay_time = nil
		--print("stop decay")
	end
end 
function backpack_decay_fn(inst)
	inst.AnimState:SetSkin("swap_backpack_mushy", "swap_backpack")
	inst.skin_build_name = "swap_backpack_mushy"
	inst.override_skinname = "backpack_mushy"
	inst.replica.inventoryitem:SetImage("backpack_mushy")
	inst.decayed = true
	inst.target_decay_time = nil
	--print("decayed")
end

function backpack_decay_long_update(inst, dt)
	if not inst.decayed then
		if inst.decay_task then inst.decay_task:Cancel() end
		
		if inst.target_decay_time ~= nil then
			if GetTime() + dt > inst.target_decay_time then
				backpack_decay_fn(inst)
			else
				inst.target_decay_time = inst.target_decay_time - dt
				inst.decay_task = inst:DoTaskInTime( inst.target_decay_time - GetTime(), backpack_decay_fn )
			end
		end
	end
end


function backpack_init_fn(inst, build_name)
    inst.AnimState:SetSkin(build_name, "swap_backpack")

    inst:ListenForEvent("ondropped", backpack_dropped)
	inst:ListenForEvent("onputininventory", backpack_pickedup)

	inst.OnSave = backpack_skin_save_fn
	inst.OnLoad = backpack_skin_load_fn
	inst.OnLongUpdate = backpack_decay_long_update
	
    inst.replica.inventoryitem:SetImage(inst:GetSkinName())
end

function backpack_skin_save_fn(inst, data)
	if inst.target_decay_time ~= nil then
		local remaining_decay_time = inst.target_decay_time - GetTime()
		data.remaining_decay_time = remaining_decay_time
		--print("saving drop time left", remaining_decay_time)
	end
	data.decayed = inst.decayed
	--print("saving decayed state", data.decayed )
end

function backpack_skin_load_fn(inst, data)
	if not data.decayed then
		if data.remaining_decay_time ~= nil then
			inst.target_decay_time = GetTime() + data.remaining_decay_time
			inst.decay_task = inst:DoTaskInTime( data.remaining_decay_time, backpack_decay_fn )
			--print("loading drop time", GetTime(), data.remaining_decay_time, inst.target_decay_time)
		end
	else
		backpack_decay_fn(inst)
	end
end


function backpack_init_fn_no_decay(inst, build_name)
    inst.AnimState:SetSkin(build_name, "swap_backpack")
    inst.replica.inventoryitem:SetImage(inst:GetSkinName())
end


function torch_init_fn(inst, build_name)
    inst.AnimState:SetSkin(build_name, "swap_torch")
	
    inst.replica.inventoryitem:SetImage(inst:GetSkinName())
end


function CreatePrefabSkin( name, info )
	local prefab_skin = Prefab(name, nil, info.assets, info.prefabs)
	prefab_skin.is_skin = true
	
	prefab_skin.base_prefab			= info.base_prefab or ""
	prefab_skin.ui_preview			= info.ui_preview
	prefab_skin.tags				= info.tags or {}
	prefab_skin.item_type			= info.item_type or "CHARACTER_SKIN"
	prefab_skin.init_fn				= info.init_fn
	prefab_skin.build_name			= info.build_name
	prefab_skin.rarity				= info.rarity
	prefab_skin.skins				= info.skins
	prefab_skin.skip_item_gen		= info.skip_item_gen
	prefab_skin.skip_giftable_gen	= info.skip_giftable_gen
	
	if info.torso_tuck_builds then
		for _,base_skin in pairs(info.torso_tuck_builds) do
			BASE_TORSO_TUCK[base_skin] = "full"
		end
	end
	
	if info.torso_untuck_builds then
		for _,base_skin in pairs(info.torso_untuck_builds) do
			BASE_TORSO_TUCK[base_skin] = "untucked"
		end
	end
	
	if info.has_alternate_for_body then
		for _,base_skin in pairs(info.has_alternate_for_body) do
			BASE_ALTERNATE_FOR_BODY[base_skin] = true
		end
	end
	
	if info.has_alternate_for_skirt then
		for _,base_skin in pairs(info.has_alternate_for_skirt) do
			BASE_ALTERNATE_FOR_SKIRT[base_skin] = true
		end
	end
	
	if info.legs_cuff_size then
		for base_skin,size in pairs(info.legs_cuff_size) do
			BASE_LEGS_SIZE[base_skin] = size
		end
	end
	
	if info.feet_cuff_size then
		for base_skin,size in pairs(info.feet_cuff_size) do
			BASE_FEET_SIZE[base_skin] = size
		end
	end
	
	if info.fx_prefab ~= nil then
		SKIN_FX_PREFAB[name] = info.fx_prefab
	end
	
	
	return prefab_skin
end
