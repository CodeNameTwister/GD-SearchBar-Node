@tool
@icon("res://addons/search_bar_node/search.svg")
extends LineEdit
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	SearchBarNode
#	https://github.com/CodeNameTwister/GD-SearchBar-Node
#
#	Search Bar Node addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

enum SEARCH_BY {
	SINGLE_ROOT_NODE,
	MULTI_ROOT_NODE,
	GROUP_NAME_NODE
}

@export_category("Search By")
@export var search_by : SEARCH_BY = SEARCH_BY.SINGLE_ROOT_NODE:
	set(e):
		search_by = e
		property_list_changed.emit()
		update_configuration_warnings()

@export var root_node_to_search : Node:
	set(e):
		if !Engine.is_editor_hint() and root_nodes_to_search:
			for root_node_search : Node in root_nodes_to_search:
				if root_node_search:
					if root_node_search.child_entered_tree.is_connected(_queue_update):
						root_node_search.child_entered_tree.disconnect(_queue_update)
					if root_node_search.child_exiting_tree.is_connected(_queue_update):
						root_node_search.child_exiting_tree.disconnect(_queue_update)
		root_node_to_search = e
		if !Engine.is_editor_hint():
			for root_node_search : Node in root_nodes_to_search:
				if root_node_search:
					if !root_node_search.child_entered_tree.is_connected(_queue_update):
						root_node_search.child_entered_tree.connect(_queue_update)
					if !root_node_search.child_exiting_tree.is_connected(_queue_update):
						root_node_search.child_exiting_tree.connect(_queue_update)
			_queue_update()	
		else:
			update_configuration_warnings()

## Node where filter object (WARNING: Not use a node has contain this node!)
@export var root_nodes_to_search : Array[Node] = []:
	set(e):
		root_nodes_to_search = e
		if OS.is_debug_build():
			for node : Node in root_nodes_to_search:
				var found : Node = node.find_child(name)
				if found == self:
					found = null
					printerr("SearchBarNode can not be contained by a root node to search, unexpected behaviour!")
					return
		if !Engine.is_editor_hint():
			for root_node_search : Node in root_nodes_to_search:
				if root_node_search:
					if root_node_search.child_entered_tree.is_connected(_queue_update):
						root_node_search.child_entered_tree.connect(_queue_update)
					if root_node_search.child_exiting_tree.is_connected(_queue_update):
						root_node_search.child_exiting_tree.connect(_queue_update)
			_queue_update()	
		else:
			update_configuration_warnings()
			
@export var group_name : PackedStringArray = []:
	set(e):
		group_name = e
		if !Engine.is_editor_hint():
			_queue_update()
		else:
			update_configuration_warnings()

@export_category("Settings")
## Add any filter you want, can be property of script too!, default: ["text", "value"]
@export var filters : Array[StringName] = [&"text", &"value"]

## Ignore if upper or lower, example if true: Hello" is equal to "hello" otherside if false: "Hello" is not equal to "hello"
@export var equal_ignore_case : bool = true

## Discard other nodes if you have found an exact match list and the others are only close but not equal!
@export var discard_similars : bool = true

var _last_search_buffer0 : Array[Node] = []
var _last_search_buffer1 : Array[Node] = []

#region USER_FUNCTIONS
## Returns all items found in the matching search.
func get_all_found_elements() -> Array[Node]:
	var output : Array[Node] = _last_search_buffer0.duplicate()
	output.append_array(_last_search_buffer1)
	return output
	
## Return true or false if any elements matching in the search.
func has_found_elements() -> bool:
	return _last_search_buffer0.size() > 0 or _last_search_buffer1.size() > 0
	
## Get values ​​as equeal to the match value.
func get_full_match_searched_elements() -> Array[Node]:
	return _last_search_buffer0

## Get values ​​similar or close to the match value.
func get_similar_searched_elements() -> Array[Node]:
	return _last_search_buffer1

## Validate the node if a filter is required.
func _is_valid_node(node : Node) -> bool:
	return node is Control or node is Node2D or node is Node3D
#endregion

func _get_configuration_warnings() -> PackedStringArray:
	if search_by == SEARCH_BY.SINGLE_ROOT_NODE:
		if !is_instance_valid(root_node_to_search):
			return ["Root node for search is not defined!"]
	elif search_by == SEARCH_BY.MULTI_ROOT_NODE:
		if root_nodes_to_search.size() < 1:
			return ["Root nodes for search is empty!"]
	else:
		if group_name.size() < 1:
			return ["Search by group name is empty!"]
	return []

func _ready() -> void:
	if !Engine.is_editor_hint():
		text_changed.connect(_on_change)
		text_submitted.connect(_on_change)

func _on_change(_event: String) -> void:
	_queue_update()
	
