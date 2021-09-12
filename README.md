# ![icon](./icons/plugin.svg) godot-ply ![icon](./icons/plugin.svg)
Godot plugin for in-editor box modeling.

Only tested in Godot 3.3.3. Icons are only good for dark mode.

See demos [on youtube](https://www.youtube.com/channel/UCf1IV6ABf3a4nW1wEyPwmMQ).

## Installation
- Copy the contents of this repository into your `addons` folder for your godot project.
- Activate the plugin in your project settings.

## Usage
Create a ![nodeicon](./icons/plugin.svg) PlyInstance node in your scene, and select it.

There are four selection modes:
- ![meshicon](./icons/select_mesh.svg) ` 1 ` Mesh
- ![faceicon](./icons/select_face.svg) ` 2 ` Face
- ![edgeicon](./icons/select_edge.svg) ` 3 ` Edge
- ![vertexicon](./icons/select_vertex.svg) ` 4 ` Vertex

There are two editor modes are toggled by the ![transformicon](./icons/icon_tool_move.svg) `` ` `` Transform toggle in the menu.
- Selection mode: select faces, edges, and vertices with the mouse
- Transform mode: use the gizmo to translate, rotate and scale

There are tools for each selection mode:
- Mesh
    - Generators
        - Plane: Generate a two-sided unit plane
        - Cube: Generate a unit cube
- Face
    - ![loopicon1](./icons/face_loop.svg) Loop: Select Face Loop in One Direction
    - ![loopicon2](./icons/face_loop_2.svg) Loop: Select Face Loop in The Other Direction
    - ![extrudeicon](./icons/extrude_face.svg) ` ctrl-e ` Extrude: Extrudes the selected face(s) along their mean normal by 1 unit
- Edge
    - ![loopicon](./icons/edge_select_loop.svg) Loop: Select an edge loop from the given edge
    - ![loopcuticon](./icons/loop_cut.svg) ` ctrl-r ` Cut Loop: Add a loop cut perpindicular to the selected edge
    - ![subdivideicon](./icons/edge_subdivide.svg) Subdivide: Splits the selected edge into two parallel edges
- Vertex
    - None, yet!

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

## Contributing

Feel free to contribute! Both issues and pull requests are very welcome.

Feel free to contact me on the [godot discord server](https://discord.gg/4JBkykG), where my name is `hints`
