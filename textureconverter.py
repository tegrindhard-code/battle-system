import json
import os
import shutil

print("\n" + "="*60)
print("POKEMON MODEL CONVERTER - BATCH PROCESSOR")
print("="*60 + "\n")

# Prompt for model folder
print("Enter the folder path containing your Pokemon model files:")
print("(Should contain .dae or .obj, .png textures, and .txt/.json material file)")
MODEL_FOLDER = input("Folder path: ").strip().strip('"')

if not os.path.exists(MODEL_FOLDER):
    print(f"\nERROR: Folder not found: {MODEL_FOLDER}")
    exit()

print(f"\n[OK] Found folder: {MODEL_FOLDER}")

# Prompt for output folder
print("\nEnter the output folder path (where to save the ready files):")
OUTPUT_FOLDER = input("Output folder: ").strip().strip('"')

if not os.path.exists(OUTPUT_FOLDER):
    print(f"Creating output folder: {OUTPUT_FOLDER}")
    os.makedirs(OUTPUT_FOLDER)

# Prompt for model name
print("\nEnter a name for the output (without extension):")
MODEL_NAME = input("Model name: ").strip()

if not MODEL_NAME:
    MODEL_NAME = "pokemon_model"

print("\n" + "-"*60)
print("CREATING BLENDER SCRIPT...")
print("-"*60 + "\n")

# Create a Blender Python script that will do the work
blender_script = f'''
import bpy
import json
import os

# Configuration
MODEL_FOLDER = r"{MODEL_FOLDER}"
OUTPUT_FOLDER = r"{OUTPUT_FOLDER}"
MODEL_NAME = "{MODEL_NAME}"

def clear_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)

def find_file_with_extension(folder, extensions):
    if isinstance(extensions, str):
        extensions = [extensions]
    
    for file in os.listdir(folder):
        if any(file.lower().endswith(ext) for ext in extensions):
            return os.path.join(folder, file)
    return None

def load_material_json(folder):
    for file in os.listdir(folder):
        if file.endswith('.txt') or file.endswith('.json'):
            filepath = os.path.join(folder, file)
            try:
                with open(filepath, 'r') as f:
                    content = f.read()
                    data = json.loads(content)
                    if isinstance(data, list) and len(data) > 0:
                        if 'BaseColorMap' in str(data):
                            print(f"[OK] Found material JSON: {{file}}")
                            return data
            except:
                continue
    return None

def find_texture(folder, texture_name):
    if not texture_name:
        return None
    
    for file in os.listdir(folder):
        name_without_ext = os.path.splitext(file)[0]
        if name_without_ext == texture_name:
            return os.path.join(folder, file)
    return None

def setup_material(mat_data, folder, obj):
    mat_name = mat_data.get('name', 'Material')
    
    if mat_name in bpy.data.materials:
        mat = bpy.data.materials[mat_name]
    else:
        mat = bpy.data.materials.new(name=mat_name)
    
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    
    nodes.clear()
    
    bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    bsdf.location = (0, 0)
    
    output = nodes.new(type='ShaderNodeOutputMaterial')
    output.location = (300, 0)
    
    links.new(bsdf.outputs['BSDF'], output.inputs['Surface'])
    
    x_offset = -300
    y_offset = 0
    
    # Base Color
    base_color_map = mat_data.get('BaseColorMap', '')
    if base_color_map:
        texture_path = find_texture(folder, base_color_map)
        if texture_path and os.path.exists(texture_path):
            tex_node = nodes.new(type='ShaderNodeTexImage')
            tex_node.image = bpy.data.images.load(texture_path)
            tex_node.location = (x_offset, y_offset)
            links.new(tex_node.outputs['Color'], bsdf.inputs['Base Color'])
            print(f"  [OK] Applied Base Color: {{base_color_map}}")
            y_offset -= 300
    
    # Normal Map
    normal_map = mat_data.get('NormalMap', '')
    if normal_map:
        texture_path = find_texture(folder, normal_map)
        if texture_path and os.path.exists(texture_path):
            tex_node = nodes.new(type='ShaderNodeTexImage')
            tex_node.image = bpy.data.images.load(texture_path)
            tex_node.image.colorspace_settings.name = 'Non-Color'
            tex_node.location = (x_offset, y_offset)
            
            normal_node = nodes.new(type='ShaderNodeNormalMap')
            normal_node.location = (x_offset + 200, y_offset)
            
            links.new(tex_node.outputs['Color'], normal_node.inputs['Color'])
            links.new(normal_node.outputs['Normal'], bsdf.inputs['Normal'])
            print(f"  [OK] Applied Normal Map: {{normal_map}}")
            y_offset -= 300
    
    # Roughness
    roughness_map = mat_data.get('RoughnessMap', '')
    if roughness_map:
        texture_path = find_texture(folder, roughness_map)
        if texture_path and os.path.exists(texture_path):
            tex_node = nodes.new(type='ShaderNodeTexImage')
            tex_node.image = bpy.data.images.load(texture_path)
            tex_node.image.colorspace_settings.name = 'Non-Color'
            tex_node.location = (x_offset, y_offset)
            links.new(tex_node.outputs['Color'], bsdf.inputs['Roughness'])
            print(f"  [OK] Applied Roughness: {{roughness_map}}")
            y_offset -= 300
    
    return mat

def apply_materials_to_mesh(obj, materials_dict):
    if not obj.data.materials:
        return
    
    for i, mat_slot in enumerate(obj.material_slots):
        mat_name = mat_slot.name
        if mat_name in materials_dict:
            mat_slot.material = materials_dict[mat_name]
            print(f"  [OK] Assigned material '{{mat_name}}' to slot {{i}}")

# Main execution
print("\\n" + "="*60)
print("PROCESSING IN BLENDER...")
print("="*60 + "\\n")

clear_scene()

# Find model file
dae_file = find_file_with_extension(MODEL_FOLDER, '.dae')
obj_file = find_file_with_extension(MODEL_FOLDER, '.obj')

model_file = dae_file if dae_file else obj_file

if not model_file:
    print("[ERROR] No .dae or .obj file found!")
    import sys
    sys.exit(1)

print(f"[OK] Found model: {{os.path.basename(model_file)}}")

# Import model
if model_file.lower().endswith('.dae'):
    print("Importing DAE...")
    bpy.ops.wm.collada_import(filepath=model_file)
else:
    print("Importing OBJ...")
    bpy.ops.import_scene.obj(filepath=model_file)

print("[OK] Model imported\\n")

# Load and apply materials
material_data = load_material_json(MODEL_FOLDER)

if material_data:
    print(f"[OK] Found {{len(material_data)}} materials\\n")
    
    materials_dict = {{}}
    
    for mat_data in material_data:
        mat_name = mat_data.get('name', 'Material')
        print(f"Processing: {{mat_name}}")
        
        for obj in bpy.data.objects:
            if obj.type == 'MESH':
                mat = setup_material(mat_data, MODEL_FOLDER, obj)
                materials_dict[mat_name] = mat
    
    print("\\nApplying materials...")
    for obj in bpy.data.objects:
        if obj.type == 'MESH':
            apply_materials_to_mesh(obj, materials_dict)

# Scale up the model before export (Pokemon models are tiny)
for obj in bpy.data.objects:
    if obj.type == 'MESH' or obj.type == 'ARMATURE':
        obj.scale = (100, 100, 100)
        bpy.context.view_layer.update()

# Apply the scale
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

# Export FBX
output_path = os.path.join(OUTPUT_FOLDER, f"{{MODEL_NAME}}.fbx")

print(f"\\nExporting FBX: {{output_path}}")

bpy.ops.export_scene.fbx(
    filepath=output_path,
    use_selection=False,
    apply_scale_options='FBX_SCALE_ALL',
    global_scale=100.0,
    object_types={{'ARMATURE', 'MESH'}},
    use_mesh_modifiers=True,
    mesh_smooth_type='FACE',
    add_leaf_bones=False,
    bake_anim=False,
    path_mode='COPY',
    embed_textures=True
)

print("\\n" + "="*60)
print("CONVERSION COMPLETE!")
print("="*60)
print(f"\\nOutput: {{output_path}}")
print("\\nReady to import into Roblox Studio!")
print("="*60 + "\\n")
'''

