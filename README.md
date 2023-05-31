![100%-material-free-_every-pixel-deliberate_](https://github.com/benthillerkus/mesh_gradient/assets/29630575/f66a7337-695b-493a-ba14-7af622fd72d9)


# mesh_gradient

Renders a so called *mesh gradient* as a Bézier patch defined by control points.
DeCasteljau's algorithm is used to mesh the surface into polygons, that are then drawn via `canvas.drawVertices` - this call supports vertex colors, sidestepping the lack of user defined vertex shaders as of *Flutter 3.10*.

The mesh gradient in fact does not require any user defined fragment shaders. This could've been built with Flutter more than [7 years ago](https://github.com/flutter/engine/blame/main/lib/ui/painting.dart#L4644). However for the configurator I am using a fragment shader to display the gradient in a specifc colospace (though in ye olden days you could've just added a gradient with a bunch of stops to get a 95% accurate representation without touching any GlSl if you were so inclined).

https://github.com/benthillerkus/mesh_gradient/assets/29630575/66158b60-26ed-4d66-9129-3efdded627a8

# why

The enfant terrible of Flutter evangelism set out a [100 bottle cap bounty](https://twitter.com/luke_pighetti/status/1662206784923402240) on getting ~~mesh gradients~~ *the cool thing from stripe.com* working in Flutter.
This got [a bunch](https://twitter.com/mideb_/status/1662424309065760768) of [people](https://twitter.com/caseycrogers/status/1662486769470947328) working on the problem, but the consensus quickly became that vertex shaders would be needed.

While I came to the same conclusion at first (otherwise one would have to supply `n` colors and positions to the fragment shader and then to the blending and distortion per pixel *(which might also work and could even be performant, it just sounded very painful and math-heavy to me)*), I then recalled a [video by Filip Hráček](https://youtu.be/pD38Yyz7N2E) on `canvas.drawVertices`.

And sure enough [`drawVertices`](https://api.flutter.dev/flutter/dart-ui/Canvas/drawVertices.html) actually allows you to pass a color and even UVs as additional varyings to the geometry. Flutter -by default- will just use these per-vertex colors and blend them over each triangle that it paints.

The game plan was now to generate a reasonably dense mesh from a set of user defined control points and pre-blended colors and then let Flutter do the rest.

https://github.com/benthillerkus/mesh_gradient/assets/29630575/065d6d75-ec9b-4e66-81a0-f20a2614fc84

I mocked up what I had in mind in Blender and used the [subdivision surface modifier](https://docs.blender.org/manual/en/dev/modeling/modifiers/generate/subdivision_surface.html#subdivision-surface-modifier) to transform a sparse mesh (the control points) into a nice looking result. Blender uses the [Catmull-Clark algorithm](https://en.wikipedia.org/wiki/Catmull%E2%80%93Clark_subdivision_surface) -- so that's what I tried to implement first. Aaaaand I failed! While the algorithm is deceptively simple, it requires lots of book-keeping of which vertex is adjacent to which face and which edge neighbors which newly created point and the likes.

![blender screenshot](https://github.com/benthillerkus/mesh_gradient/assets/29630575/bcd581ca-2d5b-40c0-a532-7f2312685443)

And while I could've (should've) just copied an existing implementation and their data structure, I instead asked ChatGPT with the broad problem definition and it suggested using DeCasteljau's Algorithm. I had a look at [Wikipedia](https://de.wikipedia.org/wiki/Bezierfl%C3%A4che), saw a bunch of big words and as soon as the MathJax loaded in, I hasted back and prompted for an implementation in Java - which miraculously turned out to be correct and worked nicely with the helper methods I had already written.
I had to touch up the code a bit and add some caching to optimize the way I'm using the datastructure, but yeah, this kind of saved the day for me.

*as I'm writing this up, I realize that the [English Wikipedia for the algorithm itself](https://en.wikipedia.org/wiki/De_Casteljau%27s_algorithm) is much more explanative and even comes with code samples. Oh well.*

In the future it'd be nice to switch to something more [sophisticated](https://twinside.github.io/coon_rendering.html#what-is-a-gradient-mesh) or even get regular subdivision surfaces working, because I find the control points to be overly soft currently. The effect looks best when there are big contrasts in sharpness / density and with the current setup, you have to move the points quite far to get even moderately extreme results.



https://github.com/benthillerkus/mesh_gradient/assets/29630575/5a5995d0-4987-4fa4-a2f2-22b2855d2f41
At this point I was still experimenting with fragment shaders and hadn't settled for a direction yet...
