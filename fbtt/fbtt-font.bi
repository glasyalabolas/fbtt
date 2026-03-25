#ifndef __FBTRUETYPE_FONT__
#define __FBTRUETYPE_FONT__

#include once "fb-truetype.bi"
#include once "fbtt-commons.bi"
#include once "dh-hash-table.bi"

#ifndef NULL
  #define NULL 0
#endif

'' Clip region, in pixels
type ttf_clip_region
  as long x1, y1, x2, y2
end type

'' Text region, in pixels, with text baseline
type ttf_text_region
  as long width, height
  as long baseline
end type

'' Char region, in pixels
type ttf_char_region
  as long x, y, width, height
end type

'' True Type/OpenType font data. Treated as an opaque token
type ttf_font
  as fbtt_FontData ptr _fontData  '' Font data
  as DhHashTable _glyphs          '' Glyph cache (size, glyphIndex)
end type

'' Retrieve font properties
private sub ttf_get_font_properties(f as ttf_font ptr, size as long, byref fProps as fbtt_FontProps, byref bb as fbtt_FontBoundingBox)
  fbtt_GetFontProperties(f->_fontData, size, fProps)
  fbtt_GetFontBoundingBox(f->_fontData, size, fProps, @bb)
end sub

'' Destroys the font. Also destroys cached glyph data
sub ttf_font_destroy(f as ttf_font ptr)
  fbtt_FreeFont(f->_fontData)
  
  dh_destroy(f->_glyphs, cptr(sub(as any ptr), @deallocate))
  delete(f)
  f = NULL
end sub

'' Loads font data from a file (TTF/OTF supported)
function ttf_font_fromFile(fileName as string) as ttf_font ptr
  var fd = fbtt_LoadFont(fileName)
  
  if fbtt_GetLastError() then
    return NULL
  end if
  
  var newFont = new ttf_font
  
  newFont->_fontData = fd
  newFont->_glyphs = dh_create(256)
  
  return newFont
end function

'' Loads font data from a byte buffer
function ttf_font_fromBuffer(buffer as any ptr, bytes as uinteger) as ttf_font ptr
  var fd = fbtt_LoadFontFromBuffer(buffer, bytes)
  
  if fbtt_GetLastError() then
    return NULL
  end if
  
  var newFont = new ttf_font
  
  newFont->_fontData = fd
  newFont->_glyphs = dh_create(256)
  
  return newFont
end function

'' Retrieves the bounding boxes of the text, for the specified font.
'' The height is the blackbox height (ie ascent + descent) for each glyph.
function ttf_font_measureChars(f as ttf_font ptr, text as string, size as long, ch() as ttf_char_region) as long
  if size < 1 orElse len(text) < 1 then
    return 0
  end if
  
  dim as integer nChars = len(text)
  redim ch(0 to nChars - 1)
  
  dim as fbtt_FontProps fProps
  dim as fbtt_FontBoundingBox bb
  
  ttf_get_font_properties(f, size, fProps, bb)

  dim as long height = bb.y1 - bb.y0
  
  dim as fbtt_GlyphProps gProps
  dim as long cx = 0, pcx = 0
  
  for i as long = 0 to nChars - 1
    dim as long char = text[i]
    
    ch(i).x = cx
    ch(i).height = height
    
    if char >= 32 then
      dim as long index1 = fbtt_GetGlyphIndex(f->_fontData, char)
      
      if index1 <> FBTT_GLYPH_NOT_FOUND then
        dim as long index2 = iif(i < nChars - 1, fbtt_GetGlyphIndex(f->_fontData, text[i + 1]), 0)
        index2 = iif(index2 = FBTT_GLYPH_NOT_FOUND, 0, index2)
        
        if fbtt_GetGlyphProperties(f->_fontData, fProps, gProps, index1, index2) = 0 then
          pcx = cx
          cx += gProps.advanceWidth + gProps.kernAdvance
          
          ch(i).width = cx - pcx
        endif
      endif
    endif
  next
  
  return nChars
end function

