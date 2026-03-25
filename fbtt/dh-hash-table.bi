#pragma once

#ifndef NULL
  #define NULL 0
#endif

'' Slot states
const as long DH_EMPTY     = 0
const as long DH_OCCUPIED  = 1
const as long DH_TOMBSTONE = 2

type DhHashEntry
  as ulong h1       '' Primary key (raw, as supplied by caller)
  as ulong h2       '' Secondary key (raw, as supplied by caller)
  as any ptr value  '' Associated data
  as long state     '' DH_EMPTY / DH_OCCUPIED / DH_TOMBSTONE
end type

'' Dynamic double-hashing hash table.
'' Size is always a power of 2; grows by _cap slots on each resize.
'' h1/h2 are internally mixed before probing — caller need not pre-hash.
'' Probing: slot = (ph1 + i * (ph2 or 1)) and (size - 1)
type DhHashTable
  as DhHashEntry ptr _bucket
  as long size    '' Current total slot count (power of 2)
  as long _count  '' Number of occupied slots
  as long _cap    '' Growth increment (initial capacity, rounded to next pow2)
end type

'' Internally mix raw h1/h2 into probe values ph1_ and ph2_ using two
'' independent Murmur3-style passes. Raw keys are preserved in entries
'' for equality checks; only the mixed values drive slot selection.
#macro DH_MIX(h1_, h2_, ph1_, ph2_)
  scope
    dim as ulong _a = cast(ulong, h1_) xor (cast(ulong, h2_) * 2654435761ul)
    _a xor= _a shr 16
    _a *= &h45d9f3b
    _a xor= _a shr 16
    ph1_ = _a

    dim as ulong _b = cast(ulong, h2_) xor (cast(ulong, h1_) * 2246822519ul)
    _b xor= _b shr 16
    _b *= &hb55a4f09
    _b xor= _b shr 16
    ph2_ = _b
  end scope
#endmacro

'' Round n up to the next power of 2 (minimum 1)
private function dh_next_pow2(n as long) as long
  if n <= 1 then return 1

  dim as long p = 1

  do while p < n
    p shl= 1
  loop

  return p
end function

'' Create a hash table with the given initial capacity (rounded to next pow2)
function dh_create(capacity as long) as DhHashTable
  dim as DhHashTable ht

  ht._cap    = dh_next_pow2(iif(capacity < 1, 1, capacity))
  ht.size    = ht._cap
  ht._count  = 0
  ht._bucket = callocate(ht.size, sizeof(DhHashEntry))

  return ht
end function

'' Destroy the hash table, optionally calling disposeFunc on each value
sub dh_destroy(ht as DhHashTable, disposeFunc as sub(as any ptr) = 0)
  if disposeFunc then
    for i as long = 0 to ht.size - 1
      if ht._bucket[i].state = DH_OCCUPIED andAlso ht._bucket[i].value <> NULL then
        disposeFunc(ht._bucket[i].value)
      end if
    next
  end if

  deallocate(ht._bucket)

  ht._bucket = NULL
  ht._count  = 0
  ht.size    = 0
end sub

'' Internal: probe for a slot matching (h1, h2), or the first tombstone/empty
'' Returns the slot index; sets outFound = true if key matched
private function dh_probe(ht as DhHashTable, h1 as ulong, h2 as ulong, byref outFound as boolean) as long
  dim as ulong ph1_, ph2_
  DH_MIX(h1, h2, ph1_, ph2_)

  dim as ulong stride_ = ph2_ or 1
  dim as long mask     = ht.size - 1
  dim as long tomb_    = -1

  for i as long = 0 to ht.size - 1
    dim as long slot = cast(long, (ph1_ + cast(ulong, i) * stride_) and mask)

    select case as const ht._bucket[slot].state
      case DH_EMPTY
        outFound = false
        return iif(tomb_ <> -1, tomb_, slot)
      case DH_TOMBSTONE
        if tomb_ = -1 then tomb_ = slot
      case DH_OCCUPIED
        if ht._bucket[slot].h1 = h1 andAlso ht._bucket[slot].h2 = h2 then
          outFound = true
          return slot
        end if
    end select
  next

  outFound = false
  return tomb_
end function

'' Internal: rehash all occupied entries into a freshly allocated bucket array
private sub dh_rehash(ht as DhHashTable)
  dim as long newSize       = ht.size + ht._cap
  dim as DhHashEntry ptr nb = callocate(newSize, sizeof(DhHashEntry))
  dim as long mask          = newSize - 1

  for i as long = 0 to ht.size - 1
    if ht._bucket[i].state = DH_OCCUPIED then
      dim as ulong ph1_, ph2_
      DH_MIX(ht._bucket[i].h1, ht._bucket[i].h2, ph1_, ph2_)

      dim as ulong stride_ = ph2_ or 1

      for j as long = 0 to newSize - 1
        dim as long slot = cast(long, (ph1_ + cast(ulong, j) * stride_) and mask)

        if nb[slot].state = DH_EMPTY then
          nb[slot] = ht._bucket[i]
          exit for
        end if
      next
    end if
  next

  deallocate(ht._bucket)

  ht._bucket = nb
  ht.size    = newSize
end sub

'' Find an entry by (h1, h2); returns its value or NULL if not found
function dh_find(ht as DhHashTable, h1 as ulong, h2 as ulong) as any ptr
  dim as ulong ph1_, ph2_
  DH_MIX(h1, h2, ph1_, ph2_)

  dim as ulong stride_ = ph2_ or 1
  dim as long mask     = ht.size - 1

  for i as long = 0 to ht.size - 1
    dim as long slot = cast(long, (ph1_ + cast(ulong, i) * stride_) and mask)

    select case as const ht._bucket[slot].state
      case DH_EMPTY
        return NULL
      case DH_OCCUPIED
        if ht._bucket[slot].h1 = h1 andAlso ht._bucket[slot].h2 = h2 then
          return ht._bucket[slot].value
        end if
    end select
  next

  return NULL
end function

'' Add an entry; returns false if key already exists
'' Resizes the table first if no empty or tombstone slot is available
function dh_add(ht as DhHashTable, h1 as ulong, h2 as ulong, value as any ptr) as boolean
  if ht._count = ht.size then
    dh_rehash(ht)
  end if

  dim as boolean found_
  dim as long slot = dh_probe(ht, h1, h2, found_)

  if found_ then return false

  with ht._bucket[slot]
    .h1    = h1
    .h2    = h2
    .value = value
    .state = DH_OCCUPIED
  end with

  ht._count += 1

  return true
end function

'' Remove an entry by (h1, h2); returns its value or NULL if not found
function dh_remove(ht as DhHashTable, h1 as ulong, h2 as ulong) as any ptr
  dim as ulong ph1_, ph2_
  DH_MIX(h1, h2, ph1_, ph2_)

  dim as ulong stride_ = ph2_ or 1
  dim as long mask     = ht.size - 1

  for i as long = 0 to ht.size - 1
    dim as long slot = cast(long, (ph1_ + cast(ulong, i) * stride_) and mask)

    select case as const ht._bucket[slot].state
      case DH_EMPTY
        return NULL
      case DH_OCCUPIED
        if ht._bucket[slot].h1 = h1 andAlso ht._bucket[slot].h2 = h2 then
          dim as any ptr result_ = ht._bucket[slot].value

          ht._bucket[slot].state = DH_TOMBSTONE
          ht._bucket[slot].value = NULL
          ht._count -= 1

          return result_
        end if
    end select
  next

  return NULL
end function
