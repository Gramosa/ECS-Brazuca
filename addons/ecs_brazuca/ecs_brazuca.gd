@tool
extends EditorPlugin

var script_templates_folder: String = "res://script_tempaltes"
var brazuca_templates_folder_path: String = "res://addons/ecs_brazuca/ecs_brazuca_script_templates"
var relative_gd_paths: Array[String]

func _enter_tree() -> void:
	# Create the "res://script_templates if does not exist"
	create_directory(script_templates_folder)
	
	# Load the gd_paths with the .gd script inside ecs_brazuca_script_template folder and subfolders
	copy_templates_paths(brazuca_templates_folder_path, script_templates_folder)
	
	#var temp_dir: DirAccess = DirAccess.open("res://script_templates")
	#temp_dir.copy(gd_paths[0], "res://script_templates/BaseComponent/component_template.gd")

func _exit_tree() -> void:
	pass

## Add the templates to the script_templates folder
func copy_templates_paths(core_source_path: String, core_target_path: String, relative_folder_path: String = ""):
	var source_folder_path: String = core_source_path + relative_folder_path
	var target_folder_path: String = core_target_path
	
	var dir: DirAccess = DirAccess.open(source_folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				# Update the relative_folder_path with the current folder where the dir access are pointing at
				relative_folder_path += "/" + file_name
				# Update the target_folder_path, it was just the core path, but are core + relative
				target_folder_path += relative_folder_path
				# Create the target directory, if does not exist yet
				create_directory(target_folder_path)
				
				copy_templates_paths(core_source_path, core_target_path, relative_folder_path)
					
			else:
				var was_appended: bool = false
				if file_name.ends_with(".gd"):
					var relative_gd_file_path: String = relative_folder_path + "/" + file_name
					relative_gd_paths.append(relative_gd_file_path)
					was_appended = true
					
					#Its in fact the part of the code who copy the files
					dir.copy(core_source_path + relative_gd_file_path, core_target_path + relative_gd_file_path)
					
				if not was_appended:
					push_warning("This archive {0}, on {1} is not a .gd file, ignored".format([file_name, source_folder_path]))
							
			file_name = dir.get_next()

	else:
		push_error("Was not possible to find the templates directory")

func create_directory(source_folder_path: String):
	if DirAccess.dir_exists_absolute(source_folder_path) == false:
		DirAccess.make_dir_absolute(source_folder_path)
