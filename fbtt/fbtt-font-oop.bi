#ifndef __FBTRUETYPE_FONT__
#define __FBTRUETYPE_FONT__

#include once "fb-truetype.bi"
#include once "fbtt-commons.bi"

namespace Fb
  type ClipRegion
    declare constructor()
    declare constructor( as long, as long, as long, as long )
    
    as long x1, y1, x2, y2
  end type
  
  constructor ClipRegion() : end constructor
  
  constructor ClipRegion( nX1 as long, nY1 as long, nX2 as long, nY2 as long )
    x1 = nX1 : y1 = nY1 : x2 = nX2 : y2 = nY2
  end constructor
  
  type TextRegion
    as long width, height
    as long baseline
  end type
  
  type CharRegion
    as long x, y, width, height
  end type
  
  type Font
    public:
      declare constructor()
      declare constructor( as Font )
      declare destructor()
      
      declare operator let( as Font )
      
      declare property size() as long
      declare property size( as long )
      declare property useBaseline() as boolean
      declare property useBaseline( as boolean )
      declare property baseline() as long
      declare property fontHeight() as long
      declare property fontData() as fbtt_FontData ptr
      declare property fontProps() as fbtt_FontProps ptr
      
      declare sub render( as long, as long, as string, as ulong, as any ptr = 0 )
      declare sub render_clipped( as ClipRegion, as long, as long, as string, as ulong, as any ptr = 0 )
      declare function measure( as string ) as TextRegion
      declare function measureChars( as string, a() as CharRegion ) as long
      declare function measureChars_exact( as string, a() as CharRegion ) as long
      
      declare function getCharBitmap( as long, byref as long, byref as long ) as any ptr
      
      declare static function fromFile( as string ) as Font
      declare static function fromBuffer( as any ptr, as uinteger ) as Font
    
    private:
      declare constructor( as fbtt_FontData ptr )
      
      declare sub setFontProperties()
      declare sub renderGlyph_new( as long, as long, as ubyte ptr, as fbtt_GlyphProps, as ulong, as Fb.Image ptr = 0, as ulong = 256 )
      declare sub renderGlyph_clipped( as ClipRegion, as long, as long, as ubyte ptr, as fbtt_GlyphProps, as ulong, as Fb.Image ptr = 0, as ulong = 256 )
      
      as fbtt_FontData ptr _fontData
      as fbtt_FontBoundingBox _bb
      as fbtt_FontProps _fProps
      as long _size = 20
      as long _height, _baseline
      as boolean _useBaseline
  end type
  
  constructor Font()
    _fontData = fbtt_GetDefaultFont()
    setFontProperties()
  end constructor
  
  constructor Font( rhs as Font )
    fbtt_FreeFont( _fontData )
    _fontData = fbtt_CopyFont( rhs._fontData )
    setFontProperties()
  end constructor
  
  constructor Font( fd as fbtt_FontData ptr )
    _fontData = fd
    setFontProperties()
  end constructor
  
  destructor Font()
    fbtt_FreeFont( _fontData )
  end destructor
  
  operator Font.let( rhs as Font )
    fbtt_FreeFont( _fontData )
    _fontData = fbtt_CopyFont( rhs._fontData )
    setFontProperties()
  end operator
  
  property Font.fontData() as fbtt_FontData ptr
    return _fontData
  end property
  
  property Font.fontProps() as fbtt_FontProps ptr
    return @_fProps
  end property
  
  property Font.size() as long
    return( _size )
  end property
  
  property Font.size( value as long )
    if( value > 1 ) then
      _size = value
      setFontProperties()
    end if
  end property
  
  property Font.useBaseline() as boolean
    return( _useBaseline )
  end property
  
  property Font.useBaseline( value as boolean )
    _useBaseline = value
  end property
  
  property Font.baseline() as long
    return( _baseline )
  end property
  
  property Font.fontHeight() as long
    return( _height )
  end property
  
  static function Font.fromFile( fileName as string ) as Font
    var fd = fbtt_LoadFont( fileName )
    
    if( fbtt_GetLastError() ) then
      ? "ERROR: " & fbtt_GetLastError()
      return( Font() )
    end if
    
    return( Font( fd ) )
  end function
  
  static function Font.fromBuffer( buffer as any ptr, bytes as uinteger ) as Font
    var fd = fbtt_LoadFontFromBuffer( buffer, bytes )
    
    if( fbtt_GetLastError() ) then
      return( Font() )
    end if
    
    return( Font( fd ) )
  end function
  
  sub Font.setFontProperties()
    fbtt_GetFontProperties( _fontData, _size, _fProps )
    fbtt_GetFontBoundingBox( _fontData, _size, _fProps, @_bb )
    
    _baseline = _bb.y1
    _height = _bb.y1 - _bb.y0
  end sub
  
  function Font.measureChars( text as string, ch() as CharRegion) as long
    if( _size < 1 orElse len( text ) < 1 ) then
      return( 0 )
    end if
    
    dim as integer nChars = len( text )
    redim ch( 0 to nChars - 1 )
    
    dim as long height = _bb.y1 - _bb.y0
    
    dim as fbtt_GlyphProps gProps
    dim as long cx = 0, pcx = 0
    
    for i as long = 0 to nChars - 1
      dim as long char = text[ i ]
      
      ch( i ).x = cx
      ch( i ).height = height
      
      if( char < 33 ) then
        if( char = 32 ) then
          pcx = cx
          cx += size \ 4
          
          ch( i ).width = size \ 4
        end if
      else
        dim as long index1 = fbtt_GetGlyphIndex( _fontData, char )
        
        if( index1 <> FBTT_GLYPH_NOT_FOUND ) then
          dim as long index2 = iif( i < nChars - 1, fbtt_GetGlyphIndex( _fontData, text[ i + 1 ] ), 0 )
          index2 = iif( index2 = FBTT_GLYPH_NOT_FOUND, 0, index2 )
          
          if( fbtt_GetGlyphProperties( _fontData, _fProps, gProps, index1, index2 ) = 0 ) then
            pcx = cx
            cx += gProps.advanceWidth + gProps.kernAdvance
            
            ch( i ).width = cx - pcx
          endif
        endif
      endif
    next
    
    return( nChars )
  end function
  
  function Font.measureChars_exact( text as string, ch() as CharRegion ) as long
    if( _size < 1 orElse len( text ) < 1 ) then
      return( 0 )
    end if
    
    dim as integer nChars = len( text )
    redim ch( 0 to nChars - 1 )
    
    dim as long height = _bb.y1 - _bb.y0
    
    dim as fbtt_GlyphProps gProps
    dim as long cx = 0, cy = 0
    
    for i as long = 0 to nChars - 1
      dim as long char = text[ i ]
      
      if( char < 33 ) then
        if( char = 32 ) then
          ch( i ).x = cx
          ch( i ).y = 0
          ch( i ).height = height
          
          cx += size \ 4
          
          ch( i ).width = size \ 4
        end if
      else
        dim as long index1 = fbtt_GetGlyphIndex( _fontData, char )
        
        if( index1 <> FBTT_GLYPH_NOT_FOUND ) then
          dim as long index2 = iif( i < nChars - 1, fbtt_GetGlyphIndex( _fontData, text[ i + 1 ] ), 0 )
          index2 = iif( index2 = FBTT_GLYPH_NOT_FOUND, 0, index2 )
          
          if( fbtt_GetGlyphProperties( _fontData, _fProps, gProps, index1, index2 ) = 0 ) then
            ch( i ).x = cx + gProps.x0
            ch( i ).y = cy + gProps.y0 + _baseline
            ch( i ).width = gProps.w + gProps.x0
            ch( i ).height = gProps.h
            
            cx += gProps.advanceWidth + gProps.kernAdvance
          endif
        endif
      endif
    next
    
    return( nChars )
  end function
  
  function Font.measure( text as string ) as TextRegion
    if( _size < 1 orElse len( text ) < 1 ) then
      return( type<TextRegion>( 0 ) )
    end if
    
    dim as TextRegion result
    
    result.height = _bb.y1 - _bb.y0
    result.baseline = _bb.y1
    
    dim as fbtt_GlyphProps gProps
    dim as integer nChars = len( text )
    
    for i as long = 0 to nChars - 1
      dim as long char = text[ i ]
      
      if( char < 33 ) then
        if( char = 32 ) then
          result.width += size \ 4
        end if
      else
        dim as long index1 = fbtt_GetGlyphIndex( _fontData, char )
        
        if( index1 <> FBTT_GLYPH_NOT_FOUND ) then
          dim as long index2 = iif( i < nChars - 1, fbtt_GetGlyphIndex( _fontData, text[ i + 1 ] ), 0 )
          index2 = iif( index2 = FBTT_GLYPH_NOT_FOUND, 0, index2 )
          
          if( fbtt_GetGlyphProperties( _fontData, _fProps, gProps, index1, index2 ) = 0 ) then
            result.width += gProps.advanceWidth + gProps.kernAdvance
          endif
        endif
      endif
    next
    
    return( result )
  end function
  
  sub Font.render( x as long, y as long, text as string, clr as ulong, buff as any ptr = 0 )
    if( _size < 1 orElse len( text ) < 1 ) then return
    
    dim as fbtt_GlyphProps gProps
    dim as integer nChars = len( text )
    dim as long cx = x, cy = y
    
    if( buff = 0 ) then
      screenLock()
    end if
    
    for i as long = 0 to nChars - 1
      dim as long char = text[ i ]
      
      if( char < 33 ) then
        if( char = 32 ) then
          cx += size \ 4
        end if
      else
        dim as long index1 = fbtt_GetGlyphIndex( _fontData, char )
        
        if( index1 <> FBTT_GLYPH_NOT_FOUND ) then
          dim as long index2 = iif( i < nChars - 1, fbtt_GetGlyphIndex( _fontData, text[ i + 1 ] ), 0 )
          index2 = iif( index2 = FBTT_GLYPH_NOT_FOUND, 0, index2 )
          
          if( fbtt_GetGlyphProperties( _fontData, _fProps, gProps, index1, index2 ) = 0 ) then
            var alphaCh = fbtt_GetGlyphImageRaw( _fontData, _fProps, gProps, index1 )
            
            if( alphaCh ) then
              dim as long offset = iif( _useBaseline, 0, _baseline )
              
              renderGlyph_new( cx + gProps.x0, cy + gProps.y0 + offset, alphaCh, gProps, clr, buff )
            end if
            
            cx += gProps.advanceWidth + gProps.kernAdvance
          endif
        endif
      endif
    next
    
    if( buff = 0 ) then
      screenUnlock()
    end if
  end sub
  
  sub Font.render_clipped( r as ClipRegion, x as long, y as long, text as string, clr as ulong, buff as any ptr = 0 )
    if( _size < 1 orElse len( text ) < 1 ) then return
    
    dim as fbtt_GlyphProps gProps
    dim as integer nChars = len( text )
    dim as long cx = x, cy = y
    
    if( buff = 0 ) then
      screenLock()
    end if
    
    for i as long = 0 to nChars - 1
      dim as long char = text[ i ]
      
      if( char < 33 ) then
        if( char = 32 ) then
          cx += size \ 4
        end if
      else
        dim as long index1 = fbtt_GetGlyphIndex( _fontData, char )
        
        if( index1 <> FBTT_GLYPH_NOT_FOUND ) then
          dim as long index2 = iif( i < nChars - 1, fbtt_GetGlyphIndex( _fontData, text[ i + 1 ] ), 0 )
          index2 = iif( index2 = FBTT_GLYPH_NOT_FOUND, 0, index2 )
          
          if( fbtt_GetGlyphProperties( _fontData, _fProps, gProps, index1, index2 ) = 0 ) then
            var alphaCh = fbtt_GetGlyphImageRaw( _fontData, _fProps, gProps, index1 )
            
            if( alphaCh ) then
              dim as long offset = iif( _useBaseline, 0, _baseline )
              
              renderGlyph_clipped( r, cx + gProps.x0, cy + gProps.y0 + offset, alphaCh, gProps, clr, buff )
            end if
            
            cx += gProps.advanceWidth + gProps.kernAdvance
          endif
        endif
      endif
    next
    
    if( buff = 0 ) then
      screenUnlock()
    end if
  end sub
  
  /'
    New version: doesn't destroy destination buffer alpha information.
    Bound to be a bit slower than the previous version, but it gives correct results for
    blitting fonts on buffers.
  '/
  sub Font.renderGlyph_new( x as long, y as long, alphaChannel as ubyte ptr, _
    gProps as fbtt_GlyphProps, clr as ulong, buff as Fb.Image ptr = 0, opacity as ulong = 256 )
    
    dim as long offset = iif( _useBaseline, 0, _baseline )
    
    #define __min__( _a_, _b_ ) iif( _a_ < _b_, _a_, _b_ )
    #define __max__( _a_, _b_ ) iif( _a_ > _b_, _a_, _b_ )
    #define __R__( c ) ( culng( c ) shr 16 and 255 )
    #define __G__( c ) ( culng( c ) shr  8 and 255 )
    #define __B__( c ) ( culng( c )        and 255 )
    #define __A__( c ) ( culng( c ) shr 24         )  
    
    dim as ulong ptr dstp
    dim as long dstStride, dstWidth, dstHeight
    
    if( buff ) then
      '' Blitting to a buffer
      dstp = cptr( ulong ptr, cptr( ubyte ptr, buff ) + sizeof( Fb.Image ) )
      dstStride = buff->pitch \ sizeof( ulong )
      dstWidth = buff->width
      dstHeight = buff->height
    else
      '' Blitting to the screen
      dstp = cptr( ulong ptr, screenptr() )
      
      dim as long scW, scH
      screenInfo( scW, scH )
      
      dstStride = scW
      dstWidth = scW
      dstHeight = scH
    end if
    
    dim as ubyte ptr srcp = alphaChannel
    dim as long srcStride = gProps.w
    
    dim as integer _
      dstStartX = __max__( 0,  x ), dstStartY = __max__( 0,  y ), _
      srcStartX = __max__( 0, -x ), srcStartY = __max__( 0, -y ), _
      srcEndX = __min__( gProps.w - 1, ( ( dstWidth - 1 ) - ( x + gProps.w - 1 ) ) + gProps.w - 1 ), _
      srcEndY = __min__( gProps.h - 1, ( ( dstHeight - 1 ) - ( y + gProps.h - 1 ) ) + gProps.h - 1 )
    
    if( buff = 0 ) then
      screenLock()
    end if
    
    dim as long dstOffX = dstStartX - srcStartX
    dim as long dstOffY = dstStartY - srcStartY
    
    #define src_r __R__( srcc )
    #define src_g __G__( srcc )
    #define src_b __B__( srcc )
    #define src_a __A__( srcc )
    
    #define dst_r __R__( dstc )
    #define dst_g __G__( dstc )
    #define dst_b __B__( dstc )
    #define dst_a __A__( dstc )
    
    dim as long dstpx, srcpx
    dim as ulong dstc
    dim as ulong srcc
    
    for yy as integer = srcStartY to srcEndY
      for xx as integer = srcStartX to srcEndX
        dstpx = ( dstOffY + yy ) * dstStride + ( dstOffX + xx )
        srcpx = yy * srcStride + xx
        dstc = dstp[ dstpx ]
        srcc = rgba( __R__( clr ), __G__( clr ), __B__( clr ), srcp[ srcpx ] )
        
        dstp[ dstpx ] = rgba( _
          dst_r + ( opacity * ( ( dst_r + ( src_a * ( src_r - dst_r ) ) shr 8 ) - dst_r ) shr 8 ), _
          dst_g + ( opacity * ( ( dst_g + ( src_a * ( src_g - dst_g ) ) shr 8 ) - dst_g ) shr 8 ), _
          dst_b + ( opacity * ( ( dst_b + ( src_a * ( src_b - dst_b ) ) shr 8 ) - dst_b ) shr 8 ), _
          dst_a + ( opacity * ( ( src_a * ( 256 - dst_a ) ) shr 8 ) shr 8 ) )
      next
    next
    
    if( buff = 0 ) then
      screenUnlock()
    end if
    
    '' <OPT> Cache the alpha channel for the char index instead of releasing it every call
    deallocate( alphaChannel )
  end sub
  
  sub Font.renderGlyph_clipped( r as ClipRegion, x as long, y as long, alphaChannel as ubyte ptr, _
    gProps as fbtt_GlyphProps, clr as ulong, buff as Fb.Image ptr = 0, opacity as ulong = 256 )
    
    dim as long offset = iif( _useBaseline, 0, _baseline )
    
    #define __min__( _a_, _b_ ) iif( _a_ < _b_, _a_, _b_ )
    #define __max__( _a_, _b_ ) iif( _a_ > _b_, _a_, _b_ )
    #define __R__( c ) ( culng( c ) shr 16 and 255 )
    #define __G__( c ) ( culng( c ) shr  8 and 255 )
    #define __B__( c ) ( culng( c )        and 255 )
    #define __A__( c ) ( culng( c ) shr 24         )  
    
    dim as ulong ptr dstp
    dim as long dstStride, dstWidth, dstHeight
    
    if( buff ) then
      '' Blitting to a buffer
      dstp = cptr( ulong ptr, cptr( ubyte ptr, buff ) + sizeof( Fb.Image ) )
      dstStride = buff->pitch \ sizeof( ulong )
      dstWidth = buff->width
      dstHeight = buff->height
    else
      '' Blitting to the screen
      dstp = cptr( ulong ptr, screenptr() )
      
      dim as long scW, scH
      screenInfo( scW, scH )
      
      dstStride = scW
      dstWidth = scW
      dstHeight = scH
    end if
    
    '' Clip coordinates
    if( r.x1 > r.x2 ) then swap r.x1, r.x2
    if( r.y1 > r.y2 ) then swap r.y1, r.y2
    
    r.x1 = __max__( 0, r.x1 )
    r.y1 = __max__( 0, r.y1 )
    r.x2 = __min__( r.x2, dstWidth )
    r.y2 = __min__( r.y2, dstHeight )
    
    dim as integer rW = __min__( dstWidth, r.x2 - r.x1 )
    dim as integer rH = __min__( dstHeight, r.y2 - r.y1 )
    
    dim as integer _
      dstStartX = __max__( r.x1,  x ), dstStartY = __max__( r.y1,  y ), _
      srcStartX = __max__( -r.x1, -x ) + r.x1, srcStartY = __max__( -r.y1, -y ) + r.y1
    
    dim as integer _
      srcEndX = __min__( gProps.w - 1, ( r.x1 + ( rW - 1 ) - ( x + gProps.w - 1 ) ) + gProps.w - 1 ), _
      srcEndY = __min__( gProps.h - 1, ( r.y1 + ( rH - 1 ) - ( y + gProps.h - 1 ) ) + gProps.h - 1 )
    
    if( buff = 0 ) then
      screenLock()
    end if
    
    dim as ubyte ptr srcp = alphaChannel
    dim as long srcStride = gProps.w
    dim as long dstOffX = dstStartX - srcStartX
    dim as long dstOffY = dstStartY - srcStartY
    
    #define src_r __R__( srcc )
    #define src_g __G__( srcc )
    #define src_b __B__( srcc )
    #define src_a __A__( srcc )
    
    #define dst_r __R__( dstc )
    #define dst_g __G__( dstc )
    #define dst_b __B__( dstc )
    #define dst_a __A__( dstc )
    
    dim as long dstpx, srcpx
    dim as ulong dstc
    dim as ulong srcc
    
    for yy as integer = srcStartY to srcEndY
      for xx as integer = srcStartX to srcEndX
        dstpx = ( dstOffY + yy ) * dstStride + ( dstOffX + xx )
        srcpx = yy * srcStride + xx
        dstc = dstp[ dstpx ]
        srcc = rgba( __R__( clr ), __G__( clr ), __B__( clr ), srcp[ srcpx ] )
        
        dstp[ dstpx ] = rgba( _
          dst_r + ( opacity * ( ( dst_r + ( src_a * ( src_r - dst_r ) ) shr 8 ) - dst_r ) shr 8 ), _
          dst_g + ( opacity * ( ( dst_g + ( src_a * ( src_g - dst_g ) ) shr 8 ) - dst_g ) shr 8 ), _
          dst_b + ( opacity * ( ( dst_b + ( src_a * ( src_b - dst_b ) ) shr 8 ) - dst_b ) shr 8 ), _
          dst_a + ( opacity * ( ( src_a * ( 256 - dst_a ) ) shr 8 ) shr 8 ) )
      next
    next
    
    if( buff = 0 ) then
      screenUnlock()
    end if
    
    '' <OPT> Cache the alpha channel for the char index instead of releasing it every call
    deallocate( alphaChannel )
  end sub
  
  function Font.getCharBitmap( ch as long, byref w as long, byref h as long ) as any ptr
    dim as fbtt_GlyphProps gProps
    
    dim as long index1 = fbtt_GetGlyphIndex( _fontData, ch )
    
    if( fbtt_GetGlyphProperties( _fontData, _fProps, gProps, index1, 0 ) = 0 ) then
      w = gProps.w : h = gProps.h
      
      return( fbtt_GetGlyphImageRaw( _fontData, _fProps, gProps, index1 ) )
    end if
    
    return( 0 )
  end function
end namespace

#endif
