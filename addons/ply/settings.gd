@tool
extends Node

# Settings that will be used by the plugin should be added below, as this will ensure they exist/are initialized

const settings_metadata = {
	'editors/ply_gizmos/snap_increments/translate': {
		'type': TYPE_FLOAT,
		'default': 1.0
	},
	'editors/ply_gizmos/snap_increments/rotate': {
		'type': TYPE_FLOAT,
		'default': 15.0
	},
	'editors/ply_gizmos/snap_increments/scale': {
		'type': TYPE_FLOAT,
		'default': 0.1
	}
}

static func _apply_setting_info(editor_settings: EditorSettings, name: String, properties: Dictionary) -> void:
	var already_exists = editor_settings.has_setting(name)

	if !already_exists:
		editor_settings.set(name, properties.default)
		
	editor_settings.add_property_info({'name': name, 'type': properties.type})
	editor_settings.set_initial_value(name, properties.default, false)

static func initialize_plugin_settings(editor_settings: EditorSettings) -> void:
	for setting_name in settings_metadata:
		_apply_setting_info(editor_settings, setting_name, settings_metadata[setting_name])
