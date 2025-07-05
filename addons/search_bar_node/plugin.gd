@tool
extends EditorPlugin
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	SearchBarNode
#	https://github.com/CodeNameTwister/GD-SearchBar-Node
#
#	Search Bar Node addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

const SEARCH_BAR : Script = preload("res://addons/search_bar_node/SearchBarNode.gd")
const ICON_SEARCH_BAR : Texture2D = preload("res://addons/search_bar_node/search.svg")

func _enter_tree() -> void:
	add_custom_type("SearchBarNode", "LineEdit", SEARCH_BAR, ICON_SEARCH_BAR)

func _exit_tree() -> void:
	remove_custom_type("SearchBarNode")
