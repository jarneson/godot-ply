# ![icon](./icon.png) godot-ply ![icon](./icon.png)
Godot plugin for in-editor box modeling.

Only tested in Godot 3.3.3.

## Installation
- Copy the contents of this repository into your `addons` folder for your godot project.
- Activate the plugin in your project settings.

## Usage
Create a PlyInstance node in your scene, and select it.

There are four selection modes: Mesh, Face, Edge, and Vertex.
Toggle them in the GUI to get handles for that selection mode.

Translation, rotation, and scaling are all using the built-in Godot widget. Transform snapping also works out of the box.

Other mesh editing are buttons in the hotbar.
- Extrude Face: Extrudes a face along the (approximate) face normal by 1 unit.

Generate base shapes in the hotbar as well.
- Plane: A two-sided unit x/z plane
- Cube: A unit cube
