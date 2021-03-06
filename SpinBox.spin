'' ===========================================================================
''  VGA High-Res Text UI Elements Base UI Support Functions  v1.2
''
''  File: SpinBox.spin
''  Author: Allen Marincak
''  Copyright (c) 2009 Allen MArincak
''  See end of file for terms of use
'' ===========================================================================
''
''============================================================================
'' Simple SpinBox
''============================================================================
''
'' Creates a simple spin box control. Data may be text or numeric.


CON
    MAX_LEN = 16 


OBJ
  SBOX          : "SimpleBox"


VAR
  word  varGdx          'GUI control variable
  long  varScreenPtr    'screen buffer pointer
  long  varDataPtr      'points to the display data (not the setup bytes)
  long  varDrawIdx      'vga index to start of display item area
  long  n_idx           'index into number string
  word  varUpIdx        'vga index of up arrow
  word  varDnIdx        'vga index of down arrow
  byte  n_str[MAX_LEN]  'string for numeric data
  byte  varRow          'top row location
  byte  varCol          'left col location
  byte  varCol2         'right col location
  byte  varWidth        'width ... info area is 6 less than total width
  byte  varVgaCols      'width of screen in columns
  byte  varNumData      'number of data items
  byte  varDataIdx      'current data item displayed
  byte  varType         '0 = text   1 = numeric


PUB Init ( pRow, pCol, pWidth, pType, pNum, pDataPtr, pVgaPtr, pVgaWidth ) | vgaIdx

  varVgaCols    := pVgaWidth
  varRow        := pRow
  varCol        := pCol
  varWidth      := pWidth
  varScreenPtr  := pVgaPtr
  varCol2       := varCol + varWidth
  varDataPtr    := pDataPtr
  varType       := pType
  varNumData    := pNum
  varDataIdx    := 0
  varDrawIdx    := varRow*varVgaCols+varVgaCols+varCol+1 'display item location
  
  SBOX.DrawBox( pRow, pCol, pWidth, 3, 0, pVgaPtr, pVgaWidth )

  vgaIdx := varRow * varVgaCols + varCol + varWidth - 3
  byte[varScreenPtr][vgaIdx] := 16              'top 'tee' char
  vgaIdx += varVgaCols
  byte[varScreenPtr][vgaIdx] := 15              'vertical line char
  varDnIdx := vgaIdx+1                          'save position of DN arrow
  byte[varScreenPtr][vgaIdx+1] := 3             'down arrow char  
  vgaIdx += varVgaCols
  byte[varScreenPtr][vgaIdx] := 17              'bottom 'tee' char

  vgaIdx := varRow * varVgaCols + varCol + varWidth - 5
  byte[varScreenPtr][vgaIdx] := 16              'top 'tee' char
  vgaIdx += varVgaCols
  byte[varScreenPtr][vgaIdx] := 15              'vertical line char
  varUpIdx := vgaIdx+1                          'save position of UP arrow
  byte[varScreenPtr][vgaIdx+1] := 2             'up arrow char 
  vgaIdx += varVgaCols
  byte[varScreenPtr][vgaIdx] := 17              'bottom 'tee' char

  DrawData( varDataIdx )

  
PUB IsIn( pCx, pCy ) | retVal

  retVal := false

    if ( pCx => varCol ) AND ( pCx =< varCol2 )
      if pCy == varRow + 1 
        retVal := true

  return retVal


PUB Clicked( pCx, pCy ) | idx, retVal

  retVal := -1      'default return if neither arrow was pressed or at boundary
  
  idx := pCy*varVgaCols+pCx
  
  if idx == varUpIdx
    if varDataIdx <> varNumData - 1
      varDataIdx++
      retVal := varDataIdx

  if idx == varDnIdx
    if varDataIdx <> 0
      varDataIdx--
      retVal := varDataIdx
      
  if retVal <> -1
    DrawData( varDataIdx )

  return retVal


PUB GetDataIndex
'returns the zero based index of the currently displaying data
  return varDataIdx


PUB set_gzidx( gzidx )
  varGdx := gzidx


PUB get_gzidx
  return varGdx

  
PRI DrawData( didx ) | tptr, strLen
'Draws the specified (by zero based index) data in the spin box display area.
' didx = index of data item to display

  tptr := varDataPtr
  bytefill(@byte[varScreenPtr][varDrawIdx],32,varWidth-6)

  if varType == 0                               '----<data is text>-----------

    strLen := strsize( tptr )
    repeat didx
      tptr += strLen + 1
      strLen := strsize( tptr )
    bytemove(@byte[varScreenPtr][varDrawIdx], tptr, strLen )
  
  else                                          '----<data is numeric>--------
    strLen := varWidth-6
    strLen := 1 #> strLen <# constant(MAX_LEN - 1)
    bytemove(@byte[varScreenPtr][varDrawIdx], decf(long[tptr][didx],strLen), strLen )


''=============================================================================
'' The routine that follows is taken from the Simple_Numbers.spin object.
'' However, I collapsed clrstr() and decstr() into this decf() function.
''
''****************************************
''*  Simple_Numbers                      *
''*  Authors: Chip Gracey, Jon Williams  *
''*  Copyright (c) 2006 Parallax, Inc.   *
''*  See end of file for terms of use.   *
''****************************************

''=============================================================================
PRI decf(value, width) | t_val, field, div, z_pad

'' Converts value to signed-decimal string equivalent
'' - characters written to current position of n_idx
'' - returns pointer to n_str: signed-decimal, fixed-width, space padded string

  n_idx~                                        ' reset index
  t_val := ||value                              ' work with absolute
  field~                                        ' clear field

  bytefill(@n_str, 0, MAX_LEN)                  ' clear string to zeros

  repeat while t_val > 0                        ' count number of digits
    field++
    t_val /= 10

  field #>= 1                                   ' min field width is 1
  if value < 0                                  ' if value is negative
    field++                                     '  - bump field for neg sign indicator
  
  if field < width                              ' need padding?
    repeat (width - field)                      ' yes
      n_str[n_idx++] := " "                     '  - pad with space(s)

  if (value < 0)                                ' negative value?         
    -value                                      '  - yes, make positive
    n_str[n_idx++] := "-"                       '  - and print sign indicator

  div := 1_000_000_000                          ' initialize divisor
  z_pad~                                        ' clear zero-pad flag

  repeat 10
    if (value => div)                           ' printable character?
      n_str[n_idx++] := (value / div + "0")     '  - yes, print ASCII digit
      value //= div                             '  - update value
      z_pad~~                                   '  - set zflag
    elseif z_pad or (div == 1)                  ' printing or last column?
      n_str[n_idx++] := "0"
    div /= 10 

  return @n_str

  
{{
┌────────────────────────────────────────────────────────────────────────────┐
│                     TERMS OF USE: MIT License                              │                                                            
├────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy│
│of this software and associated documentation files (the "Software"), to    │
│deal in the Software without restriction, including without limitation the  │
│rights to use, copy, modify, merge, publish, distribute, sublicense, and/or │
│sell copies of the Software, and to permit persons to whom the Software is  │
│furnished to do so, subject to the following conditions:                    │
│                                                                            │
│The above copyright notice and this permission notice shall be included in  │
│all copies or substantial portions of the Software.                         │
│                                                                            │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR  │
│IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,    │
│FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE │
│AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER      │
│LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING     │
│FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS│
│IN THE SOFTWARE.                                                            │
└────────────────────────────────────────────────────────────────────────────┘
}}   