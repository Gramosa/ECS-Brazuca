#It's an autoload named JsonLoader
extends Node

var directory_paths_to_load : Array[String] = ["res://json/"]
var jsons_paths : Array[String] = [] # filled with paths of jsons archive by the load_jsons_paths function
var unsorted_json_data : Array = [] # A array with each JSON Object found [{...}, {...}, ...]
#var data_by_category : Dictionary = {}
var data_by_type : Dictionary = {}
var data_by_id: Dictionary = {}
var elements_by_id : Dictionary = {} # All items who have "element" as value of the key "category"

func _init() -> void:
	# Takes all paths of the jsons inside specifieds folders, and fill jsons_paths
	for path in directory_paths_to_load:
		load_jsons_paths(path)
	
	# Load the data of each json archive found in jsons_paths
	for json_path in jsons_paths:
		unsorted_json_data = parse_unsorted_jsons_data_by_path(unsorted_json_data, json_path)
	
	# Organize all unsorted data by a specified individual key and/or coletive key, in this case, "category" and "type"
	# IMPORTANT: Dictionaries organized by "organize_json_data_by_key" and "organize_json_data_by_individual_key" have DIFFERENT structures
	# In the first the "main" key is the colective key, in the second the main key is the individual key adn the colective key does not exist (less nested)
	for data in unsorted_json_data:
		data_by_type = organize_json_data_by_key(data_by_type, data, "type", "id")
		#data_by_category = organize_json_data_by_key(data_by_category, data, "category", "id")
		data_by_id = organize_json_data_by_individual_key(data_by_id, data, "id")
	
	# Take the values usually used, like element
	elements_by_id = data_by_type["element"] #Every item who have the key "type" with value "element"

# This function takes a folder and then take the path of all JSONs files inside this folders, and subfolders using recursion
# All paths are stored in the global variable "jsons_paths".
func load_jsons_paths(folder_path: String) -> void:
	if DirAccess.dir_exists_absolute(folder_path):
		var dir: DirAccess = DirAccess.open(folder_path)
		if dir:
			dir.list_dir_begin()
			var file_name: String = dir.get_next()
			while file_name != "":
				if dir.current_is_dir():
					var subdirectory_path : String = folder_path
					if folder_path in directory_paths_to_load: #the paths in main_paths_to_load already have the "/"
						subdirectory_path += file_name
					else:
						subdirectory_path += "/" + file_name
						
					load_jsons_paths(subdirectory_path)
					
				else:
					var was_appended: bool = false
					if file_name.ends_with(".json"):
						var json_path: String = folder_path
						if folder_path in directory_paths_to_load:
							json_path += file_name
						else:
							json_path += "/" + file_name
						jsons_paths.append(json_path)
						was_appended = true
					
					if not was_appended:
						push_warning("This archive {0}, on {1} is not a .json file, ignored".format([file_name, folder_path]))
							
				file_name = dir.get_next()
		else:
			push_error("An error ocurred when tried to access the directory {0}".format([folder_path]))
	else:
		push_error("path doesn't exist: " + folder_path)

# Load all JSON data from a json file path, the data are parsed in the way it was found
# All 
func parse_unsorted_jsons_data_by_path(unsorted_data: Array, file_path: String) -> Array:
	# Load JSON data from file
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	var content_file: String = file.get_as_text()
	file.close()
	# Parse JSON data into an array
	unsorted_data += JSON.parse_string(content_file)
	return unsorted_data