function ttf_font_measureChars_unicode(f as ttf_font ptr, text as wstring, size as long, ch() as ttf_char_region) as long
  if size < 1 orElse len(text) < 1 then
    return 0
  end if
  
  dim as integer nChars = len(text)
  redim ch(0 to nChars - 1)
  
  dim as fbtt_FontProps fProps
  dim as fbtt_FontBoundingBox bb
  
  ttf_get_font_properties(f, size, fProps, bb)

  dim as long height = bb.y1 - bb.y0
  
  dim as fbtt_GlyphProps gProps
  dim as long cx = 0, pcx = 0
  
  for i as long = 0 to nChars - 1
    dim as long char = text[i]
    
    ch(i).x = cx
    ch(i).height = height
    
    if char >= 32 then
      dim as long index1 = fbtt_GetGlyphIndex(f->_fontData, char)
      
      if index1 <> FBTT_GLYPH_NOT_FOUND then
        dim as long index2 = iif(i < nChars - 1, fbtt_GetGlyphIndex(f->_fontData, text[i + 1]), 0)
        index2 = iif(index2 = FBTT_GLYPH_NOT_FOUND, 0, index2)
        
        if fbtt_GetGlyphProperties(f->_fontData, fProps, gProps, index1, index2) = 0 then
          pcx = cx
          cx += gProps.advanceWidth + gProps.kernAdvance
          
          ch(i).width = cx - pcx
        endif
      endif
    endif
  next
  
  return nChars
end function

'' Retrieves the exact bounding boxes of the text, for the specified font.
'' Exact means the bounding box in pixels, not the blackbox height.
function ttf_font_measureChars_exact(f as ttf_font ptr, text as string, size as long, ch() as ttf_char_region) as long
  if size < 1 orElse len(text) < 1 then
    return 0
  end if
  
  dim as integer nChars = len(text)
  redim ch(0 to nChars - 1)
  
  dim as fbtt_FontProps fProps
  dim as fbtt_FontBoundingBox bb

  ttf_get_font_properties(f, size, fProps, bb)
  
  dim as long height = bb.y1 - bb.y0
  
  dim as fbtt_GlyphProps gProps
  dim as long cx = 0, cy = 0

  for i as long = 0 to nChars - 1
    dim as long char = text[i]
    
    if char >= 32 then
      dim as long index1 = fbtt_GetGlyphIndex(f->_fontData, char)
      
      if index1 <> FBTT_GLYPH_NOT_FOUND then
        dim as long index2 = iif(i < nChars - 1, fbtt_GetGlyphIndex(f->_fontData, text[i + 1]), 0)
        index2 = iif(index2 = FBTT_GLYPH_NOT_FOUND, 0, index2)
        
        if fbtt_GetGlyphProperties(f->_fontData, fProps, gProps, index1, index2) = 0 then
          ch(i).x = cx + gProps.x0
          ch(i).y = cy + gProps.y0 + bb.y1 '' bb.y1 = baseline
          ch(i).width = gProps.w + gProps.x0
          ch(i).height = gProps.h
          
          cx += gProps.advanceWidth + gProps.kernAdvance
        endif
      endif
    endif
  next
  
  return nChars
end function

function ttf_font_measureChars_exact_unicode(f as ttf_font ptr, text as wstring, size as long, ch() as ttf_char_region) as long
  if size < 1 orElse len(text) < 1 then
    return 0
  end if
  
  dim as integer nChars = len(text)
  redim ch(0 to nChars - 1)
  
  dim as fbtt_FontProps fProps
  dim as fbtt_FontBoundingBox bb

  ttf_get_font_properties(f, size, fProps, bb)
  
  dim as long height = bb.y1 - bb.y0
  
  dim as fbtt_GlyphProps gProps
  dim as long cx = 0, cy = 0

  for i as long = 0 to nChars - 1
    dim as long char = text[i]
    
    if char >= 32 then
      dim as long index1 = fbtt_GetGlyphIndex(f->_fontData, char)
      
      if index1 <> FBTT_GLYPH_NOT_FOUND then
        dim as long index2 = iif(i < nChars - 1, fbtt_GetGlyphIndex(f->_fontData, text[i + 1]), 0)
        index2 = iif(index2 = FBTT_GLYPH_NOT_FOUND, 0, index2)
        
        if fbtt_GetGlyphProperties(f->_fontData, fProps, gProps, index1, index2) = 0 then
          ch(i).x = cx + gProps.x0
          ch(i).y = cy + gProps.y0 + bb.y1 '' bb.y1 = baseline
          ch(i).width = gProps.w + gProps.x0
          ch(i).height = gProps.h
          
          cx += gProps.advanceWidth + gProps.kernAdvance
        endif
      endif
    endif
  next
  
  return nChars
end function

