#if NUM_VS_TEXTURES > 0
    struct Layer {
        float scale;
        float bias;
        int mode;
        float zmin;
        float zmax;
    };

    struct ColorData {
        float height;
        float r;
        float g;
        float b;
        float a;
    };

    uniform Layer       elevationLayers[NUM_VS_TEXTURES];
    uniform sampler2D   elevationTextures[NUM_VS_TEXTURES];
    uniform vec4        elevationOffsetScales[NUM_VS_TEXTURES];
    uniform int         elevationTextureCount;
    uniform float       geoidHeight;
    uniform vec4        colorData[NUM_COLORDATA];

    highp float decode32(highp vec4 rgba) {
        highp float Sign = 1.0 - step(128.0,rgba[0])*2.0;
        highp float Exponent = 2.0 * mod(rgba[0],128.0) + step(128.0,rgba[1]) - 127.0;
        highp float Mantissa = mod(rgba[1],128.0)*65536.0 + rgba[2]*256.0 +rgba[3] + float(0x800000);
        highp float Result =  Sign * exp2(Exponent) * (Mantissa * exp2(-23.0 ));
        return Result;
    }

    float getElevationMode(vec2 uv, sampler2D tex, int mode) {
        if (mode == ELEVATION_RGBA)
            return decode32(texture2D( tex, uv ).abgr * 255.0);
        if (mode == ELEVATION_DATA || mode == ELEVATION_COLOR)
        #if defined(WEBGL2)
            return texture2D( tex, uv ).r;
        #else
            return texture2D( tex, uv ).w;
        #endif
        return 0.;
    }

    float getElevation(vec2 uv, sampler2D tex, vec4 offsetScale, Layer layer) {
        uv = uv * offsetScale.zw + offsetScale.xy;
        float d = clamp(getElevationMode(uv, tex, layer.mode), layer.zmin, layer.zmax);
        
        float elevation = 0.0;
        vec3 vcolor = texture2D( tex, uv ).rgb;
        for ( int i = 0; i < NUM_COLORDATA; i ++) {
            vec4 color = colorData[i];
            
            if ((abs(vcolor.r - color.x) < 0.01) && (abs(vcolor.g - color.y) < 0.01) && (abs(vcolor.b - color.z) < 0.01) ) {
                elevation = color.w;
                break;
            }
        }
        if (layer.mode == ELEVATION_DATA || layer.mode == ELEVATION_COLOR)
            return elevation;
        else 
            return d * layer.scale + layer.bias;
    }
#endif
