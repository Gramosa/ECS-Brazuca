@tool
extends EditorPlugin

var script_templates_folder: String = "res://script_templates"
var brazuca_templates_folder_path: String = "res://addons/ecs_brazuca/ecs_brazuca_script_templates"
var relative_gd_paths: Array[String]

func _enter_tree() -> void:
	# Create the "res://script_templates if does not exist"
	create_directory(script_templates_folder)
	# Load the gd_paths with the .gd script inside ecs_brazuca_script_template folder and subfolders
	copy_templates_paths(brazuca_templates_folder_path, script_templates_folder)
	# Just refresh the FileSystem
	refresh_file_system()
	
	add_autoload_singleton("BRZMetadata", "res://addons/ecs_brazuca/singletons/metadata.gd")
	
func _exit_tree() -> void:
	#TODO: Verificar porque nao funciona
	#delete_folder_recursive(script_templates_folder)
	refresh_file_system()
	
	remove_autoload_singleton("BRZMetadata")

## Add the templates to the script_templates folder
func copy_templates_paths(core_source_path: String, core_target_path: String, relative_folder_path: String = "") -> void:
	var source_folder_path: String = core_source_path + relative_folder_path
	var target_folder_path: String = core_target_path + relative_folder_path

	var dir: DirAccess = DirAccess.open(source_folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			var current_item_path: String = source_folder_path + "/" + file_name
			var current_target_path: String = target_folder_path + "/" + file_name
			
			if dir.current_is_dir():
				# Create the target directory if it does not exist yet
				create_directory(current_target_path)

				# Recursively copy files from the subdirectory
				copy_templates_paths(core_source_path, core_target_path, relative_folder_path + "/" + file_name)
			else:
				if file_name.ends_with(".gd"):
					relative_gd_paths.append(relative_folder_path + "/" + file_name)
					
					# Copy the file to the target location
					dir.copy(current_item_path, current_target_path)
				else:
					push_warning("This archive {0}, on {1} is not a .gd file, ignored".format([file_name, source_folder_path]))
					
			file_name = dir.get_next()
	else:
		push_error("Was not possible to find/open the templates directory")

func create_directory(source_folder_path: String) -> void:
	if DirAccess.dir_exists_absolute(source_folder_path) == false:
		DirAccess.make_dir_absolute(source_folder_path)

func delete_folder_recursive(path: String) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			var file_path = path + "/" + file_name
			if dir.current_is_dir():
				delete_folder_recursive(file_path)
			else:
				var error: Error = dir.remove(path)
				if error != OK:
					push_error("Failed to delete the file: '{0}".format([file_path]))
			
			file_name = dir.get_next()
	else:
		push_error("Failed to open the directory '{0}".format([path]))

func refresh_file_system() -> void:
	var editor_interface : EditorInterface = get_editor_interface()
	var editor_file_system : EditorFileSystem = editor_interface.get_resource_filesystem()
	editor_file_system.scan()
