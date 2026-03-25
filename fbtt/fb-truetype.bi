#ifndef __FBTRUETYPE2__
#define __FBTRUETYPE2__

#include once "fbgfx.bi"

'' Comment this if you want to use the dynamic lib
#define USE_STATIC_LIB

#ifdef __FB_WIN32__
  #ifndef __FB_64BIT__
    #libpath "fbtt/bin/win"
  #else
    #libpath "fbtt/bin/win"
  #endif   
#else
  #libpath "fbtt/bin/lin"
#endif

#ifndef __FB_64BIT__
  #ifdef USE_STATIC_LIB
    #inclib "FBTrueType-32-static"
  #else
    #inclib "FbTrueType-32"
  #endif
#else
  #ifdef USE_STATIC_LIB
    #inclib "FBTrueType-64-static"
  #else
    #inclib "FbTrueType-64"
  #endif
#endif

'' Error codes returned by fbtt_LoadFont()
#define FBTT_FONT_NOT_LOADED    (-1)
#define FBTT_FONT_NOT_SUPPORTED (-2)
#define FBTT_WRONG_VALUE        (-5)
#define FBTT_GLYPH_NOT_FOUND    (-6)

function fbtt_ErrorText( code as long ) as string
  select case as const( code )
    case FBTT_FONT_NOT_LOADED    : return "Failed to load font"
    case FBTT_FONT_NOT_SUPPORTED : return "Unsupported font" 
    case FBTT_WRONG_VALUE        : return "Parameter out of valid range"
    case FBTT_GLYPH_NOT_FOUND    : return "No glyph present for codepoint"
    case else                    : return "No error"
  end select
end function

'' Font data
type fbtt_FontData
  as ubyte ptr fontData
  as uinteger fontDataSize
  as any ptr fontInfo
end type

' Font properties
type fbtt_FontProps
  as single scale
  as long   advanceHeight '' Space to the next cursor y position (ascent - descent + linegap)
  as long   ascent        '' The space between baseline to top of the font
  as long   descent       '' Space from bottom of the font to base line (negative)
  as long   linegap       '' Space from bottom of the font to next font top line
end type

'' Glyph properties
type fbtt_GlyphProps
  as long advanceWidth    '' The space to the next cursor x position
  as long kernAdvance     '' The kerning can be added to advanceWidth if the glyph has a neighbor glyph
  as long leftSideBearing '' The space from current x position to the left of the glyph
  as long y               '' The absolute y position of the glyph (from font ascent)
  as long w, h            '' Width and height of the visibe part of the glyph
  as long x0, y0, x1, y1  '' Corners of the bounding box for the glyph
end type

'' Internal bounding box of the font
type fbtt_FontBoundingBox
  as long x0, y0, x1, y1
end type

extern "C"
  '' FbTrueType2 C API 
  declare function fbtt_GetLastError() as long
  declare function fbtt_NewFont() as fbtt_FontData ptr
  declare sub fbtt_FreeFont( f as fbtt_FontData ptr )
  declare function fbtt_LoadFont( fileName as zstring ptr ) as fbtt_FontData ptr
  declare function fbtt_LoadFontFromBuffer( buffer as any ptr, size as uinteger ) as fbtt_FontData ptr
  declare sub fbtt_GetFontBoundingBox( f as fbtt_FontData ptr, height as long, byref fProps as fbtt_FontProps, info as fbtt_FontBoundingBox ptr )
  declare sub fbtt_GetFontProperties( f as fbtt_FontData ptr, pixelHeight as long, byref props as fbtt_FontProps )
  declare function fbtt_GetGlyphIndex( f as fbtt_FontData ptr, char as long ) as long
  declare function fbtt_GetDefaultFont() as fbtt_FontData ptr
  declare function fbtt_CopyFont( f as fbtt_FontData ptr ) as fbtt_FontData ptr
  declare function fbtt_GetGlyphProperties( _
    f as fbtt_FontData ptr, fProps as fbtt_FontProps, gProps as fbtt_GlyphProps, index1 as long, index2 as long ) as long
  declare function fbtt_GetGlyphImageRaw( _
    f as fbtt_FontData ptr, byref fProps as fbtt_FontProps, byref gProps as fbtt_GlyphProps, glyphIndex as long ) as any ptr
end extern

#endif