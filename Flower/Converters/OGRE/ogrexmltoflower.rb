#!/usr/bin/ruby

# OgreXMLToFlower.rb, version 0.3
#
# Copyright (c) 2010 Robin Southern
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

FLOWER_VERSION = '0.3'

def read(type, file)
    
    materials_db = {}
    
    if File.exists?(file) == false
        puts "\nCannot find the file '#{file}'"
        return
    end
    
    if File.exists?("materials.txt")
        m = File.read("materials.txt")
        m.scan(/(\w+)\s+(\d*)/).each do |mat|
            materials_db[mat[0]] = mat[1]
        end
    else
        puts "\n[Warning] ====================================================================="
        puts "\"materials.txt\" does not exist in this folder. It is recommended you use one"
        puts "to convert Ogre submesh names into the PhysX material identifier equivalent."
        puts "Simply open up a text editor, and for each sub mesh name. Write it down"
        puts "followed by a space (or two) with the PhysX material identifier, i.e:"
        puts " grass 3"
        puts " ogre_tusks 2"
        puts "===============================================================================\n\n"
    end
    
    f = File.read(file)
    
    sub_mesh_id = 0
    
    f.scan(/<submesh(.*)<\/submesh>/m).each do |submesh|
        
        material_index = 0
        
        mat_name = f.match(/material=\"(\w+)\"/)
        if mat_name != nil
            material_index = materials_db[mat_name[1]]
            if material_index != nil
                puts " - Submesh '#{mat_name[1]}' is assumed to be PhysX Material ##{material_index} in this mesh."
            end
        end
        
        material_index = 0 if material_index == nil
        
        vertices = []
        indexes = []
        texturecoords = []
        normals = []
        materials = []
        
        f.scan(/position\s+x\s*=\s*"(.+)"\s+y\s*=\s*"(.+)"\s+z\s*=\s*"(.+)"/).each do |vertex|
            vertices.push vertex[0]
            vertices.push vertex[1]
            vertices.push vertex[2]
            3.times do |v|
                materials.push material_index
            end
        end
        
        f.scan(/normal\s+x\s*=\s*"(.+)"\s+y\s*=\s*"(.+)"\s+z\s*=\s*"(.+)"/).each do |normal|
            normals.push normal[0]
            normals.push normal[1]
            normals.push normal[2]
        end
        
        f.scan(/texcoord\s+u\s*=\s*"(.+)"\s+v\s*=\s*"(.+)"/).each do |texcoord|
            texturecoords.push texcoord[0]
            texturecoords.push texcoord[1]
        end
        
        f.scan(/face\s+v1\s*=\s*"(.+)"\s+v2\s*=\s*"(.+)"\s+v3\s*=\s*"(.+)"/).each do |index|
            indexes.push index[0]
            indexes.push index[1]
            indexes.push index[2]
        end
        
        out = String.new
        out << file
        suffix = String.new
        suffix << "." + sub_mesh_id.to_s if sub_mesh_id != 0
        suffix << ".flower"
        
        fout = out.gsub /\.mesh\.xml/, suffix
        fout << ".flower" if (fout == out)
        
        write(fout, file, type, vertices, indexes, normals, texturecoords, materials)
        
        sub_mesh_id +=1
    end
    

end


def write(file, original, type, vertices, indexes, normals, texturecoords, materials) 
    
    out = String.new
    out << "# '#{original}' converted by OgreXMLToFlower.rb\n"
    
    out << "type #{type}\n\n"
    
    if type == "convex" && (indexes.size / 3) > 255
        puts "[Warning] Triangle limit has exceeded limitations (255) for the convex mesh."
    end
    
    # vertices
    out << "\nvertices " << vertices.join(', ') << "\n" if vertices.size > 2
    
    # indexes
    out << "\nindexes " << indexes.join(', ') << "\n" if indexes.size > 2
    
    # normals
    out << "\nnormals " << normals.join(', ') << "\n" if normals.size > 2
    
    # texturecoords
    out << "\ntexturecoords " << texturecoords.join(', ') << "\n" if texturecoords.size > 2
    
    # materials
    out << "\nmaterials " << materials.join(', ') << "\n" if materials.size > 3
    
    File.open(file, 'w')  { |f| f.write out }
    puts " - Wrote #{file}"
    
end

if ARGV.size == 0
    puts "OgreXML to Flower #{FLOWER_VERSION}\n(c) Robin Southern, http://github.com/betajaen/nxogre"
    puts "Usage:\n  ogrexmlconverter.rb <type> <file(s)>"
    puts " - Where type is \"convex\", \"triangle\", \"cloth\" or \"skeleton\"."
    puts " - Where file(s) is a space seperated path for each mesh(s) to convert from."
    puts "Notes:\n - Enclose in \"quotations\" for any file with spaces in its path."
    puts " - SoftBody exporting is not supported."
    puts " - Submeshes are exported as seperate files."
    puts "Example:"
    puts " > ogrexmltoflower triangle ogrehead.mesh.xml"
    puts " > ogrexmltoflower triangle *.mesh.xml"
    Process.exit
end

args = ARGV.clone

type = String.new
type << ARGV[0]

type.downcase!

if ["convex", "triangle", "cloth", "skeleton"].include?(type) == false
    puts "I can only convert into a convex, triangle, skeleton or cloth. Not a '#{type}'."
    Process.exit
end

args.delete_at 0

args.each do |arg|
    read type, arg
end
