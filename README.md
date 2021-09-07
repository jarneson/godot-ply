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
- Faces
    - Extrude: Extrudes a face along the (approximate) face normal by 1 unit.
- Edges
    - Subdivide: Add a vertex at the midpoint of the edge, and split it in two.
    - Edge Loop: Add an edge loop along the quad loop perpindicular to the selected edge.

There are also selection utilities.
- Faces
    - Select Quad Loop: Select a quad loop containing the selected face. There are two directions, one for each axis of the plane.

Generate base shapes in the hotbar as well.
- Plane: A two-sided unit x/z plane
- Cube: A unit cube

## Details
Meshes are meant to only be oriented manifolds. Some properties:
- Each edge has one or two faces (although we generally use exactly 2)
- All of an edge's faces have compatible orientation -- that is the edge origin and destination are in opposite order for opposite faces.

Ply uses a winged edge representation for edges, but omit counterclockwise navigation:
```
omitted
left ccw        right cw
         \     /
          \   /
           \ /
            o destination
            ^
            |
left face   |   right face
            |
            o origin
           / \
          /   \
         /     \
left cw          right ccw
                 omitted
```

### Implications
Given this representation, a few limitations occur that are representable in other tools:
- One cannot abritrarily extrude edges into one-sided faces, or one edge would be incident with >2 faces.
- One cannot flip individual faces, as the faces would no longer have compatible orientation.