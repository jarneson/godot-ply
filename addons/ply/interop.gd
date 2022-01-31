#MIT License
#
#Copyright (c) 2021 Jeffrey Arneson, Sólyom Zoltán
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

@tool
extends Node

# Notification when a plugin starts doing something which will be in progress until
# NOTIFY_CODE_WORK_ENDED notification is received.
const NOTIFY_CODE_WORK_STARTED = 1
# Notification when a plugin finished something that was in progress
# since NOTIFY_CODE_WORK_STARTED.
const NOTIFY_CODE_WORK_ENDED = 2
# Notification when a plugin request every other plugin to not react to input.
const NOTIFY_CODE_REQUEST_IGNORE_INPUT = 3
# Notification when a plugin stops requesting every other plugin to not react to input.
const NOTIFY_CODE_ALLOW_INPUT = 4

# For custom notification codes used by plugins, this should be the lowest value.
# i.e. const MY_CODE = NOTIFY_CODE_USER + 1
const NOTIFY_CODE_USER = 65536

# Used internally to add a node in the editor interface. Used for interop.
const _PLUGIN_NODE_NAME = "plugin_interop"
# Used internally as a meta tag of the interop node to list plugins that registered.
const _PLUGIN_DICTIONARY = "PluginDictionary"
const _PLUGIN_DICTIONARY_NAMES = "PluginNamesDictionary"


# Call on _enter_tree() to register the plugin using interop. `plugin_name` should be
# a string uniquely identifying your plugin.
static func register(plugin: EditorPlugin, plugin_name: String):
	var base_control = plugin.get_editor_interface().get_base_control()
	var n: Node = base_control.get_node_or_null(_PLUGIN_NODE_NAME)
	if n == null:
		n = Node.new()
		n.name = _PLUGIN_NODE_NAME
		base_control.add_child(n)
	var plugins = n.get_meta(_PLUGIN_DICTIONARY) if n.has_meta(_PLUGIN_DICTIONARY) else null
	var plugin_names = (
		n.get_meta(_PLUGIN_DICTIONARY_NAMES)
		if n.has_meta(_PLUGIN_DICTIONARY_NAMES)
		else null
	)
	if plugins == null:
		plugins = {}
		plugin_names = {}
	assert(!plugins.has(plugin_name)) #,'Plugin "%s" already registered for interop' % [plugin_name])
	plugins[plugin_name] = plugin
	plugin_names[plugin] = plugin_name
	n.set_meta(_PLUGIN_DICTIONARY, plugins)
	n.set_meta(_PLUGIN_DICTIONARY_NAMES, plugin_names)


static func ___get_interop_node(plugin: EditorPlugin):
	var n: Node = plugin.get_editor_interface().get_base_control().get_node_or_null(
		_PLUGIN_NODE_NAME
	)
	assert(n != null) #,"Interop node does not exist. Make sure to register your plugin first.")
	return n


static func ___get_interop_plugins(plugin: EditorPlugin):
	var n: Node = ___get_interop_node(plugin)
	var plugins = n.get_meta(_PLUGIN_DICTIONARY) if n.has_meta(_PLUGIN_DICTIONARY) else null
	return plugins


static func ___get_interop_plugin_names(plugin: EditorPlugin):
	var n: Node = ___get_interop_node(plugin)
	var plugin_names = (
		n.get_meta(_PLUGIN_DICTIONARY_NAMES)
		if n.has_meta(_PLUGIN_DICTIONARY_NAMES)
		else null
	)
	return plugin_names


static func deregister(plugin: EditorPlugin):
	var n: Node = ___get_interop_node(plugin)
	var plugins = n.get_meta(_PLUGIN_DICTIONARY) if n.has_meta(_PLUGIN_DICTIONARY) else null
	var plugin_names = (
		n.get_meta(_PLUGIN_DICTIONARY_NAMES)
		if n.has_meta(_PLUGIN_DICTIONARY_NAMES)
		else null
	)
	if !(plugin_names != null && plugin_names.has(plugin)):
		push_error("Your plugin is not registered, cannot deregister")
		assert(false)
	var plugin_name = plugin_names[plugin]
	plugins.erase(plugin_name)
	plugin_names.erase(plugin)
	if plugins.is_empty():
		n.queue_free()
	else:
		n.set_meta(_PLUGIN_DICTIONARY, plugins)
		n.set_meta(_PLUGIN_DICTIONARY_NAMES, plugin_names)


static func get_plugin_or_null(plugin: EditorPlugin, name_to_find: String):
	var plugins = ___get_interop_plugins(plugin)
	if plugins == null:
		return null
	return plugins.get(name_to_find)


# Calls the _interop_notification(caller_plugin, code, id, args) function on every registered plugin.
# caller_plugin - The registered name of your plugin sent to the receiver.
# code - a notification code.
# id - custom string that can be empty. Meaning depends on the code.
# args - custom arguments passed by the broadcasting plugin. See their documentation.
static func notify_plugins(plugin: EditorPlugin, code: int, id: String = String(), args = null):
	var plugin_names = ___get_interop_plugin_names(plugin)
	if plugin_names == null:
		return
	var plugin_name = plugin_names.get(plugin)
	assert(plugin_name != null) #,"Your plugin is not registered, cannot broadcast notification")
	if plugin_name == null:
		return
	for p in plugin_names:
		if p != plugin && p.has_method("_interop_notification"):
			p._interop_notification(plugin_name, code, id, args)


static func start_work(plugin: EditorPlugin, work_id: String, args = null):
	notify_plugins(plugin, NOTIFY_CODE_WORK_STARTED, work_id, args)


static func end_work(plugin: EditorPlugin, work_id: String, args = null):
	notify_plugins(plugin, NOTIFY_CODE_WORK_ENDED, work_id, args)


static func grab_full_input(plugin: EditorPlugin):
	notify_plugins(plugin, NOTIFY_CODE_REQUEST_IGNORE_INPUT)


static func release_full_input(plugin: EditorPlugin):
	notify_plugins(plugin, NOTIFY_CODE_ALLOW_INPUT)
