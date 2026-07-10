extends Node3D

func _ready():
	var anim_player = find_child("AnimationPlayer*", true, false) as AnimationPlayer
	var skeleton = find_child("Skeleton3D*", true, false) as Skeleton3D

	if not anim_player or not skeleton:
		print("[Rifle] ВНИМАНИЕ: Не найден AnimationPlayer или Skeleton3D!")
		return


	var root_for_anims = anim_player.get_node(anim_player.root_node)
	var real_skel_path = str(root_for_anims.get_path_to(skeleton))


	for anim_name in anim_player.get_animation_list():
		var anim = anim_player.get_animation(anim_name)


		for i in range(anim.get_track_count()):
			var old_path = str(anim.track_get_path(i))


			var colon_index = old_path.find(":")
			if colon_index != -1:
				var right_side = old_path.substr(colon_index + 1)


				var fixed_path = NodePath(real_skel_path + ":" + right_side)
				anim.track_set_path(i, fixed_path)
