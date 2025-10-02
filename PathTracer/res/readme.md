# PBR Textures
This path tracer supports PBR rendering using a PBR BRDF (Disney's burley + GGX) and PBR textures to modulate some parameters of the material along the 3D model's surfaces

- <b>Textures</b>: they allow for a 3D model to have images mapped upon its faces, the final albedo is computed as <code>mapColor * material.albedo</code>
- <b>Normal maps</b>: they change how normals are directed on the surface, altering its shading. It looks particularly cool on reflective and refractive materials
- <b>Roughness maps</b>: they modulate the roughness along the faces
- <b>Height maps</b>: they fake 3D details on plain surfaces by using parallax mapping, you can see it in action in the "flashlight" scene on the metallic ground
- <b>Ambient occlusion maps</b>: they fake pre-baked ambient occlusion on faces, often used in combination with height maps
- <b>Metallic maps</b>: they modulate the metallic parameter along the face
- <b>Emission maps</b>: they are single channel images that define which pixel of the model actually emit light (the light color is specified in the material file)

# Material Files
The material file is a key=value list of attributes of a material
- <code>albedo</code>: the rgba color of the material, the a component indicates whether the material is transparent (<code>albedo=(1,0,0,0.5)</code>)
- <code>fresnelR0</code>: the amount of light reflected by the surface on perpendicular incidence. This parameter influences how much reflections and specular highlight are visible when looking perpendicularly at the surface normal (<code>fresnelR0=(0.1,0.1,0.1)</code>)
- <code>roughness</code>: a parameter to model micro-facets distribution on the surface, a roughness closer to 0 will yield a perfect reflection/refraction, while
a roughness closer to 1 will model a very rough surface. This parameter influences <b>burley diffuse, GGX specular, VNDF distribution</b> and <b>cos-weighted distribution for diffuse calculations</b>
- <code>metallic</code>: this is just a parameter to model how much reflections are visible, metallic=0 -> no reflections, metallic=1 -> very visible reflections
- <code>refraction_index</code>: the parameter to pass to hlsl refract, it's calculated as <code>1.0 / eta</code>, where eta is the phisically correct IOR of the material. This parameter can be split in
<code>refraction_index_r</code>, <code>refraction_index_g</code>, <code>refraction_index_b</code> to model spectral dispersion
- <code>specular</code>: balances diffuse and specular contributions: <code>color = Ld * (1.0 - specular) + Ls * specular</code>
- <code>emission</code>: the emission color of the material (<code>emission=(1,0,0)</code>)
# Scene file
The scene file can be divided in sections
## Resources
Here you will set which resources the scene needs to load
- <code>id</code>: the scene id, you can put anything since it's not being used right now
- <code>cubemap</code>: file name without extension of the .dds cubemap in <code>res/cubemaps</code>
- <code>textures</code>: a list of .dds texture names without extension in <code>res/textures</code> (<code>textures={tex1,tex2,...,tex_n}</code>)
- <code>nmaps</code>: a list of .dds normal map names without extension in <code>res/normal_maps</code> (<code>nmaps={tex1,tex2,...,tex_n}</code>)
- <code>rmaps</code>: a list of .dds roughness map names without extension in <code>res/roughness_maps</code> (<code>rmaps={tex1,tex2,...,tex_n}</code>)
- <code>hmaps</code>: a list of .dds height map names without extension in <code>res/height_maps</code> (<code>hmaps={tex1,tex2,...,tex_n}</code>)
- <code>aomaps</code>: a list of .dds ambient occlusion map names without extension in <code>res/ao_maps</code> (<code>aomaps={tex1,tex2,...,tex_n}</code>)
- <code>mmaps</code>: a list of .dds metallic map names without extension in <code>res/metallic_maps</code> (<code>mmaps={tex1,tex2,...,tex_n}</code>)
- <code>emimaps</code>: a list of .dds emission map names without extension in <code>res/emissive</code> (<code>emimaps={tex1,tex2,...,tex_n}</code>)
- <code>materials</code>: a list of .mat material names without extension in <code>res/materials</code> (<code>materials={mat1,mat2,...,mat_n}</code>)
- <code>geometries</code>: a list of .glb 3D model names without extension in <code>res/models</code>.
You can also add custom names to auto-generate models: <code>#box</code> -> 3D cube, <code>#plane</code> -> 2D plane pointing up, <code>#sphere</code> -> sphere, <code>#quad</code> -> 2D plane pointing towards the Z axis
- <code>lights</code>: the number of lights of the scene
- <code>cameras</code>: the number of cameras of the scene, the first one will always be controlled by user input  
<b>Important Note: each texture must be 2048x2048 with 12 mipmaps.</b>
## Objects
The loader understands that you're writing an object when it reads curly braces <code>\{...\}</code>.  
Inside of them you can write all the parameters as key=value just like before.  
## Lights and cameras
If in the resources section <code>cameras != 0</code>, you need to write an object for each camera. You can tell the loader to start loading cameras by writing <code>#cameras</code>  
<ul>
	<li><code>pos</code>: world space position of the camera (<code>pos=(0.5,1.0,-3.0)</code>)</li>
	<li><code>look</code>: looking direction of the camera (<code>look=(0,0,1)</code>)</li>
</ul>

If in the resources section <code>lights != 0</code>, you need to write an object for each light. You can tell the loader to start loading cameras by writing <code>#lights</code>
<ul>
	<li><code>direction</code>: for directional lights: the constant direction of the light, for spotlight: the main direction along the cone, for point lights: unused (<code>direction=(0,-1,0)</code>)</li>
	<li><code>pos</code>: light position for spotlights and point lights (<code>pos=(-2,2.45,-1)</code>)</li>
	<li><code>strength</code>: rgb color of the light * light strength (<code>strength=(1,1,1)</code>)</li>
	<li><code>falloff_start</code> <b>(for point light and spotlights only)</b>: distance from the position the light starts</li>
	<li><code>falloff_end</code> <b>(for point light and spotlights only)</b>: distance from the position the light ends (with a linear falloff)</li>
	<li><code>spot_power</code> <b>(for spotlights only)</b>: determines the shape of the cone of light</li>
	<li><code>type</code>: can be either of <code>directional_light</code>, <code>spot_light</code> or <code>point_light</code></li>
	<li><code>radius</code>: used for shadows importance sampling, turning the light from a single point to an area light, allowing for soft shadows</li>
</ul>

<b>Important Note: there can only be one directional light and it must be the first one of the list</b>
## Instances
Start the instances section by writing <code>#instances</code>, in this section you can write as many objects as you want, each one represent an entity
<ul>
	<li><code>id</code>: unique identifier of the entity (the entities should have their id ordered from lower to higher)</li>
	<li><code>geometry</code>: an index pointing to a geometry inside <code>geometries</code></li>
	<li><code>layer</code>: can be either of <code>opaque</code>, <code>transparent</code> or <code>alpha_tested</code></li>
	<li><code>instances</code>: the amount of instances sharing this same geometry and render layer</li>
</ul>

After the <code>instances</code> attribute, you must defined one object for each instance nested inside the entity object
<ul>
	<li><code>material</code>: an index pointing to a material inside <code>materials</code></li>
	<li><code>texture</code>: an index pointing to a texture inside <code>textures</code>, you can use -1 for no texture</li>
	<li><code>nmap</code>: an index pointing to a normal map inside <code>nmaps</code>, you can use -1 for no normal map</li>
	<li><code>rmap</code>: an index pointing to a roughness map inside <code>rmaps</code>, you can use -1 for no roughness map</li>
	<li><code>hmap</code>: an index pointing to a height map inside <code>hmaps</code>, you can use -1 for no height map</li>
	<li><code>aomap</code>: an index pointing to a ambient occlusion map inside <code>aomaps</code>, you can use -1 for no ambient occlusion map</li>
	<li><code>emap</code>: an index pointing to a emission map inside <code>emimaps</code>, you can use -1 for no emission map</li>
	<li><code>mmap</code>: an index pointing to a metallic map inside <code>mmaps</code>, you can use -1 for no metallic map</li>
	<li><code>pos</code>: world space position of the instance (<code>pos=(0,-0.5,-1.5)</code>)</li>
	<li><code>rot</code>: rotation in radians for each axis (<code>rot=(0,0,0)</code>)</li>
	<li><code>scale</code>: scale on each axis, by putting at least one value different from the other you will force the renderer to calculate the inverse transpose (<code>scale=(1,1,1)</code>)</li>
	<li><code>tex_scale</code>: scale value for the texture, this will make the texture appear either bigger or smaller on the surfaces (<code>tex_scale=(1,1,1)</code>)</li>
</ul>

<b>Important note: each INSTANCE should be separated by a break line</b>  
<b>Important note: please set all <code>tex_scale</code> values to the same value</b>
# Settings
From the <code>main.cpp</code> file you can set custom settings for the renderer
- <code>width</code>: width of the window
- <code>height</code>: height of the window
- <code>dlssWidth</code>/<code>dlssHeight</code>: for internal use
- <code>fps</code>: fps limit, set 0 to have unlimited fps (on some hardware it is necessary to go fullscreen for unlimited fps to work)
- <code>texFilter</code>: using <code>TEX_FILTER_NEAREST</code> will disable interpolation, <code>TEX_FILTER_BILINEAR</code> will interpolate along the u-v axes, <code>TEX_FILTER_TRILINEAR</code> will also interpolate between mipmaps
- <code>texResolution</code>: using a lower resolution will force the renderer to load and render lower resolution textures (to use for performances reasons)
- <code>anisotropic</code>: will enhance the visual rendering of textures rendered from grazing angles, must be between 0 and 16
- <code>dlss</code>: choose your DLSS mode between off, performance, quality, balanced, ultra performance, ultra quality (not working) and DLAA
- <code>mouseSensitivity</code>: sensitivity of the mouse
- <code>vSync</code>: enables vSync to fix screen tearing
- <code>fullscreen</code>: fullscreen mode
- <code>mipmaps</code>: enables mipmaps
- <code>specular</code>: enables GGX specular highlights
- <code>rtao</code>: enables Ray Traced Ambient Occlusion
- <code>rtReflections</code>: enables reflections
- <code>rtRefractions</code>: enables refractions (if disabled, transparent objects will still be transparent)
- <code>rtShadows</code>: enables shadows
- <code>indirect</code>: enables GI
- <code>texturing</code>: enables textures
- <code>normalMapping</code>: enables normal maps
- <code>roughnessMapping</code>: enables roughness maps
- <code>heightMapping</code>: enables height maps
- <code>aoMapping</code>: enables ambient occlusion maps
- <code>metallicMapping</code>: enables metallic maps
- <code>rayReconstruction</code>: enables DLSS Ray Reconstruction (doesn't work well for surfaces with solid colors witout textures)
- <code>fxaa</code>: enables FXAA
- <code>colorGrading</code>: enables color grading
- <code>vignette</code>: enables vignette effect
- <code>backBufferFormat</code>: the DXGI format of the back buffer
- <code>exposure</code>: camera exposure
- <code>brightness</code>: brightness of the image
- <code>contrast</code>: increases contrast
- <code>saturation</code>: saturates the final image
- <code>gamma</code>: used to apply gamma correction
- <code>tonemapping</code>: lets you choose which tone mapper to use between off, reinhard, uncharted2, ACES and AGX
- <code>maxAnisotropy</code>: upper limit for <code>anisotropic</code>
- <code>dlssSupported</code>: a flag to check for DLSS compatibility
- <code>rayReconstructionSupported</code>: a flag to check for DLSS Ray Reconstruction compatibility