'' Measures the rectangle of the text for the specified font. Also retrieves baseline.
function ttf_font_measure(f as ttf_font ptr, text as string, size as long) as ttf_text_region
  if size < 1 orElse len(text) < 1 then
    return type<ttf_text_region>(0)
  end if
    
  dim as ttf_text_region result
  
  dim as fbtt_FontBoundingBox bb
  dim as fbtt_FontProps fProps

  ttf_get_font_properties(f, size, fProps, bb)
  
  result.height = bb.y1 - bb.y0
  result.baseline = bb.y1
  
  dim as fbtt_GlyphProps gProps
  dim as integer nChars = len(text)
  
  for i as long = 0 to nChars - 1
    dim as long char = text[i]
    
    if char >= 32 then
      dim as long index1 = fbtt_GetGlyphIndex(f->_fontData, char)
      
      if index1 <> FBTT_GLYPH_NOT_FOUND then
        dim as long index2 = iif(i < nChars - 1, fbtt_GetGlyphIndex(f->_fontData, text[i + 1]), 0)
        index2 = iif(index2 = FBTT_GLYPH_NOT_FOUND, 0, index2)
        
        if fbtt_GetGlyphProperties(f->_fontData, fProps, gProps, index1, index2) = 0 then
          result.width += gProps.advanceWidth + gProps.kernAdvance
        endif
      endif
    endif
  next
  
  return result
end function

function ttf_font_measure_unicode(f as ttf_font ptr, text as wstring, size as long) as ttf_text_region
  if size < 1 orElse len(text) < 1 then
    return type<ttf_text_region>(0)
  end if
    
  dim as ttf_text_region result
  
  dim as fbtt_FontBoundingBox bb
  dim as fbtt_FontProps fProps

  ttf_get_font_properties(f, size, fProps, bb)
  
  result.height = bb.y1 - bb.y0
  result.baseline = bb.y1
  
  dim as fbtt_GlyphProps gProps
  dim as integer nChars = len(text)
  
  for i as long = 0 to nChars - 1
    dim as long char = text[i]
    
    if char >= 32 then
      dim as long index1 = fbtt_GetGlyphIndex(f->_fontData, char)
      
      if index1 <> FBTT_GLYPH_NOT_FOUND then
        dim as long index2 = iif(i < nChars - 1, fbtt_GetGlyphIndex(f->_fontData, text[i + 1]), 0)
        index2 = iif(index2 = FBTT_GLYPH_NOT_FOUND, 0, index2)
        
        if fbtt_GetGlyphProperties(f->_fontData, fProps, gProps, index1, index2) = 0 then
          result.width += gProps.advanceWidth + gProps.kernAdvance
        endif
      endif
    endif
  next
  
  return result
end function

/'
  Clips a glyph to the specified region and blits it to the destination buffer.
  opacity is 0..255. Full opacity = 255.
  Assumes the screen is locked when rendering to the framebuffer.
