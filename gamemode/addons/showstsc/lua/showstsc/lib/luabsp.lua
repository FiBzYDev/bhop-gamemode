local lib_id =  debug.getinfo( 1, "S" ).short_src
local luabsp = {}

HEADER_LUMPS = 64
LUMP_ENTITIES =  0
LUMP_PLANES =  1
LUMP_TEXDATA =  2
LUMP_VERTEXES =  3
LUMP_VISIBILITY =  4
LUMP_NODES =  5
LUMP_TEXINFO =  6
LUMP_FACES =  7
LUMP_LIGHTING =  8
LUMP_OCCLUSION =  9
LUMP_LEAFS = 10
LUMP_FACEIDS = 11
LUMP_EDGES = 12
LUMP_SURFEDGES = 13
LUMP_MODELS = 14
LUMP_WORLDLIGHTS = 15
LUMP_LEAFFACES = 16
LUMP_LEAFBRUSHES = 17
LUMP_BRUSHES = 18
LUMP_BRUSHSIDES = 19
LUMP_AREAS = 20
LUMP_AREAPORTALS = 21
LUMP_UNUSED0 = 22
LUMP_UNUSED1 = 23
LUMP_UNUSED2 = 24
LUMP_UNUSED3 = 25
LUMP_DISPINFO = 26
LUMP_ORIGINALFACES = 27
LUMP_PHYSDISP = 28
LUMP_PHYSCOLLIDE = 29
LUMP_VERTNORMALS = 30
LUMP_VERTNORMALINDICES = 31
LUMP_DISP_LIGHTMAP_ALPHAS = 32
LUMP_DISP_VERTS = 33
LUMP_DISP_LIGHTMAP_SAMPLE_POSITIONS = 34
LUMP_GAME_LUMP = 35
LUMP_LEAFWATERDATA = 36
LUMP_PRIMITIVES = 37
LUMP_PRIMVERTS = 38
LUMP_PRIMINDICES = 39
LUMP_PAKFILE = 40
LUMP_CLIPPORTALVERTS = 41
LUMP_CUBEMAPS = 42
LUMP_TEXDATA_STRING_DATA = 43
LUMP_TEXDATA_STRING_TABLE = 44
LUMP_OVERLAYS = 45
LUMP_LEAFMINDISTTOWATER = 46
LUMP_FACE_MACRO_TEXTURE_INFO = 47
LUMP_DISP_TRIS = 48
LUMP_PHYSCOLLIDESURFACE = 49
LUMP_WATEROVERLAYS = 50
LUMP_LEAF_AMBIENT_INDEX_HDR = 51
LUMP_LEAF_AMBIENT_INDEX = 52
LUMP_LIGHTING_HDR = 53
LUMP_WORLDLIGHTS_HDR = 54
LUMP_LEAF_AMBIENT_LIGHTING_HDR = 55
LUMP_LEAF_AMBIENT_LIGHTING = 56
LUMP_XZIPPAKFILE = 57
LUMP_FACES_HDR = 58
LUMP_MAP_FLAGS = 59
LUMP_OVERLAY_FADES = 60
LUMP_OVERLAY_SYSTEM_LEVELS = 61
LUMP_PHYSLEVEL = 62
LUMP_DISP_MULTIBLEND = 63

local function unsigned( val, length )
    local val = val
    if val < 0 then
        val = val + 2^(length*8)
    end
    return val
end

local function plane_intersect( p1, p2, p3 )
    local A1, B1, C1, D1 = p1.A, p1.B, p1.C, p1.D
    local A2, B2, C2, D2 = p2.A, p2.B, p2.C, p2.D
    local A3, B3, C3, D3 = p3.A, p3.B, p3.C, p3.D

    local det = (A1)*( B2*C3 - C2*B3 )
              - (B1)*( A2*C3 - C2*A3 )
              + (C1)*( A2*B3 - B2*A3 )

    if math.abs(det) < 0.001 then return nil end

    local x = (D1)*( B2*C3 - C2*B3 )
            - (B1)*( D2*C3 - C2*D3 )
            + (C1)*( D2*B3 - B2*D3 )

    local y = (A1)*( D2*C3 - C2*D3 )
            - (D1)*( A2*C3 - C2*A3 )
            + (C1)*( A2*D3 - D2*A3 )

    local z = (A1)*( B2*D3 - D2*B3 )
            - (B1)*( A2*D3 - D2*A3 )
            + (D1)*( A2*B3 - B2*A3 )

    return Vector(x,y,z)/det
end

local function is_point_inside_planes( planes, point )
    for i=1, #planes do
        local plane = planes[i]
        local t = point.x*plane.A + point.y*plane.B + point.z*plane.C
        if t - plane.D > 0.01 then return false end
    end
    return true
end

