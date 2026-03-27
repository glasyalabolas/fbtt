#include once "fbgfx.bi"
#include once "fbtt/fbtt-font.bi"

const as single _
  C_PI = 4.0f * atn(1.0f), _
  C_DEGTORAD = C_PI / 180.0f, _
  C_RADTODEG = 180.0f / C_PI

#define rad(_a_) ((_a_) * C_DEGTORAD)
#define deg(_a_) ((_a_) * C_RADTODEG)

const as long SCR_W       = 1280
const as long SCR_H       = 700

#ifdef setDPIAwareness
  setDPIAwareness()
#endif

screenRes(SCR_W, SCR_H, 32, , Fb.GFX_ALPHA_PRIMITIVES)
color rgb(0, 0, 0), rgb(255, 255, 255)
cls()

var f = ttf_font_fromFile("fonts/ReadexPro-Regular.ttf")
dim as string text = "Rotated text!"

dim as long mx, my
dim as long n = 5
dim as single r = 0, angleSlice = 360.0 / n

do
  getMouse(mx, my)
  
  screenLock()
    cls()
    
    for i as integer = 0 to n - 1
      dim as single px = r * cos(i * angleSlice), py = r * sin(i * angleSlice)
      
      ttf_font_render_rotated(f, mx + px, my + py, text, 48, rgb(0, 0, 0), rad(i * angleSlice))
    next
  screenUnlock()
  
  sleep(1, 1)
loop until len(inkey())

ttf_font_destroy(f)