# OUTDATED DESCRIPTION, CHANGE IN FUTURE
# Keep this in mind when reading: an item can be represented as a dictionary {key: value, ...}, similar to JSON object. Alternatively, an item can be a key that maps to a dictionary as its value, for example: item1: {key: value}, ...
#
# This function takes a Array with a specific structure and a specific key as input and returns a new dictionary.
# The returned dictionary is organized as a hierarchy of nested sub-dictionaries. Here's how it works:
# - Each unique value found in the specified key of the JSON data becomes a separate sub-dictionary within the hierarchy.
# - These sub-dictionaries act as containers for items that share the same value in the specified key.
# - To access an item, you can navigate through the hierarchy based on their unique values in the specified key of the JSON data.
# The purpose is to organize the JSON data into nested dictionaries based on the specified key's values.
# 
# Only makes sense to use this function if the key are a common key between the Json objects, but the values may be different
# 
# nested_dictionary: Dictionary -> A dictionary who will receive the formated dictionary from the json file, not necessary empty, but if not empty this must be with the new structure: {"valueA": {}, "valueB": {}...}
# path: String -> The path of the json file, with the structure [{...}, {...}, {...}, ..., {...}]
# key: String -> the common key between all jsons objects, its means: [{"key" : ValueA}, {"key": ValueB}, {"key": ValueC}, ..., {"key" : ValueZ}]
#
# Example of the previous JSON structure:
# [
#   {
#     "key": "valueA",
#     "id": "item1",
#     // Other item data here
#   },
#   {
#     "key": "valueA",
#     "id": "item2",
#     // Other item data here
#   },
#   // More items with "key" as "valueA"
#   {
#     "key": "valueB",
#     // Other item data here
#   },
#   // More items with "key" as "valueB" or other values
# ]
#
# The structure of the returned dictionary (it will be the content of nested_dictionary if its empty {}:
# {
#     "valueA": {
#         "item1": {
#             "key": "valueA",
#             "id": "item1",
#             # Other item data here
#         },
#         "item2": {
#             "key": "valueA",
#             "id": "item2",
#             # Other item data here
#         },
#         # More items with "key" as "valueA"
#     },
#     "valueB": {
#         # All items that have "key" with the value "valueB"
#     },
#     # More sub-dictionaries for other unique values of the specified key
# }
func organize_json_data_by_key(nested_dictionary: Dictionary, data: Dictionary, coletive_key: String, individual_key: String = "id") -> Dictionary:
	assert(coletive_key in data, "The data: {0} does not have the specified key given by individual_key: {1}".format([data, individual_key]))
	assert(individual_key in data, "The data: {0} does not have the specified key given by individual_key: {1}".format([data, individual_key]))
	# Get the value of the specified coletive_key, and this value will become the key of the new nested dictionary
	var coletive_value: String = data[coletive_key]
	var individual_value: String = data[individual_key]
	
	# Check if the key exists in the new dictionary, create a nested dictionary if it doesn't
	if coletive_value not in nested_dictionary:
		nested_dictionary[coletive_value] = {}

	# Add the data to the appropriate nested dictionary
	nested_dictionary[coletive_value][individual_value] = data
	
	return nested_dictionary

# This function populate the argument organized_dictionary with the described structure
# The data MUST have the individual_key specified
# A simplest function than the organize_json_data_by_key, doesnt need to have a colective key.
# its means a item that have a key and a value shared between more than one JSON Object
# Example of the data structure:
# {
#     "any_key": "valueA",
#     "individual_key": "item1",
#     // Other item data here
# }
# After the changes:
# {
#     "item1" : {
#         "any_key": "valueA",
#         "individual_key": "item1",
#         // Other item data here
#     },
#     "item2"{
#         // The data of item2 if the organized_dicionary already had it
#     }
# }
func organize_json_data_by_individual_key(organized_dictionary: Dictionary, data: Dictionary, individual_key: String = "id"):
	assert(individual_key in data, "The data: {0} does not have the specified key given by individual_key: {1}".format([data, individual_key]))
	# Get the value of the specified coletive_key, and this value will become the key of the new nested dictionary
	var individual_value: String = data[individual_key]
	
	# Check if the key exists in the new dictionary, create a key with the value of the specified key if it doesn't
	if individual_key not in organized_dictionary:
		organized_dictionary[individual_value] = data
	else:
		push_warning(
			"The item with key: {0} and value: {1} already exist, the individual_key must match only the key, but the value need to be different, \
			for example two JSON Objects; 1° \"id\":\"sp_fb1\". The data won't be overriden, will be ignored".format([individual_key, individual_value])
			)
	
	return organized_dictionary

# Only by type and id are implemented yet
func get_data_by_key(key: String = "type") -> Dictionary: #Actualy only the key "type" are allowed
	if key == "id":
		return data_by_id
	elif key == "type":
		return data_by_type
	else:
		return {}
