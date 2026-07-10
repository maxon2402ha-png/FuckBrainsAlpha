extends Node3D

func _ready():
	var anim_player = find_child("AnimationPlayer", true, false)
	if not anim_player: return

	var root_node = anim_player.get_node(anim_player.root_node)


	var hands_skel = find_child("Skeleton3D", true, false)
	var gun_skel = find_child("GunSkeleton", true, false)

	var new_library = AnimationLibrary.new()

	for lib_name in anim_player.get_animation_library_list():
		var lib = anim_player.get_animation_library(lib_name)

		for anim_name in lib.get_animation_list():
			var anim = lib.get_animation(anim_name).duplicate()


			var l_name = anim_name.to_lower()
			if "idle" in l_name or "walk" in l_name or "run" in l_name or "hold" in l_name:
				anim.loop_mode = Animation.LOOP_LINEAR
			else:
				anim.loop_mode = Animation.LOOP_NONE


			for i in range(anim.get_track_count() - 1, -1, -1):
				var old_path = str(anim.track_get_path(i))


				if not ":" in old_path or ":position" in old_path or ":rotation" in old_path or ":scale" in old_path:
					anim.remove_track(i)
					continue


				var bone_name = old_path.split(":")[1]
				var new_path = ""


				if hands_skel and hands_skel.find_bone(bone_name) != -1:
					new_path = str(root_node.get_path_to(hands_skel)) + ":" + bone_name
				elif gun_skel and gun_skel.find_bone(bone_name) != -1:
					new_path = str(root_node.get_path_to(gun_skel)) + ":" + bone_name


				if new_path != "":
					anim.track_set_path(i, NodePath(new_path))
				else:
					anim.remove_track(i)

			new_library.add_animation(anim_name, anim)

		anim_player.remove_animation_library(lib_name)

	anim_player.add_animation_library("", new_library)
	print("[Код-Фикс] ГОТОВО! Злые координаты удалены. Дробовик привязан к руке!")