# Save the Blender script with UTF-8 encoding
script_path = os.path.join(OUTPUT_FOLDER, f"{MODEL_NAME}_blender_script.py")
with open(script_path, 'w', encoding='utf-8') as f:
    f.write(blender_script)

print(f"[OK] Created Blender script: {script_path}")

# Create a batch file to run it - Fixed version
batch_content = f'''@echo off
echo Running Blender converter...
echo.

REM Try common Blender installation paths
set BLENDER=""

if exist "C:\\Program Files\\Blender Foundation\\Blender 4.4\\blender.exe" (
    set BLENDER="C:\\Program Files\\Blender Foundation\\Blender 4.4\\blender.exe"
) else if exist "C:\\Program Files\\Blender Foundation\\Blender 4.2\\blender.exe" (
    set BLENDER="C:\\Program Files\\Blender Foundation\\Blender 4.2\\blender.exe"
) else if exist "C:\\Program Files\\Blender Foundation\\Blender 4.1\\blender.exe" (
    set BLENDER="C:\\Program Files\\Blender Foundation\\Blender 4.1\\blender.exe"
) else if exist "C:\\Program Files\\Blender Foundation\\Blender 4.0\\blender.exe" (
    set BLENDER="C:\\Program Files\\Blender Foundation\\Blender 4.0\\blender.exe"
) else if exist "C:\\Program Files\\Blender Foundation\\Blender 3.6\\blender.exe" (
    set BLENDER="C:\\Program Files\\Blender Foundation\\Blender 3.6\\blender.exe"
) else (
    echo ERROR: Blender not found in common locations!
    echo Please install Blender from https://www.blender.org/download/
    echo Or edit this batch file to point to your Blender installation.
    pause
    exit /b 1
)

echo Found Blender at: %BLENDER%
echo.

%BLENDER% --background --python "{script_path.replace(chr(92), chr(92)+chr(92))}"

echo.
echo Done! Check the output folder.
pause
'''

batch_path = os.path.join(OUTPUT_FOLDER, f"RUN_CONVERTER_{MODEL_NAME}.bat")
with open(batch_path, 'w', encoding='utf-8') as f:
    f.write(batch_content)

print(f"[OK] Created batch file: {batch_path}")

print("\n" + "="*60)
print("SETUP COMPLETE!")
print("="*60)
print("\nNext steps:")
print(f"1. Double-click: {os.path.basename(batch_path)}")
print("2. Wait for Blender to process (runs in background)")
print(f"3. Your FBX will be in: {OUTPUT_FOLDER}")
print("4. Import the FBX into Roblox Studio!")
print("\n" + "="*60 + "\n")