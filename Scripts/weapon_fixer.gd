extends Node3D

func _ready():
	var anim_player = $AnimationPlayer
	if not anim_player: return


	for anim_name in anim_player.get_animation_list():
		var anim = anim_player.get_animation(anim_name)


		for i in range(anim.get_track_count()):
			var old_path = str(anim.track_get_path(i))


			if "Skeleton3D" in old_path and "/" in old_path:
				var bone_name = old_path.split(":")[1]
				var fixed_path = NodePath("Skeleton3D:" + bone_name)
				anim.track_set_path(i, fixed_path)
