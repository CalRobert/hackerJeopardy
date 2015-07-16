'' ===========================================================================
''  VGA High-Res Text UI Elements Base UI Support Functions  v1.2
''
''  File: TextBox.spin
''  Author: Allen Marincak
''  Copyright (c) 2009 Allen MArincak
''  See end of file for terms of use
'' ===========================================================================
''
''============================================================================
'' TextBox Control
''============================================================================
''
'' Creates a simple text box with auto scrolling text area
''
'' This control is a text window that you can print ASCII strings to. You can
'' set it to truncate ot wrap long lines. If lines are wrapped all wrapped
'' lines will be prefixed with an inverted right arrow character to mark the
'' wrapping operation. Leading and trailing CRLF characters are stripped from
'' the string but CRLFs inside the string remain and will be print as "funny"
'' characters. A titlebar with a caption may optionally be applied.

OBJ
  SBOX          : "SimpleBox"

  
VAR
  word varGdx         'GUI control variable
  long varScreenPtr   'screen buffer pointer
  byte varRow         'top row location
  byte varRow2        'bottom row location
  byte varCol         'left col location
  byte varCol2        'right col location
  byte varWidth       'width ... text width is 2 less than total width
  byte varHeight      'height ... text height is 2 or 4 less than total height
  byte varTitle       'number of rows used for title area ( 0 or 2 )
  byte varRowIdx      'index to current row to be written
  byte varVgaCols     'width of screen in columns
  byte varWrap        '0=truncate lines   1=wrap lines (marks wrapped lines)
  

PUB Init( pRow, pCol, pWidth, pHeight, pWrap, pTitlePtr, pVgaPtr, pVgaWidth )

  varVgaCols    := pVgaWidth
  varRow        := pRow
  varCol        := pCol
  varWidth      := pWidth
  varHeight     := pHeight
  varWrap       := pWrap
  varRow2       := pRow + 2
  varCol2       := pCol + pWidth - 1
  varRowIdx     := 0
  varScreenPtr  := pVgaPtr

  if pTitlePtr == 0                             'no title text ?
    varTitle := 0
  else
    varTitle := 2

  SBOX.DrawBox( pRow, pCol, pWidth, pHeight, pTitlePtr, pVgaPtr, pVgaWidth )
  
  
PUB IsIn( pCx, pCy ) : qq

  qq := false

    if ( pCx => varCol ) AND ( pCx =< varCol2 )
      if ( pCy => ( varRow + varTitle ) ) AND ( pCy =< varRow2 )
        qq := true

  return qq


PUB Clear | tbRows, idx, vgaIdx

  tbRows := varHeight - varTitle - 2

  vgaIdx := ( varRow + varTitle + 1 ) * varVgaCols + varCol + 1

  repeat tbRows
    bytefill( @byte[varScreenPtr][vgaIdx], 32, varWidth - 2 )
    vgaIdx += varVgaCols

  varRowIdx := 0     
  
PUB Hide | tbRows, idx, vgaIdx
  tbRows := varHeight - varTitle - 2
  vgaIdx := ( varRow + varTitle + 1 ) * varVgaCols + varCol + 1

  repeat tbRows
    bytefill( @byte[varScreenPtr][vgaIdx], 32, varWidth - 2 )
    vgaIdx += varVgaCols

  varRowIdx := 0   

PUB Print( pTxtPtr, pSize ) | strLen, tbRows, vgaIdx

  tbRows := varHeight - varTitle - 2
  if varRowIdx == tbRows                        'if full, scroll up
    Scroll

  vgaIdx := (varRow+varTitle+varRowIdx+1)*varVgaCols+varCol+1 'index to screen
  
  if pSize <> 0                                 'determine string size
    strLen := pSize
  else
    strLen := strsize( pTxtPtr )

  if strlen > 0                                 'strip leading CRLF
    repeat while byte[pTxtPtr][0] < 32
      strLen--
      pTxtPtr++
      if strLen == 0
        quit
  
  if strLen > 0                                 'strip trailing CRLF
    repeat while byte[pTxtPtr][strLen-1] < 32
      strLen--
      if strLen == 0
        quit

  if varWrap == 0               'if not wrapping lines
    strLen <#= (varWidth-2)     ' - truncate line length to window width

  if strLen =< varWidth-2
    bytemove(@byte[varScreenPtr][vgaIdx],pTxtPtr,strLen)' - copy whole string
    if varRowIdx < tbRows
      varRowIdx++
  else
    bytemove(@byte[varScreenPtr][vgaIdx],pTxtPtr,varWidth-2)' - copy part string
    if varRowIdx < tbRows
      varRowIdx++
    strlen -= varWidth-2
    pTxtPtr += varWidth-2

    repeat                                      'repeat till all of string done
      if varRowIdx == tbRows                    'scroll if required
        Scroll
      vgaIdx := (varRow+varTitle+varRowIdx+1)*varVgaCols+varCol+1  'index to screen
      byte[varScreenPtr][vgaIdx] := $81         'inverted right arrow to show wrap
      if strLen =< varWidth-3
        bytemove(@byte[varScreenPtr][vgaIdx+1],pTxtPtr,strLen)' - copy remaining string
        if varRowIdx < tbRows
          varRowIdx++
          quit
      else
        bytemove(@byte[varScreenPtr][vgaIdx+1],pTxtPtr,varWidth-3)' copy part string
        strlen -= varWidth-3
        pTxtPtr += varWidth-3
        if varRowIdx < tbRows
          varRowIdx++


PUB Scroll | vgaIdx, tbRows

  tbRows := varHeight - varTitle - 2
  vgaIdx := ( varRow + varTitle + 1 ) * varVgaCols + varCol
  repeat tbRows - 1
    longmove( @byte[varScreenPtr][vgaIdx], @byte[varScreenPtr][vgaIdx+varVgaCols], varWidth / 4 )
    vgaIdx += varVgaCols
  bytefill( @byte[varScreenPtr][vgaIdx+1], 32, varWidth - 2 )
  varRowIdx--


PUB Title( pTxtPtr ) | strIdx, vgaIdx

  if varTitle <> 0
    strIdx := strSize( pTxtPtr )
    vgaIdx := varRow * varVgaCols + varCol + varVgaCols +1 'title location
    bytefill( @byte[varScreenPtr][vgaIdx], 32, varWidth - 2 )
    bytemove( @byte[varScreenPtr][vgaIdx], pTxtPtr, strIdx )


PUB set_gzidx( gzidx )
  varGdx := gzidx


PUB get_gzidx
  return varGdx

  
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