'/
private sub ttf_font_renderGlyph_clipped( _
  r as ttf_clip_region, x as long, y as long, _
  alphaChannel as ubyte ptr, gProps as fbtt_GlyphProps, _
  clr as ulong, buff as Fb.Image ptr = 0, opacity as ulong = 255, offset as long = 0)
    
  #define __min__(_a_, _b_) iif((_a_) < (_b_), _a_, _b_)
  #define __max__(_a_, _b_) iif((_a_) > (_b_), _a_, _b_)
  
  dim as ulong ptr dstp
  dim as long dstStride, dstWidth, dstHeight
  
  if buff then
    '' Blitting to a buffer
    dstp = cptr(ulong ptr, cptr(ubyte ptr, buff) + sizeof(Fb.Image))
    dstStride = buff->pitch \ sizeof(ulong)
    dstWidth = buff->width
    dstHeight = buff->height
  else
    '' Blitting to the screen
    dstp = cptr(ulong ptr, screenptr())
    
    dim as long scW, scH
    screenInfo(scW, scH)
    
    dstStride = scW
    dstWidth = scW
    dstHeight = scH
  end if
  
  '' Clip coordinates
  if r.x1 > r.x2 then swap r.x1, r.x2
  if r.y1 > r.y2 then swap r.y1, r.y2
  
  r.x1 = __max__(0, r.x1)
  r.y1 = __max__(0, r.y1)
  r.x2 = __min__(r.x2, dstWidth)
  r.y2 = __min__(r.y2, dstHeight)
  
  dim as integer rW = __min__(dstWidth, r.x2 - r.x1)
  dim as integer rH = __min__(dstHeight, r.y2 - r.y1)
  
  dim as integer _
    dstStartX = __max__( r.x1,  x),        dstStartY = __max__( r.y1,  y), _
    srcStartX = __max__(-r.x1, -x) + r.x1, srcStartY = __max__(-r.y1, -y) + r.y1
  
  dim as integer _
    srcEndX = __min__(gProps.w - 1, (r.x1 + (rW - 1) - (x + gProps.w - 1)) + gProps.w - 1), _
    srcEndY = __min__(gProps.h - 1, (r.y1 + (rH - 1) - (y + gProps.h - 1)) + gProps.h - 1)
  
  dim as ubyte ptr srcp = alphaChannel
  dim as long srcStride = gProps.w
  dim as long dstOffX = dstStartX - srcStartX
  dim as long dstOffY = dstStartY - srcStartY

  '' Sree's trick applied once per call: opacity 0..255 -> scale 1..256
  dim as ulong opScale = opacity + 1

  '' Strip alpha lane from clr so it never bleeds into the packed ag lane
  dim as ulong clrRGB = clr and &h00FFFFFF

  for yy as integer = srcStartY to srcEndY
    for xx as integer = srcStartX to srcEndX
      dim as long dstpx = (dstOffY + yy) * dstStride + (dstOffX + xx)
      dim as long srcpx = yy * srcStride + xx

      dim as ulong dst32 = dstp[dstpx]
      dim as ulong srcA  = srcp[srcpx]   '' glyph grayscale alpha, 0..255

      '' Stage 1: lerp dst RGB toward clrRGB using glyph alpha (srcA).
      '' Sree's trick: srcA 0..255 -> s1 1..256 for exact full-coverage at 255.
      dim as ulong s1 = srcA + 1

      dim as ulong dstrb1 = dst32  and &h00FF00FF
      dim as ulong dstg1  = dst32  and &h0000FF00
      dim as ulong srcrb1 = clrRGB and &h00FF00FF
      dim as ulong srcg1  = clrRGB and &h0000FF00

      dim as ulong rb1 = ((((srcrb1 - dstrb1) * s1) shr 8) + dstrb1) and &h00FF00FF
      dim as ulong g1  = ((((srcg1  - dstg1)  * s1) shr 8) + dstg1)  and &h0000FF00

      dim as ulong mid32 = rb1 or g1   '' stage-1 RGB result; alpha lane intentionally 0

      '' Stage 2: lerp dst RGB toward mid32 using opacity.
      dim as ulong dstrb2 = dst32  and &h00FF00FF
      dim as ulong dstg2  = dst32  and &h0000FF00
      dim as ulong midrb2 = mid32  and &h00FF00FF
      dim as ulong midg2  = mid32  and &h0000FF00

      dim as ulong rb2 = ((((midrb2 - dstrb2) * opScale) shr 8) + dstrb2) and &h00FF00FF
      dim as ulong g2  = ((((midg2  - dstg2)  * opScale) shr 8) + dstg2)  and &h0000FF00

      '' Alpha: coverage accumulation — preserves dst alpha, not lerped
      dim as ulong dstA = dst32 shr 24
      dim as ulong outA = dstA + ((opacity * ((srcA * (256 - dstA)) shr 8)) shr 8)

      dstp[dstpx] = rb2 or g2 or (outA shl 24)
    next
  next

  #undef __min__
  #undef __max__
end sub

/'
  Blits a glyph to the specified buffer (unclipped).
  Delegates to ttf_font_renderGlyph_clipped with a clip region covering the full destination.

  opacity is 0..255. Full opacity = 255.
  Assumes the screen is locked when rendering to the framebuffer.
'/
private sub ttf_font_renderGlyph_new( _
  x as long, y as long, alphaChannel as ubyte ptr, _
  gProps as fbtt_GlyphProps, clr as ulong, _
  buff as Fb.Image ptr = 0, opacity as ulong = 255, offset as long = 0)

  dim as long dstWidth, dstHeight

  if buff then
    dstWidth  = buff->width
    dstHeight = buff->height
  else
    screenInfo(dstWidth, dstHeight)
  end if

  ttf_font_renderGlyph_clipped(type<ttf_clip_region>(0, 0, dstWidth, dstHeight), _
    x, y, alphaChannel, gProps, clr, buff, opacity, offset)
end sub