local function vertices_from_planes( planes )
    local verts = {}

    for i=1, #planes do
        local N1 = planes[i]

        for j=i+1, #planes do
            local N2 = planes[j]

            for k=j+1, #planes do
                local N3 = planes[k]

                local pVert = plane_intersect(N1, N2, N3)
                if pVert and is_point_inside_planes(planes,pVert) then
                    verts[#verts + 1] = pVert
                end
            end
        end
    end

    local verts2 = {}
    for _, v1 in pairs(verts) do
        local exist = false
        for __, v2 in pairs(verts2) do
            if (v1-v2):LengthSqr() < 0.001 then
                exist = true
                break
            end
        end

        if not exist then
            verts2[#verts2 + 1] = v1
        end
    end

    return verts2
end

local function str2numbers( str )
    local ret = {}
    for k, v in pairs( string.Explode( " ", str ) ) do
        ret[k] = tonumber(v)
    end
    return unpack( ret )
end

local function find_uv( point, textureVecs, texSizeX, texSizeY )
    local x,y,z = point.x, point.y, point.z
    local u = textureVecs[1].x * x + textureVecs[1].y * y + textureVecs[1].z * z + textureVecs[1].offset
    local v = textureVecs[2].x * x + textureVecs[2].y * y + textureVecs[2].z * z + textureVecs[2].offset
    return u/texSizeX, v/texSizeY
end

local LuaBSP
do
    local entity_datatypes = {
        ["origin"] = "Vector",
        ["sunnormal"] = "Vector",
        ["fogdir"] = "Vector",
        ["world_mins"] = "Vector",
        ["world_maxs"] = "Vector",
        ["angles"] = "Angle",
        ["fogcolor"] = "Color",
        ["fogcolor2"] = "Color",
        ["suncolor"] = "Color",
        ["bottomcolor"] = "Color",
        ["duskcolor"] = "Color",
        ["bottomcolor"] = "Color",
        ["_light"] = "Color",
        ["_lighthdr"] = "Color",
        ["rendercolor"] = "Color",
    }

    local lump_parsers
    lump_parsers = {
        [LUMP_ENTITIES] =
            function(fl, lump_data)
                lump_data.data = {}
                local keyvals =  fl:Read( lump_data.filelen-1 )
                for v in keyvals:gmatch("({.-})") do
                    local data = util.KeyValuesToTable( "_"..v )
                    lump_data.data[#lump_data.data + 1] = data
                end
            end,
        [LUMP_PLANES] =
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = lump_data.filelen / 20

                for i=0, lump_data.size - 1 do
                    lump_data.data[i] = {
                        A = fl:ReadFloat(),
                        B = fl:ReadFloat(),
                        C = fl:ReadFloat(),
                        D = fl:ReadFloat(),
                        type = fl:ReadLong(),
                    }
                end
            end,
        [LUMP_TEXDATA] =
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = lump_data.filelen / 32
                for i=0, lump_data.size - 1 do
                    lump_data.data[i] = {
                        reflectivity = Vector( fl:ReadFloat(), fl:ReadFloat(), fl:ReadFloat() ),
                        nameStringTableID = fl:ReadLong(),
                        width = fl:ReadLong(),
                        height = fl:ReadLong(),
                        view_width = fl:ReadLong(),
                        view_height = fl:ReadLong(),
                    }
                end
            end,
        [LUMP_VERTEXES] =
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = lump_data.filelen / 12
                for i=0, lump_data.size - 1 do
                    lump_data.data[i] = Vector(
                        fl:ReadFloat(),
                        fl:ReadFloat(),
                        fl:ReadFloat()
                    )
                end
            end,
        [LUMP_VISIBILITY] =
            function(fl, lump_data) end,
        [LUMP_NODES] =
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = lump_data.filelen / 32
                for i=0, lump_data.size - 1 do
                    lump_data.data[i] = {
                        planenum = fl:ReadLong(),
                        children = { fl:ReadLong(), fl:ReadLong() },
                        mins = Vector(  fl:ReadShort(), fl:ReadShort(), fl:ReadShort() ),
                        maxs = Vector(  fl:ReadShort(), fl:ReadShort(), fl:ReadShort() ),
                        firstface = unsigned( fl:ReadShort(), 2 ),
                        numfacesu = unsigned( fl:ReadShort(), 2 ),
                        area = fl:ReadShort(),
                    }
                    fl:ReadShort()
                end
            end,
        [LUMP_TEXINFO] =
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = lump_data.filelen / 72
                for i=0, lump_data.size - 1 do
                    lump_data.data[i] = {
                        textureVecs = {
                            { x = fl:ReadFloat(), y = fl:ReadFloat(), z = fl:ReadFloat(), offset = fl:ReadFloat()},
                            { x = fl:ReadFloat(), y = fl:ReadFloat(), z = fl:ReadFloat(), offset = fl:ReadFloat()},
                        },
                        lightmapVecs = {
                            { x = fl:ReadFloat(), y = fl:ReadFloat(), z = fl:ReadFloat(), offset = fl:ReadFloat()},
                            { x = fl:ReadFloat(), y = fl:ReadFloat(), z = fl:ReadFloat(), offset = fl:ReadFloat()},
                        },
                        flags = fl:ReadLong(),
                        texdata = fl:ReadLong(),
                    }
                end
            end,
        [LUMP_FACES] =
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = lump_data.filelen / 56
                for i=0, lump_data.size - 1 do
                    lump_data.data[i] = {
                        planenum = unsigned( fl:ReadShort(), 2 ),
                        side = fl:ReadByte(),
                        onNode = fl:ReadByte(),
                        firstedge = fl:ReadLong(),
                        numedges = fl:ReadShort(),
                        texinfo = fl:ReadShort(),
                        dispinfo = fl:ReadShort(),
                        surfaceFogVolumeID = fl:ReadShort(),
                        styles = {
                            fl:ReadByte(),
                            fl:ReadByte(),
                            fl:ReadByte(),
                            fl:ReadByte(),
                        },
                        lightofs = fl:ReadLong(),
                        area = fl:ReadFloat(),
                        LightmapTextureMinsInLuxels = {
                            fl:ReadLong(),
                            fl:ReadLong(),
                        },
                        LightmapTextureSizeInLuxels = {
                            fl:ReadLong(),
                            fl:ReadLong(),
                        },
                        origFace = fl:ReadLong(),
                        numPrims = unsigned( fl:ReadShort(), 2 ),
                        firstPrimID = unsigned( fl:ReadShort(), 2 ),
                        smoothingGroups = unsigned( fl:ReadLong(), 4 ),
                    }
                end
            end,
        [LUMP_LIGHTING] = -- Lightmap samples
            function(fl, lump_data) end,
        [LUMP_OCCLUSION] = -- Occlusion polygons and vertices
            function(fl, lump_data) end,
        [LUMP_LEAFS] = -- BSP tree leaf nodes
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = lump_data.filelen / 30
                for i=0, lump_data.size - 1 do
                    local data = {
                        contents = fl:ReadLong(), -- OR of all brushes (not needed?)
                        cluster = fl:ReadShort(), -- cluster this leaf is in
                        flags = fl:ReadShort(), -- area this leaf is in and flags
                        mins = Vector( fl:ReadShort(), fl:ReadShort(), fl:ReadShort() ), -- for frustum culling
                        maxs = Vector( fl:ReadShort(), fl:ReadShort(), fl:ReadShort() ),
                        firstleafface = unsigned( fl:ReadShort(), 2 ), -- index into leaffaces
                        numleaffaces = unsigned( fl:ReadShort(), 2 ),
                        firstleafbrush = unsigned( fl:ReadShort(), 2 ), -- index into leafbrushes
                        numleafbrushes = unsigned( fl:ReadShort(), 2 ),
                        leafWaterDataID = fl:ReadShort(),
                    }

                    data.area = bit.band(data.flags, 0x7F)
                    data.flags = bit.band(bit.rshift(data.flags, 9), 0x1FF)
                    lump_data.data[i] = data
                    fl:Read(2) -- padding

                end
            end,
        [LUMP_FACEIDS] =
            function(fl, lump_data) end,
        [LUMP_EDGES] =
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = lump_data.filelen / 4
                for i=0, lump_data.size - 1 do
                    lump_data.data[i] = {
                        unsigned( fl:ReadShort(), 2 ),
                        unsigned( fl:ReadShort(), 2 ),
                    }
                end
            end,
        [LUMP_SURFEDGES] =
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = lump_data.filelen / 4
                for i=0, lump_data.size - 1 do
                    lump_data.data[i] = fl:ReadLong()
                end
            end,
        [LUMP_MODELS] =
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = lump_data.filelen / 48
                for i=0, lump_data.size - 1 do
                    lump_data.data[i] = {
                        mins = Vector( fl:ReadFloat(), fl:ReadFloat(), fl:ReadFloat() ),
                        maxs = Vector( fl:ReadFloat(), fl:ReadFloat(), fl:ReadFloat() ),
                        origin = Vector( fl:ReadFloat(), fl:ReadFloat(), fl:ReadFloat() ),
                        headnode = fl:ReadLong(),
                        firstface = fl:ReadLong(),
                        numfaces = fl:ReadLong(),
                    }
                end
            end,
        [LUMP_WORLDLIGHTS] =
            function(fl, lump_data) end,
        [LUMP_LEAFFACES] =
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = lump_data.filelen / 2
                for i=0, lump_data.size - 1 do
                    lump_data.data[i] = unsigned( fl:ReadShort(), 2 )
                end
            end,
        [LUMP_LEAFBRUSHES] =
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = lump_data.filelen / 2
                for i=0, lump_data.size - 1 do
                    lump_data.data[i] = unsigned( fl:ReadShort(), 2 )
                end
            end,
        [LUMP_BRUSHES] =
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = lump_data.filelen / 12
                for i=0, lump_data.size - 1 do
                    lump_data.data[i] = {
                        firstside = fl:ReadLong(),
                        numsides = fl:ReadLong(),
                        contents = fl:ReadLong(),
                    }
                end
            end,
        [LUMP_BRUSHSIDES] =
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = lump_data.filelen / 8
                for i=0, lump_data.size - 1 do
                    lump_data.data[i] = {
                        planenum = unsigned( fl:ReadShort(), 2 ),
                        texinfo =  fl:ReadShort(),
                        dispinfo = fl:ReadShort(),
                        bevel = fl:ReadShort(),
                    }
                end
            end,
        [LUMP_AREAS] =
            function(fl, lump_data) end,
        [LUMP_AREAPORTALS] =
            function(fl, lump_data) end,
        [LUMP_UNUSED0] =
            function(fl, lump_data) end,
        [LUMP_UNUSED1] =
            function(fl, lump_data) end,
        [LUMP_UNUSED2] =
            function(fl, lump_data) end,
        [LUMP_UNUSED3] =
            function(fl, lump_data) end,
        [LUMP_DISPINFO] =
            function(fl, lump_data) end,
        [LUMP_ORIGINALFACES] =
            function(fl, lump_data)
                lump_parsers[LUMP_FACES]( fl, lump_data )
            end,
        [LUMP_PHYSDISP] =
            function(fl, lump_data) end,
        [LUMP_PHYSCOLLIDE] =
            function(fl, lump_data) end,
        [LUMP_VERTNORMALS] =
            function(fl, lump_data) end,
        [LUMP_VERTNORMALINDICES] =
            function(fl, lump_data) end,
        [LUMP_DISP_LIGHTMAP_ALPHAS] =
            function(fl, lump_data) end,
        [LUMP_DISP_VERTS] =
            function(fl, lump_data) end,
        [LUMP_DISP_LIGHTMAP_SAMPLE_POSITIONS] =
            function(fl, lump_data) end,
        [LUMP_GAME_LUMP] =
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = fl:ReadLong()
                for i=1,lump_data.size do
                    lump_data.data[i] = {
                        id      = fl:Read( 4 ),
                        flags   = fl:ReadShort(),
                        version = fl:ReadShort(),
                        fileofs = fl:ReadLong(),
                        filelen = fl:ReadLong(),
                    }
                end
            end,
        [LUMP_LEAFWATERDATA] =
            function(fl, lump_data) end,
        [LUMP_PRIMITIVES] =
            function(fl, lump_data) end,
        [LUMP_PRIMVERTS] =
            function(fl, lump_data) end,
        [LUMP_PRIMINDICES] =
            function(fl, lump_data) end,
        [LUMP_PAKFILE] =
            function(fl, lump_data) end,
        [LUMP_CLIPPORTALVERTS] =
            function(fl, lump_data) end,
        [LUMP_CUBEMAPS] =
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = lump_data.filelen / 16

                for i=0, lump_data.size - 1 do
                    local origin = Vector(fl:ReadLong(), fl:ReadLong(), fl:ReadLong())
                    local size = fl:ReadLong()

                    if size < 1 then size = 6 end

                    lump_data.data[i] = {
                        origin = origin,
                        size = 2^(size-1)
                    }
                end
            end,
        [LUMP_TEXDATA_STRING_DATA] =
            function(fl, lump_data)
                lump_data.data = {}
                local data = string.Explode( "\0", fl:Read(lump_data.filelen) )
                local offset = 0
                for k, v in pairs(data) do
                    lump_data.data[offset] = v
                    offset = offset + 1 + #v
                end
            end,
        [LUMP_TEXDATA_STRING_TABLE] =
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = lump_data.filelen / 4
                for i=0, lump_data.size - 1 do
                    lump_data.data[i] = fl:ReadLong()
                end
            end,
        [LUMP_OVERLAYS] =
            function(fl, lump_data) end,
        [LUMP_LEAFMINDISTTOWATER] =
            function(fl, lump_data) end,
        [LUMP_FACE_MACRO_TEXTURE_INFO] =
            function(fl, lump_data) end,
        [LUMP_DISP_TRIS] =
            function(fl, lump_data) end,
        [LUMP_PHYSCOLLIDESURFACE] =
            function(fl, lump_data) end,
        [LUMP_WATEROVERLAYS] =
            function(fl, lump_data) end,
        [LUMP_LEAF_AMBIENT_INDEX_HDR] =
            function(fl, lump_data) end,
        [LUMP_LEAF_AMBIENT_INDEX] =
            function(fl, lump_data) end,
        [LUMP_LIGHTING_HDR] =
            function(fl, lump_data) end,
        [LUMP_WORLDLIGHTS_HDR] =
            function(fl, lump_data) end,
        [LUMP_LEAF_AMBIENT_LIGHTING_HDR] =
            function(fl, lump_data) end,
        [LUMP_LEAF_AMBIENT_LIGHTING] =
            function(fl, lump_data) end,
        [LUMP_XZIPPAKFILE] =
            function(fl, lump_data) end,
        [LUMP_FACES_HDR] =
            function(fl, lump_data) end,
        [LUMP_MAP_FLAGS] =
            function(fl, lump_data) end,
        [LUMP_OVERLAY_FADES] =
            function(fl, lump_data) end,
        [LUMP_OVERLAY_SYSTEM_LEVELS] =
            function(fl, lump_data) end,
        [LUMP_PHYSLEVEL] = --
            function(fl, lump_data) end,
        [LUMP_DISP_MULTIBLEND] =
            function(fl, lump_data) end,
    }

    LuaBSP = {}
    LuaBSP.__index = LuaBSP

    function LuaBSP:GetMapFileHandle( mapname )
        self.mapname = mapname or self.mapname
        local filename = "maps/"..self.mapname..".bsp"
        local fl = file.Open( filename, "rb", "GAME")
        if not fl then error( "[LuaBSP] Unable to open: "..filename ) end

        return fl
    end

    function LuaBSP.new( mapname )
        assert( mapname, "[LuaBSP] Invalid map name" )

        local self = setmetatable({}, LuaBSP)
        local filename = "maps/"..mapname..".bsp"
        local fl = self:GetMapFileHandle( mapname )

        local ident = fl:Read( 4 )
        if ident ~= "VBSP" then error( "[LuaBSP] Invalid file header: "..ident ) return end

        self.version = fl:ReadLong()
        self.lumps = {}
        self.weakLumps = setmetatable({}, { __mode = "v" })

        for i=0, HEADER_LUMPS-1 do
            self.lumps[i] = {
                fileofs = fl:ReadLong(),
                filelen = fl:ReadLong(),
                version = fl:ReadLong(),
                fourCC  = fl:Read( 4 ),
            }
        end
        self.map_revision = fl:ReadLong()

        fl:Close()

        return self
    end

    function LuaBSP:LoadLumps( ... )
        local fl = self:GetMapFileHandle()

        for k, lump in ipairs( {...} ) do
            local lump_data = self.lumps[lump]
            if not lump_data.data and not self.weakLumps[lump] then
                fl:Seek( lump_data.fileofs )
                lump_parsers[lump]( fl, lump_data )
            end
        end

        fl:Close()
    end

    function LuaBSP:LoadStaticProps()
        self:LoadLumps( LUMP_GAME_LUMP )

        local fl   = self:GetMapFileHandle()
        local lump = self.lumps[LUMP_GAME_LUMP]

        local static_props = {}
        for _,game_lump in ipairs( lump.data ) do
            local version = game_lump.version
            local static_props_entry = {
                names        = {},
                leaf         = {},
                leaf_entries = 0,
                entries      = {},
            }

            if not (version >= 4 and version < 12) then continue end

            fl:Seek( game_lump.fileofs )

            local dict_entries = fl:ReadLong()
            if dict_entries < 0 or dict_entries >= 9999 then continue end

            for i=1,dict_entries do
                static_props_entry.names[i-1] = fl:Read( 128 ):match( "^[^%z]+" ) or ""
            end

            local leaf_entries = fl:ReadLong()
            if leaf_entries < 0 then continue end

            static_props_entry.leaf_entries = leaf_entries
            for i=1,leaf_entries do
                static_props_entry.leaf[i] = fl:ReadUShort()
            end

            local amount = fl:ReadLong()
            if amount < 0 or amount >= ( 8192 * 2 ) then continue end

            for i=1,amount do
                local static_prop = {}
                static_props_entry.entries[i] = static_prop

                static_prop.Origin = Vector( fl:ReadFloat(), fl:ReadFloat(), fl:ReadFloat() )
                static_prop.Angles = Angle( fl:ReadFloat(), fl:ReadFloat(), fl:ReadFloat() )

                if version >= 11 then
                    static_prop.Scale = fl:ReadShort()
                end

                local _1,_2 = string.byte(fl:Read(2),1,2)
                local proptype = _1 + _2 * 256

                static_prop.PropType = static_props_entry.names[proptype]
                if not static_prop.PropType then continue end

                static_prop.FirstLeaf = fl:ReadShort()
                static_prop.LeafCount = fl:ReadShort()
                static_prop.Solid     = fl:ReadByte()
                static_prop.Flags     = fl:ReadByte()
                static_prop.Skin      = fl:ReadLong()
                if not static_prop.Skin then continue end

                static_prop.FadeMinDist    = fl:ReadFloat()
                static_prop.FadeMaxDist    = fl:ReadFloat()
                static_prop.LightingOrigin = Vector( fl:ReadFloat(), fl:ReadFloat(), fl:ReadFloat() )

                if version >= 5 then
                    static_prop.ForcedFadeScale = fl:ReadFloat()
                end

                if version == 6 or version == 7 then
                    static_prop.MinDXLevel = fl:ReadShort()
                    static_prop.MaxDXLevel = fl:ReadShort()
                end

                if version >= 8 then
                    static_prop.MinCPULevel = fl:ReadByte()
                    static_prop.MaxCPULevel = fl:ReadByte()
                    static_prop.MinGPULevel = fl:ReadByte()
                    static_prop.MaxGPULevel = fl:ReadByte()
                end

                if version >= 7 then
                    static_prop.DiffuseModulation = Color( string.byte( fl:Read( 4 ), 1, 4 ) )
                end

                if version >= 10 then
                    static_prop.unknown = fl:ReadFloat()
                end

                if version == 9 then
                    static_prop.DisableX360 = fl:ReadByte() == 1
                end

            end

            table.insert( static_props, static_props_entry )
        end

        self.static_props = static_props

        fl:Close()
    end

    function LuaBSP:GetLumpData(lump, force, keep)
        local lump_data = self.lumps[lump]

        if (lump_data.data or self.weakLumps[lump]) == nil or force then
            local fl = self:GetMapFileHandle()
            fl:Seek(lump_data.fileofs)
            lump_parsers[lump](fl, lump_data)
            fl:Close()

            if force and not keep then
                self.weakLumps[lump] = lump_data.data
                lump_data.data = nil
            end
        end

        return lump_data.data or self.weakLumps[lump]
    end

    function LuaBSP:GetTexData(texdata_id)
        local texdata = self:GetLumpData(LUMP_TEXDATA)[texdata_id]
        if texdata.p_nameString then return texdata end
        local offset = self:GetLumpData(LUMP_TEXDATA_STRING_TABLE)[texdata.nameStringTableID]
        texdata.p_nameString = self:GetLumpData(LUMP_TEXDATA_STRING_DATA)[offset]
        return texdata
    end

    function LuaBSP:PointsToMeshVerts(points, norm, mesh_verts, color)
        local ref = Vector(0, 0, -1)
        if math.abs(norm:Dot(Vector(0, 0, 1))) == 1 then ref = Vector(0, 1, 0) end

        local tv1 = norm:Cross(ref):Cross(norm):GetNormalized()
        local tv2 = norm:Cross(tv1)

        local textureVecs = {
            { x = tv2.x, y = tv2.y, z = tv2.z, offset = 0 },
            { x = tv1.x, y = tv1.y, z = tv1.z, offset = 0 },
        }

        for j = 1, #points - 2 do
            local u1, v1 = find_uv(points[1],     textureVecs, 32, 32)
            local u2, v2 = find_uv(points[j + 1], textureVecs, 32, 32)
            local u3, v3 = find_uv(points[j + 2], textureVecs, 32, 32)
            mesh_verts[#mesh_verts + 1] = { pos = points[1],     u = u1, v = v1 }
            mesh_verts[#mesh_verts + 1] = { pos = points[j + 1], u = u2, v = v2 }
            mesh_verts[#mesh_verts + 1] = { pos = points[j + 2], u = u3, v = v3 }
        end
    end

    local FindLeafTraverse
    FindLeafTraverse = function(lumps, node_id, pos)
        if node_id < 0 then return -(node_id + 1) end

        local node = lumps[LUMP_NODES]["data"][node_id]
        local plane = lumps[LUMP_PLANES]["data"][node.planenum]
        local d = pos.x*plane.A + pos.y*plane.B + pos.z*plane.C

        return FindLeafTraverse(lumps, node.children[(d - plane.D > 0) and 1 or 2], pos)
    end

    function LuaBSP:FindLeaf(pos)
        self:GetLumpData(LUMP_NODES) self:GetLumpData(LUMP_PLANES)
        local leaf_id = FindLeafTraverse(self.lumps, 0, pos)
        local leaf = self:GetLumpData(LUMP_LEAFS)[leaf_id]
        return leaf_id, leaf
    end

    local AddNodeLeafsTraverse
    AddNodeLeafsTraverse = function(nodes, node_id, leafs)
        if node_id < 0 then
            leafs[#leafs + 1] = -(node_id + 1)
            return
        end

        local children = nodes[node_id].children
        AddNodeLeafsTraverse(nodes, children[1], leafs)
        AddNodeLeafsTraverse(nodes, children[2], leafs)
    end

    function LuaBSP:GetNodeLeafs(node_id)
        local nodes, leafs = self:GetLumpData(LUMP_NODES), {}
        AddNodeLeafsTraverse(nodes, node_id, leafs)
        return leafs
    end
    function LuaBSP:GetFacesMesh(surf_flags, texture_name, single_mesh, original)
        local target_lump = original and LUMP_ORIGINALFACES or LUMP_FACES
        self:LoadLumps(target_lump, LUMP_SURFEDGES, LUMP_EDGES, LUMP_PLANES, LUMP_TEXINFO,
            LUMP_TEXDATA, LUMP_TEXDATA_STRING_DATA, LUMP_TEXDATA_STRING_TABLE)

        local faces = self:GetLumpData(target_lump)
        local brush_verts, meshes, count = {}, {}, 0

        for face_id, face in pairs(faces) do
            local texinfo = self:GetLumpData(LUMP_TEXINFO)[face.texinfo]
            if not texinfo or face.dispinfo ~= -1 then continue end

            local texdata = self:GetTexData(texinfo.texdata)
            if surf_flags and (surf_flags < 0 or texinfo.flags ~= surf_flags)
                and (surf_flags >= 0 or bit.band(texinfo.flags, surf_flags) == 0) then continue end
            if texture_name and not string.find(texdata.p_nameString, texture_name) then continue end

            if not single_mesh then brush_verts = {} end

            self:AddFaceVertices(face, brush_verts)

            count = count + 1
            if not single_mesh then
                local obj = Mesh()
                obj:BuildFromTriangles(brush_verts)
                meshes[face_id] = obj
            end
        end

        if single_mesh then
            local obj = Mesh()
            obj:BuildFromTriangles(brush_verts)
            return obj, count
        end

        return meshes, count
    end

    function LuaBSP:AddFaceVertices(face, mesh_verts)
        local verts = self:GetLumpData(LUMP_VERTEXES)
        local plane = self:GetLumpData(LUMP_PLANES)[face.planenum]
        local points = {}

        for i = 0, face.numedges - 1 do
            local index = self:GetLumpData(LUMP_SURFEDGES)[face.firstedge + i]
            local edge = self:GetLumpData(LUMP_EDGES)[math.abs(index)]

            if index < 0 then
                points[#points + 1], points[#points + 2] = verts[edge[2]], verts[edge[1]]
            else
                points[#points + 1], points[#points + 2] = verts[edge[1]], verts[edge[2]]
            end
        end

        self:PointsToMeshVerts(points, Vector(plane.A, plane.B, plane.C), mesh_verts)

        return points
    end

    function LuaBSP:AddBrushToLeafMap(leaf, leaf_id, leaf_brushes, brushes)
        local firstBrush, numBrushes = leaf.firstleafbrush, leaf.numleafbrushes
        for i = 0, numBrushes - 1 do
            local idx = leaf_brushes[firstBrush + i]
            if idx then brushes[idx] = leaf_id end
        end
        return brushes
    end

    function LuaBSP:GetBrushesByLeaf(leaf_id)
        return table.GetKeys(self:AddBrushToLeafMap(self:GetLumpData(LUMP_LEAFS)[leaf_id],
            leaf_id, self:GetLumpData(LUMP_LEAFBRUSHES), {}))
    end

    function LuaBSP:GetBrushesByModel(model_id)
        local model = self:GetLumpData(LUMP_MODELS)[model_id]
        local leafs = self:GetLumpData(LUMP_LEAFS)
        local leafs_ids = self:GetNodeLeafs(model.headnode)
        local brushes, leaf_brushes = {}, self:GetLumpData(LUMP_LEAFBRUSHES)

        for _, leaf_id in ipairs(leafs_ids) do
            self:AddBrushToLeafMap(leafs[leaf_id], leaf_id, leaf_brushes, brushes)
        end

        return table.GetKeys(brushes), model
    end

    function LuaBSP:GetModelMesh(model_id)
        self:LoadLumps(LUMP_BRUSHES, LUMP_BRUSHSIDES, LUMP_PLANES)
        local brushes_arr, model = self:GetBrushesByModel(model_id)
        local brushes, brush_verts = self.lumps[LUMP_BRUSHES]["data"], {}

        for _, brush_id in ipairs(brushes_arr) do
            local brush = brushes[brush_id]
            if not brush then continue end
            local bsides, points = self:GetBrushSides(brush)
            self:AddBrushVertices(bsides, points, brush_verts)
        end

        local obj = Mesh()
        obj:BuildFromTriangles(brush_verts)
        return obj, model, brushes_arr
    end

    function LuaBSP:GetBrushesByContents(contents)
        self:LoadLumps(LUMP_BRUSHES)

        local brushes, result = self.lumps[LUMP_BRUSHES]["data"], {}

        for brush_id = 0, #brushes - 1 do
            local brush = brushes[brush_id]
            if bit.band(brush.contents, contents) ~= 0 then result[#result + 1] = brush end
        end

        return result
    end

    function LuaBSP:GetBrushSidePoints(plane, brush_points)
        local points = {}

        for __, point in pairs(brush_points) do
            local t = point.x*plane.A + point.y*plane.B + point.z*plane.C
            if math.abs(t - plane.D) > 0.01 then continue end
            points[#points + 1] = point
        end

        local norm, c = Vector(plane.A, plane.B, plane.C), points[1]
        table.sort(points, function(a, b)
            return norm:Dot((c - a):Cross(b - c)) > 0.001
        end)

        return points
    end

    function LuaBSP:GetBrushSidesFiltered(brush, surf_flags, texture_name)
        local brush_firstside = brush.firstside
        local brush_numsides = brush.numsides
        local bsides, planes = {}, {}

        for i = 0, brush_numsides - 1 do
            local brushside = self.lumps[LUMP_BRUSHSIDES]["data"][brush_firstside + i]
            local texinfo = self.lumps[LUMP_TEXINFO]["data"][brushside.texinfo]
            local texdata = self:GetTexData(texinfo.texdata)

            if brushside.bevel ~= 0 then continue end

            local plane = self.lumps[LUMP_PLANES]["data"][brushside.planenum]
            planes[#planes + 1] = plane

            if surf_flags and (surf_flags < 0 or texinfo.flags ~= surf_flags)
                and (surf_flags >= 0 or bit.band(texinfo.flags, -surf_flags) == 0) then continue end
            if texture_name and not string.find(texdata.p_nameString, texture_name) then continue end

            bsides[#bsides + 1] = {
                brushside = brushside,
                texinfo = texinfo,
                texdata = texdata,
                plane = plane,
            }
        end

        return bsides, #bsides ~= 0 and vertices_from_planes(planes) or bsides
    end

    function LuaBSP:GetBrushSides(brush)
        local brush_firstside = brush.firstside
        local brush_numsides = brush.numsides
        local bsides, planes = {}, {}

        for i = 0, brush_numsides - 1 do
            local brushside = self.lumps[LUMP_BRUSHSIDES]["data"][brush_firstside + i]

            if brushside.bevel ~= 0 then continue end

            local plane = self.lumps[LUMP_PLANES]["data"][brushside.planenum]
            planes[#planes + 1] = plane
            bsides[#bsides + 1] = {
                brushside = brushside,
                plane = plane,
            }
        end

        return bsides, vertices_from_planes(planes)
    end

    function LuaBSP:GetBrushCollisionVertices(bsides, brush_points)
        local brush_verts = {}

        for _, bside in pairs(bsides) do
            local plane = bside.plane
            if not plane then continue end

            local points = self:GetBrushSidePoints(plane, brush_points)

            for j = 1, #points - 2 do
                brush_verts[#brush_verts + 1] = { pos = points[1]     }
                brush_verts[#brush_verts + 1] = { pos = points[j + 1] }
                brush_verts[#brush_verts + 1] = { pos = points[j + 2] }
            end
        end

        return brush_verts
    end

    function LuaBSP:AddBrushVertices(bsides, brush_points, brush_verts)
        for _, bside in pairs(bsides) do
            local plane = bside.plane
            if not plane then continue end

            local points = self:GetBrushSidePoints(plane, brush_points)
            self:PointsToMeshVerts(points, Vector(plane.A, plane.B, plane.C), brush_verts)
        end
    end

    function LuaBSP:GetBrushesMeshFiltered(contents, surf_flags, texture_name, single_mesh)
        self:LoadLumps(LUMP_BRUSHES, LUMP_BRUSHSIDES, LUMP_PLANES, LUMP_TEXINFO,
            LUMP_TEXDATA, LUMP_TEXDATA_STRING_DATA, LUMP_TEXDATA_STRING_TABLE)

        local brushes = self.lumps[LUMP_BRUSHES]["data"]
        local brush_verts, meshes, count = {}, {}, 0

        for brush_id = 0, #brushes - 1 do
            local brush = brushes[brush_id]
            if contents and (contents < 0 or brush.contents ~= contents)
                and (contents >= 0 or bit.band(brush.contents, -contents) == 0) then continue end

            if not single_mesh then brush_verts = {} end

            local bsides, points = self:GetBrushSidesFiltered(brush, surf_flags, texture_name)
            if #bsides == 0 then continue end

            self:AddBrushVertices(bsides, points, brush_verts)

            count = count + 1
            if not single_mesh then
                local obj = Mesh()
                obj:BuildFromTriangles(brush_verts)
                meshes[brush_id] = obj
            end
        end

        if single_mesh then
            local obj = Mesh()
            obj:BuildFromTriangles(brush_verts)
            return obj, count
        end

        return meshes, count
    end

    function LuaBSP:GetBrushesMesh(contents, single_mesh)
        self:LoadLumps(LUMP_BRUSHES, LUMP_BRUSHSIDES, LUMP_PLANES)

        local brushes = self.lumps[LUMP_BRUSHES]["data"]
        local brush_verts, meshes, count = {}, {}, 0

        for brush_id = 0, #brushes - 1 do
            local brush = brushes[brush_id]

            if contents and bit.band(brush.contents, contents) == 0 then continue end

            if not single_mesh then brush_verts = {} end

            local bsides, points = self:GetBrushSides(brush)
            self:AddBrushVertices(bsides, points, brush_verts)

            count = count + 1
            if not single_mesh then
                local obj = Mesh()
                obj:BuildFromTriangles(brush_verts)
                meshes[brush_id] = obj
            end
        end

        if single_mesh then
            local obj = Mesh()
            obj:BuildFromTriangles(brush_verts)
            return obj, count
        end

        return meshes
    end

    function LuaBSP:GetClipBrushes( single_mesh )
        self:LoadLumps( LUMP_BRUSHES, LUMP_BRUSHSIDES, LUMP_PLANES, LUMP_TEXINFO )

        local brushes = {}
        local brush_verts = {}

        for brush_id = 0, #self.lumps[LUMP_BRUSHES]["data"]-1 do
            local brush = self.lumps[LUMP_BRUSHES]["data"][brush_id]
            local brush_firstside = brush.firstside
            local brush_numsides = brush.numsides
            local brush_contents = brush.contents

            if bit.band( brush_contents, CONTENTS_PLAYERCLIP ) == 0 then continue end

            local base_color = Vector(1,0,1)
            if not single_mesh then
                brush_verts = {}
            end

            brush.p_bsides = {}
            local planes = {}
            for i = 0, brush_numsides - 1 do
                local brushside_id = (brush_firstside + i)
                local brushside = self.lumps[LUMP_BRUSHSIDES]["data"][brushside_id]
                if brushside.bevel ~= 0 then continue end
                local plane = self.lumps[LUMP_PLANES]["data"][brushside.planenum]
                brush.p_bsides[#brush.p_bsides + 1] = {
                    brushside = brushside,
                    plane = plane
                }
                planes[#planes + 1] = plane
            end

            brush.p_points = vertices_from_planes(planes)
            brush.p_render_data = {}
            for _, bside in pairs(brush.p_bsides) do
                local plane = bside.plane
                if not plane then continue end
                local render_data = {
                    texinfo = bside.brushside.texinfo,
                    plane = plane,
                    points = {},
                }
                for __, point in pairs(brush.p_points) do
                    local t = point.x*plane.A + point.y*plane.B + point.z*plane.C
                    if math.abs(t-plane.D) > 0.01  then continue end

                    render_data.points[#render_data.points + 1] = point
                end

                local norm = Vector(plane.A, plane.B, plane.C)
                local c = render_data.points[1]
                table.sort(render_data.points, function(a, b)
                    return norm:Dot((c-a):Cross(b-c)) > 0.001
                end)

                render_data.norm = norm

                local points = render_data.points
                local norm = render_data.norm
                local dot = math.abs( norm:Dot(Vector(-1,100,100):GetNormalized()) )
                local color = Color(100+55*dot,100+55*dot,100+55*dot)
                color.r = color.r * base_color.x
                color.g = color.g * base_color.y
                color.b = color.b * base_color.z
                color.a = 255

                local texinfo = self.lumps[LUMP_TEXINFO]["data"][render_data.texinfo]

                local ref = Vector(0,0,-1)
                if math.abs( norm:Dot( Vector(0,0,1) ) ) == 1 then
                    ref = Vector(0,1,0)
                end

                local tv1 = norm:Cross( ref ):Cross( norm ):GetNormalized()
                local tv2 = norm:Cross( tv1 )

                local textureVecs = {{x=tv2.x,y=tv2.y,z=tv2.z,offset=0},
                                    {x=tv1.x,y=tv1.y,z=tv1.z,offset=0}}
                local u, v
                for j = 1, #points - 2 do
                    u1, v1 = find_uv(points[1], textureVecs, 32, 32)
                    u2, v2 = find_uv(points[j+1], textureVecs, 32, 32)
                    u3, v3 = find_uv(points[j+2], textureVecs, 32, 32)
                    brush_verts[#brush_verts + 1] = { pos = points[1]+norm*0  , u = u1, v = v1, color = color }
                    brush_verts[#brush_verts + 1] = { pos = points[j+1]+norm*0, u = u2, v = v2, color = color }
                    brush_verts[#brush_verts + 1] = { pos = points[j+2]+norm*0, u = u3, v = v3, color = color }
                end
            end

            if not single_mesh then
                local obj = Mesh()
                obj:BuildFromTriangles( brush_verts )

                brush.p_mesh = obj
                brushes[#brushes+1] = obj
            end
        end

        if single_mesh then
            local obj = Mesh()
            obj:BuildFromTriangles( brush_verts )

            return obj
        end

        return brushes
    end
end

function luabsp.LoadMap( map_name )
    return LuaBSP.new( map_name )
end

function luabsp.GetLibraryID()
    return lib_id
end
return luabsp