func _validate_property(property: Dictionary) -> void:
	if property.name == "root_nodes_to_search" :
		if search_by == SEARCH_BY.MULTI_ROOT_NODE:
			property.usage = PROPERTY_USAGE_DEFAULT #PROPERTY_USAGE_READ_ONLY
		else:
			property.usage = PROPERTY_USAGE_NO_EDITOR #PROPERTY_USAGE_READ_ONLY
	elif property.name == "group_name" :
		if search_by == SEARCH_BY.GROUP_NAME_NODE:
			property.usage = PROPERTY_USAGE_DEFAULT #PROPERTY_USAGE_READ_ONLY
		else:
			property.usage = PROPERTY_USAGE_NO_EDITOR #PROPERTY_USAGE_READ_ONLY
	elif property.name == "root_node_to_search" :
		if search_by == SEARCH_BY.SINGLE_ROOT_NODE:
			property.usage = PROPERTY_USAGE_DEFAULT #PROPERTY_USAGE_READ_ONLY
		else:
			property.usage = PROPERTY_USAGE_NO_EDITOR #PROPERTY_USAGE_READ_ONLY
		
	
func _queue_update() -> void:
	if !is_inside_tree():
		return
	
	var value : String = text
	
	if value.is_empty():
		if search_by == SEARCH_BY.SINGLE_ROOT_NODE:
			if !is_instance_valid(root_node_to_search):
				printerr("Root Node To Search not defined!")
				return
			for y : Node in root_node_to_search.get_children():
				if _is_valid_node(y):
					y.visible = true
		elif search_by == SEARCH_BY.MULTI_ROOT_NODE:
			for x : Node in root_nodes_to_search:
				for y : Node in x.get_children():
					if _is_valid_node(y):
						y.visible = true
		else:
			for group : StringName in group_name:
				for x : Node in get_tree().get_nodes_in_group(group):
					for y : Node in x.get_children():
						if _is_valid_node(y):
							y.visible = true
		return
	else:
		if search_by == SEARCH_BY.SINGLE_ROOT_NODE:
			if !is_instance_valid(root_node_to_search):
				printerr("Root Node To Search not defined!")
				return
			for y : Node in root_node_to_search.get_children():
				if _is_valid_node(y):
					y.visible = false
		elif search_by == SEARCH_BY.MULTI_ROOT_NODE:
			for x : Node in root_nodes_to_search:
				for y : Node in x.get_children():
					if _is_valid_node(y):
						y.visible = false
		else:
			for group : StringName in group_name:
				for x : Node in get_tree().get_nodes_in_group(group):
					for y : Node in x.get_children():
						if _is_valid_node(y):
							y.visible = false

	var extras : String = "m"
	
	if equal_ignore_case:
		extras = "i" + extras
							
	var nodes_0 : Array[Node] = []
	var nodes_1 : Array[Node] = []
	var _rgx0 : RegEx = RegEx.create_from_string("(?{0})^{1}$".format([extras, value]))
	var _rgx1 : RegEx = RegEx.create_from_string("(?{0}).*{1}.*".format([extras, value]))
	
	if search_by == SEARCH_BY.SINGLE_ROOT_NODE:
		for x : Node in root_node_to_search.get_children():
			if _is_valid_node(x):
				x.visible = false
				_search_childs(x, x, value, filters, nodes_0, nodes_1, _rgx0, _rgx1)
	elif search_by == SEARCH_BY.MULTI_ROOT_NODE:
		for z : Node in root_nodes_to_search:
			for x : Node in z.get_children():
				if _is_valid_node(x):
					x.visible = false
					_search_childs(x, x, value, filters, nodes_0, nodes_1, _rgx0, _rgx1)
	else:
		for group : StringName in group_name:
			for x : Node in get_tree().get_nodes_in_group(group):
				for y : Node in x.get_children():
					if _is_valid_node(y):
						y.visible = false
						_search_childs(y, y, value, filters, nodes_0, nodes_1, _rgx0, _rgx1)
			
	if nodes_0.size() > 0:
		for x : Control in nodes_0:
			x.visible = true
	if nodes_1.size() > 0:
		if nodes_0.size() == 0 or !discard_similars:
			for x : Control in nodes_1:
				x.visible = true
				
	_last_search_buffer0 = nodes_0
	_last_search_buffer1 = nodes_1
	
func _search_childs(root : Node, x : Node, value : String, _filters : Array[StringName], nodes_0 : Array[Node],  nodes_1 : Array[Node], _rgx0 : RegEx, _rgx1 : RegEx) -> bool:
	for filter : StringName in _filters:
		var variant : Variant = x.get(filter)
		if value == "null" and variant == null:
			if !nodes_0.has(x):
				nodes_0.append(root)
				return true
		variant = str(variant)
		if _rgx0.search(variant) != null:
			if !nodes_0.has(root):
				nodes_0.append(root)
				return true
		elif _rgx1.search(variant) != null:
			if !nodes_1.has(root):
				nodes_1.append(root)
				return true
				
	for y : Node in x.get_children():
		if _search_childs(root, y, value, _filters, nodes_0,  nodes_1, _rgx0, _rgx1):
			return true
	return false