'' Renders the font clipped to the specified region
'' Assumes the screen is locked when rendering to the framebuffer
sub ttf_font_render overload( _
  f as ttf_font ptr, r as ttf_clip_region, x as long, y as long, _
  text as string, size as long, clr as ulong, buff as any ptr = 0, useBaseline as boolean = false)
  
  if size < 1 orElse len(text) < 1 then return
  
  dim as fbtt_GlyphProps gProps
  dim as integer nChars = len(text)
  dim as long cx = x, cy = y
  
  dim as fbtt_FontProps fProps
  dim as fbtt_FontBoundingBox bb

  ttf_get_font_properties(f, size, fProps, bb)
  
  for i as integer = 0 to nChars - 1
    dim as long char = text[i]
    
    if char >= 32 then
      dim as long index1 = fbtt_GetGlyphIndex(f->_fontData, char)
      
      if index1 <> FBTT_GLYPH_NOT_FOUND then
        dim as long index2 = iif(i < nChars - 1, fbtt_GetGlyphIndex(f->_fontData, text[i + 1]), 0)
        index2 = iif(index2 = FBTT_GLYPH_NOT_FOUND, 0, index2)
        
        if fbtt_GetGlyphProperties(f->_fontData, fProps, gProps, index1, index2) = 0 then
          if char > 32 then
            dim alphaCh as ubyte ptr = dh_find(f->_glyphs, size, index1)
            
            if alphaCh = 0 then
              alphaCh = fbtt_GetGlyphImageRaw(f->_fontData, fProps, gProps, index1)
              dh_add(f->_glyphs, size, index1, alphaCh)
            end if
            
            if alphaCh then
              dim as long offset = iif(useBaseline, 0, bb.y1)
              ttf_font_renderGlyph_clipped(r, cx + gProps.x0, cy + gProps.y0 + offset, alphaCh, gProps, clr, buff, culng(clr) shr 24, offset)
            end if
          end if

          cx += gProps.advanceWidth + gProps.kernAdvance
        endif
      endif
    endif
  next
end sub

'' Renders text (unclipped) — delegates to ttf_font_render_clipped with a full-coverage region
'' Assumes the screen is locked when rendering to the framebuffer
sub ttf_font_render( _
  f as ttf_font ptr, x as long, y as long, _
  text as string, size as long, clr as ulong, buff as any ptr = 0, useBaseline as boolean = false)

  dim as long dstWidth, dstHeight

  if buff then
    dim as Fb.Image ptr img = buff
    dstWidth  = img->width
    dstHeight = img->height
  else
    screenInfo(dstWidth, dstHeight)
  end if

  ttf_font_render(f, type<ttf_clip_region>(0, 0, dstWidth, dstHeight), _
    x, y, text, size, clr, buff, useBaseline)
end sub

sub ttf_font_render_unicode overload( _
  f as ttf_font ptr, r as ttf_clip_region, x as long, y as long, _
  text as wstring, size as long, clr as ulong, buff as any ptr = 0, useBaseline as boolean = false)
  
  if size < 1 orElse len(text) < 1 then return
  
  dim as fbtt_GlyphProps gProps
  dim as integer nChars = len(text)
  dim as long cx = x, cy = y
  
  dim as fbtt_FontProps fProps
  dim as fbtt_FontBoundingBox bb

  ttf_get_font_properties(f, size, fProps, bb)
  
  for i as integer = 0 to nChars - 1
    dim as long char = text[i]
    
    if char >= 32 then
      dim as long index1 = fbtt_GetGlyphIndex(f->_fontData, char)
      
      if index1 <> FBTT_GLYPH_NOT_FOUND then
        dim as long index2 = iif(i < nChars - 1, fbtt_GetGlyphIndex(f->_fontData, text[i + 1]), 0)
        index2 = iif(index2 = FBTT_GLYPH_NOT_FOUND, 0, index2)
        
        if fbtt_GetGlyphProperties(f->_fontData, fProps, gProps, index1, index2) = 0 then
          if char > 32 then
            dim alphaCh as ubyte ptr = dh_find(f->_glyphs, size, index1)
            
            if alphaCh = 0 then
              alphaCh = fbtt_GetGlyphImageRaw(f->_fontData, fProps, gProps, index1)
              dh_add(f->_glyphs, size, index1, alphaCh)
            end if
            
            if alphaCh then
              dim as long offset = iif(useBaseline, 0, bb.y1)
              ttf_font_renderGlyph_clipped(r, cx + gProps.x0, cy + gProps.y0 + offset, alphaCh, gProps, clr, buff, culng(clr) shr 24, offset)
            end if
          end if

          cx += gProps.advanceWidth + gProps.kernAdvance
        endif
      endif
    endif
  next
end sub

sub ttf_font_render_unicode( _
  f as ttf_font ptr, x as long, y as long, _
  text as wstring, size as long, clr as ulong, buff as any ptr = 0, useBaseline as boolean = false)

  dim as long dstWidth, dstHeight

  if buff then
    dim as Fb.Image ptr img = buff
    dstWidth  = img->width
    dstHeight = img->height
  else
    screenInfo(dstWidth, dstHeight)
  end if

  ttf_font_render_unicode(f, type<ttf_clip_region>(0, 0, dstWidth, dstHeight), _
    x, y, text, size, clr, buff, useBaseline)
end sub

#endif
