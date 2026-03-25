#ifndef __FBTRUETYPE_COMMONS__
#define __FBTRUETYPE_COMMONS__

#include once "file.bi"

function loadBinaryFile(aPath as const string, byref bytes as uinteger) as any ptr
  dim as ubyte ptr content
  
  if fileExists(aPath) then
    dim as long fileHandle = freeFile()
    
    open aPath for binary access read as fileHandle
    
    '' Resize buffer to fit content
    bytes = lof(fileHandle)
    content = allocate(bytes)
    
    '' And get it all at once
    get #fileHandle, , *content, bytes
    
    close(fileHandle)
  end if
  
  return content
end function

#endif
