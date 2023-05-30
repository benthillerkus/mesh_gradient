# mesh_gradient

Renders a so called *mesh gradient* as a Bézier patch defined by control points.
DeCasteljau's algorithm is then used to mesh the surface.
The points can then be drawn via `canvas.drawVertices`, which supports vertex colors, sidestepping the lack of user defined fragment shaders as of *Flutter 3.10*.

To achieve good blending, DeCasteljau is used to both interpolate the in-between points and colors.
