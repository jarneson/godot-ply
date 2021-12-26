"""
MIT License

Copyright (c) 2021 Jeffrey Arneson

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""

extends Node

var plugin_dictionary = {}

const NOTIFY_CODE_WORK_STARTED = 1
const NOTIFY_CODE_WORK_ENDED = 2

func register(name, plugin):
    assert(not plugin_dictionary.has(name), 'Plugin "%s" already registered for interop' % [name])
    plugin_dictionary[name] = plugin

func deregister(name, plugin):
    assert(plugin_dictionary.has(name), 'Plugin "%s" not registered, cannot deregister' % [name])
    assert(plugin_dictionary[name] == plugin, 'Plugin "%s" registered with different object, cannot deregister, was: %s expected: %s' % [name, plugin_dictionary[name], plugin])
    plugin_dictionary.erase(name)

func get_plugin_or_null(name):
    return plugin_dictionary.get(name)

func _notify_plugins(code, args):
    for plugin_name in plugin_dictionary:
        var plugin = plugin_dictionary[plugin_name]
        if plugin.has_method("_interop_notification"):
            plugin._interop_notification(code, args)

func start_work(what):
    _notify_plugins(NOTIFY_CODE_WORK_STARTED, what)

func end_work(what):
    _notify_plugins(NOTIFY_CODE_WORK_ENDED, what)