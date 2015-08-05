'' ===========================================================================
''  VGA High-Res Text UI Elements Base UI Support Functions  v1.2
''
''  File: GUIBase.spin
''  Author: Allen Marincak
''  Copyright (c) 2009 Allen MArincak
''  See end of file for terms of use
'' ===========================================================================

CON
  '---------------------------------------------------------------------------
  ' GUI Element Inventory  
  '---------------------------------------------------------------------------
  ' User modifies these as required by the GUI application being written.
  ' These constants describe how many elements of each type are required. Set
  ' any you do not need to 1. You can't set it to 0 because there is no
  ' conditional compilation for SPIN so I can't avoid NULL references.
  '-------------------------------------------------------------------------- 

  GZ_SPIN   = 1     'number of SPIN controls
  GZ_CHKB   = 1     'number of Check Boxes
  GZ_RADB   = 1     'number of Radio Buttons
  GZ_TBOX   = 18     'number of Text Boxes
  GZ_MENU   = 38     'number of Menu Items
  GZ_INPF   = 1     'number of Input Fields
  GZ_PUSH   = 1     'number of pushbuttons
  GZ_STAT   = 1     'number of Status Lamps

  
  '---------------------------------------------------------------------------
  ' Do not modify any of the constants below
  '---------------------------------------------------------------------------

  GZ_TOTAL  = GZ_SPIN+GZ_CHKB+GZ_RADB+GZ_TBOX+GZ_MENU+GZ_INPF+GZ_PUSH+GZ_STAT

  GID_SPIN  = $0100 'types
  GID_CHKB  = $0200
  GID_RADB  = $0300
  GID_TBOX  = $0400
  GID_MENU  = $0500
  GID_INPF  = $0600
  GID_PUSH  = $0700
  GID_STAT  = $0800

  G_INIT    = $8000
  G_IMSK    = $7F00
  G_OMSK    = $00FF

  VGACOLS = SVGA#cols
  VGAROWS = SVGA#rows

  
OBJ
  '---------------------------------------------------------------------------
  ' required driver objects, keep these
  '---------------------------------------------------------------------------
  SVGA          : "vga_hires_text"
  MOUS          : "mouse"
  KEYB          : "Keyboard"    'only needed if using the Input Field Object

  '---------------------------------------------------------------------------
  ' UI element objects
  '
  ' You will need to comment out elements for which you set the number to 0,
  ' the compiler will issue an error for 0 sized arrays.
  '
  ' Note that the SBOX object (Simple Box) is used by several other objects so
  ' do not comment out that one (it is miniscule anyway)
  '---------------------------------------------------------------------------
  SPIN[GZ_SPIN] : "SpinBox"
  CHKB[GZ_CHKB] : "RadioCheck"
  RADB[GZ_RADB] : "RadioCheck"
  TBOX[GZ_TBOX] : "TextBox"
  MENU[GZ_MENU] : "MenuItem"
  INPF[GZ_INPF] : "InputField"
  PUSH[GZ_PUSH] : "PushButton"
  STAT[GZ_STAT] : "StatusLamp"
  SBOX          : "SimpleBox"


VAR
  long  scrn[VGACOLS*VGAROWS/4]     'screen buffer - could be bytes, but longs allow more efficient scrolling
  word  colors[VGAROWS]             'row colors
  long  sync                        'sync long - written to -1 by VGA driver after each screen refresh
  byte  cx0,cy0,cm0,cx1,cy1,cm1     'cursor control bytes  
  long  liveINPF                    'currently active Input Field (has keyboard focus)
  word  gz_elem[GZ_TOTAL]           'element management array
  byte  gz_groups[GZ_RADB]          'radio button group control

CON ''=====< GUI Base Functions >=============================================
    '
    ' <!> NOTE <!>  Do not modify anything below unless you wish ot add or
    '               make changes to the GUI functionality
    '-------------------------------------------------------------------------                   
PUB Init( vgaBasePin, MouseDatPin, MouseClkPin, KeyboardDatPin, KeyboardClkPin ) | idx, gdx
'Initializes the VGA, Mouse and Keyboard Drivers as well as basic GUI parameters
'
'   vgaBasePin      - start of 8 consecutive pins where the VGA H/W interface is
'   MouseDatPin     - the pin driving the mouse data line
'   MouseClkPin     - the pin driving the mouse clock line
'   KeyboardDatPin  - the pin driving the keyboard data line
'   KeyboardClkPin  - the pin driving the keyboard clock line
'
'Returns the screen geometry in a WORD
'   high byte = number of character rows
'    low byte = number of cgaracter columns

  '---------------------------------------------------------------------------
  ' Start VGA, Mouse and Keyboard Drivers
  '---------------------------------------------------------------------------

  cx1 := 0                              'text cursor starting position
  cy1 := 3                              '  (but hidden at start)
  
  SVGA.start(vgaBasePin,@scrn,@colors,@cx0,@sync) 'start VGA HI RES TEXT driver

  MOUS.start(MouseDatPin, MouseClkPin)  'start mouse and set bound parameters
  MOUS.bound_limits(0, 0, 0, VGACOLS - 1, VGAROWS - 1, 0)
  MOUS.bound_scales(4, -7, 0)           'adjust speed/sensitivity to be a touch slower
  MOUS.bound_preset(2, 6, 0)            'mouse starting position

  KEYB.start( KeyboardDatPin, KeyboardClkPin ) 'start keyboard driver

  cm0 := %001                           'set mouse cursor to be a solid block
  cm1 := %000                           'set text cursor to be off for the moment

  ClearScreen( %%020, %%000 )           'green on black each is %%RGB 4 levels per R-G-B

  
  '---------------------------------------------------------------------------
  'Prepare management and control array. This array has an entry for each
  'element declared it maintains the status of each element and indices into
  'the individual element arrays
  '  
  'WORD format: aabb
  '
  '   where   aa = type  with msb 0 = free   1 = set (initialized)
  '           bb = index to element array
  '---------------------------------------------------------------------------
                                    
  gdx := 0

  if GZ_SPIN
    repeat idx from 0 to GZ_SPIN - 1
      gz_elem[gdx] := GID_SPIN + idx
      SPIN[idx].set_gzidx( gdx )
      gdx++
     
  if GZ_CHKB
    repeat idx from 0 to GZ_CHKB - 1
      gz_elem[gdx] := GID_CHKB + idx
      CHKB[idx].set_gzidx( gdx )
      gdx++
     
  if GZ_RADB
    repeat idx from 0 to GZ_RADB - 1
      gz_elem[gdx] := GID_RADB + idx
      RADB[idx].set_gzidx( gdx )
      gdx++
     
  if GZ_TBOX
    repeat idx from 0 to GZ_TBOX - 1
      gz_elem[gdx] := GID_TBOX + idx
      TBOX[idx].set_gzidx( gdx )
      gdx++
     
  if GZ_MENU
    repeat idx from 0 to GZ_MENU - 1
      gz_elem[gdx] := GID_MENU + idx
      MENU[idx].set_gzidx( gdx )
      gdx++
     
  if GZ_INPF
    repeat idx from 0 to GZ_INPF - 1
      gz_elem[gdx] := GID_INPF + idx
      INPF[idx].set_gzidx( gdx )
      gdx++
     
  if GZ_PUSH
    repeat idx from 0 to GZ_PUSH - 1
      gz_elem[gdx] := GID_PUSH + idx
      PUSH[idx].set_gzidx( gdx )
      gdx++
     
  if GZ_STAT
    repeat idx from 0 to GZ_STAT - 1
      gz_elem[gdx] := GID_STAT + idx
      STAT[idx].set_gzidx( gdx )
      gdx++

  liveINPF := 0

  return ( VGAROWS << 8 ) + VGACOLS


PUB ProcessUI | retVal, gdx_in, odx, idx, tmp
'This  function is the UI processing and control funtion. It must be executed
'often, regularly, and quickly. It should be placed in the application main
'loop and be allowed to run as often as possible to ensure a responsive UI
'
'This function will manage the UI and will return the unique id of the GUI
'element that requires an action (i.e. user clicked on an it==em or pressed
'enter in an Input Field). The value returned ( a GUID ) is the same value
'that was returned when the element was created via "Init" function (i.e.
'from GUI.SPINInit()  or  GUI.PUSHInit(), etc)
'
''Fuzzbizz update - some custom returns (negative integers) added

  retVal := -1
   
  cx0 := MOUS.bound_x                   'get mouse position to set cursor 0 position
  cy0 := MOUS.bound_y                   'ALWAYS do this first
    
  '---------------------------------------------------------------------------
  'check if mouse over a control
  '---------------------------------------------------------------------------
  gdx_in := IsIn( cx0, cy0 )

  '---------------------------------------------------------------------------
  'on mouse left click perform UI action for selected element (if any)
  '---------------------------------------------------------------------------
  if gdx_in <> -1                       'if we are in a gui element
                                         '    
    if MOUS.button(0)                   'if mouse left-click

      odx := gz_elem[gdx_in] & G_OMSK   'index to object array
      
      case gz_elem[gdx_in] & G_IMSK
        GID_SPIN:                       'in Spin Control
          if SPIN[odx].Clicked(cx0,cy0)<>-1 ' - execute click on spin
          retVal := gdx_in

        GID_CHKB:                       'in Check Box
          CHKB[odx].Select( -1 )        ' - toggle checkbox
          retVal := gdx_in
          
        GID_RADB:                       'in Radio Button
          idx := 0
          repeat GZ_RADB                'for each radio button           
            if odx == idx
              RADB[idx].Select( 1 )     '  - toggle ON the selected one
              RADB[idx].DrawText( 1 )
            else
              if gz_groups[odx] == gz_groups[idx]
                RADB[idx].Select( 0 )   '  - toggle OFF the others in this group
                RADB[idx].DrawText( 0 )              
            idx++
          retVal := gdx_in
        
        GID_TBOX:                       'in Text Box
          retVal := gdx_in
          
        GID_MENU:                       'in Menu Item
          retVal := gdx_in
        
        GID_INPF:                       'in Input Field
          idx := 0           
          repeat GZ_INPF                'for each input field
            if idx == odx
              INPF[idx].Select(1,@cx1,@cy1)
              liveINPF := idx
              cm1 := %111               'turn text cursor on, underscore slow blink
            else
              INPF[idx].Select(0,@cx1,@cy1)      
            idx++
          'note no return for selecting INPF
        
        GID_PUSH:                       'in Push Button
          retVal := gdx_in
        
        GID_STAT:                       'in Status Lamp
          retVal := gdx_in
               
      repeat while MOUS.button(0)       '    - wait for mouse release

  'Added by fuzzbizz
  'Handle clicking blank

  else
    if MOUS.button(0)
      retVal := 0

  '---------------------------------------------------------------------------
  'Handle Keyboard input
  '---------------------------------------------------------------------------

  if KEYB.gotkey
    'idx := INPF[liveINPF].get_gzidx
    'if gz_elem[idx] & G_INIT == G_INIT          'is it set
    '  tmp := INPF[liveINPF].Handler(KEYB.key)  
    '  if tmp & $80000000

    'make this negative as a half-ass way to deal with collision. We're
    'only returning the array 
    retVal := -KEYB.key
        'retVal := INPF[liveINPF].get_gzidx      'if enter was pressed
    'clear keys, Otherwise we always have some shit in the buffer and this always returns. 
    KEYB.clearkeys

  return retVal


PUB GetMouseXY
'Returns the mouse location in a WORD
'   high byte = x location
'    low byte = y location
  return ( cx0 << 8 ) + cy0

  
PRI IsIn( cx, cy ) | idx, gdx, retVal
'returns -1 if not in an element else a gui token (gz_elem[] array index)

  retVal := -1

  if GZ_SPIN
    repeat idx from 0 to GZ_SPIN - 1
      gdx := SPIN[idx].get_gzidx
      if gz_elem[gdx] & G_INIT == G_INIT 'is it set
        if SPIN[idx].IsIn( cx, cy )
          retVal := SPIN[idx].get_gzidx
     
  if GZ_CHKB
    repeat idx from 0 to GZ_CHKB - 1
      gdx := CHKB[idx].get_gzidx
      if gz_elem[gdx] & G_INIT == G_INIT 'is it set
        if CHKB[idx].IsIn( cx, cy )
          retVal := CHKB[idx].get_gzidx
          CHKB[idx].DrawText( 1 )
        else
          CHKB[idx].DrawText( 0 )
         
  if GZ_RADB
    repeat idx from 0 to GZ_RADB - 1
      gdx := RADB[idx].get_gzidx
      if gz_elem[gdx] & G_INIT == G_INIT 'is it set
        if RADB[idx].IsIn( cx, cy )
          retVal := RADB[idx].get_gzidx
          RADB[idx].DrawText( 1 )
        else
          RADB[idx].DrawText( 0 )
         
  if GZ_TBOX
    repeat idx from 0 to GZ_TBOX - 1
      gdx := TBOX[idx].get_gzidx
      if gz_elem[gdx] & G_INIT == G_INIT 'is it set
        if TBOX[idx].IsIn( cx, cy )
          retVal := TBOX[idx].get_gzidx
         
  if GZ_MENU
    repeat idx from 0 to GZ_MENU - 1
      gdx := MENU[idx].get_gzidx
      if gz_elem[gdx] & G_INIT == G_INIT 'is it set
        if MENU[idx].IsIn( cx, cy )
          retVal := MENU[idx].get_gzidx
          MENU[idx].DrawText( 1 )
        else
          MENU[idx].DrawText( 0 )
         
  if GZ_INPF
    repeat idx from 0 to GZ_INPF - 1
      gdx := INPF[idx].get_gzidx
      if gz_elem[gdx] & G_INIT == G_INIT 'is it set
        if INPF[idx].IsIn( cx, cy )
          retVal := INPF[idx].get_gzidx
         
  if GZ_PUSH
    repeat idx from 0 to GZ_PUSH - 1
      gdx := PUSH[idx].get_gzidx
      if gz_elem[gdx] & G_INIT == G_INIT 'is it set
        if PUSH[idx].IsIn( cx, cy )
          retVal := PUSH[idx].get_gzidx
          PUSH[idx].DrawText( 1 )
        else
          PUSH[idx].DrawText( 0 )
         
  if GZ_STAT
    repeat idx from 0 to GZ_STAT - 1
      gdx := STAT[idx].get_gzidx
      if gz_elem[gdx] & G_INIT == G_INIT 'is it set
        if STAT[idx].IsIn( cx, cy )
          retVal := STAT[idx].get_gzidx
         
  return retVal


CON ''=====< SIMPLE BOX INTERFACE FUNCTIONS >=================================

PUB SBOXInit( pRow, pCol, pWidth, pHeight, pTitlePtr )
'Creates box with specified width and text. Something like:
'   -------------
'  |             |  - title area ( non-existent if no title supplied)
'   -------------
'  |             |
'  |             |  - text area with optional scolling print capability
'  |             |
'   -------------
'
'  pRow       = row upper location
'  pCol       = col left location
'  pWidth     = width 
'  pHeight    = height 
'  pTitlePtr  = title text (text must be 2 less than width)
'
' NOTE: Columns must be LONG aligned to take advantage of the most efficient  
'       scrolling (via LONGMOVE). The start column must be on a long boundary
'       (multiple of 4) and the width must be a multiple of 4. If print scrolling
'       is not required this restriction can be ignored.
'
' NOTE: There is NO RETURN value from this call. Simple Boxes are not tracked,
'       they are viaual element but are not active elements 
  SBOX.DrawBox( pRow, pCol, pWidth, pHeight, pTitlePtr, @scrn, VGACOLS )


CON ''=====< SPIN BOX INTERFACE FUNCTIONS >===================================

PUB SPINInit( pRow, pCol, pWidth, pType, pNum, pDataPtr ) | idx, gdx, retVal
'Creates a spin button box with specified width and text. Something like:
'   ---------------------
'  | spin text       |↑|↓|
'   ---------------------
'
'  pRow       = row upper location
'  pCol       = col left location
'  pWidth     = width of the control in columns
'  pType      = 0 = text   1 = numeric
'  pNum       = number of data elements
'  pDataPtr   = pointer to data for spin control
'
'  The Data for the spin control is stored in a DAT section. For text type
'  the section will be a number of byte aligned strings, each with a null
'  terminator. For numeric type the section will be a number of long aligned
'  longs.
'
'Returns  -1    if there are no more free elements in the SPIN object array
'         guid  on success which is unique and used to identify the specific
'               instance of the control.

  retVal := -1
  
  repeat idx from 0 to GZ_TBOX - 1
    gdx := SPIN[idx].get_gzidx
    if gz_elem[gdx] & G_INIT == 0       'is it free
      retVal := gdx
      gz_elem[gdx] |= G_INIT            'mark it used
      SPIN[idx].Init( pRow, pCol, pWidth, pType, pNum, pDataPtr, @scrn, VGACOLS )
      quit

  return retVal

PUB SPINIsIn( guid ) | odx
' returns true  if the mouse is inside the spin control
'         false otherwise

  odx := gz_elem[guid] & G_OMSK
  return SPIN[odx].IsIn( MOUS.bound_x, MOUS.bound_y )

PUB SPINClicked( guid ) | odx
'checks where the mouse click ocurred and returns -1 if not on an UP or DOWN
'arrow otherwise it returns the zero based data index of the currently
'displayed data

  odx := gz_elem[guid] & G_OMSK
  return SPIN[odx].Clicked( MOUS.bound_x, MOUS.bound_y )

PUB SPINGetDataIndex( guid ) | odx
'returns the zero based index of the currently displayed data item

  odx := gz_elem[guid] & G_OMSK
  return SPIN[odx].GetDataIndex


CON ''=====< CHECK BOX INTERFACE FUNCTIONS >==================================

PUB CHKBInit( pRow, pCol, pTextWidth, pTextPtr ) | idx, gdx, retVal
'Creates a checkbox box at the specified location.
'Something like:
'
'  X Text here
'
'     where X is a check box symbol
'
'  pRow       = row upper location
'  pCol       = col left location
'  pTextWidth = width of button text (MAX 15 characters)
'  pTextPtr   = checkbox text (MAX 15 characters)
'
'Returns  -1    if there are no more free elements in the CHKB object array
'         guid  on success which is unique and used to identify the specific
'               instance of the control.

  retVal := -1
  
  repeat idx from 0 to GZ_CHKB - 1
    gdx := CHKB[idx].get_gzidx
    if gz_elem[gdx] & G_INIT == 0       'is it free
      retVal := gdx
      gz_elem[gdx] |= G_INIT            'mark it used
      CHKB[idx].Init( pRow, pCol, pTextWidth, 0, pTextPtr, @scrn, VGACOLS )
      quit

  return retVal

PUB CHKBIsIn( guid ) | odx
' returns true if the mouse is inside the check box
'         false otherwise
  odx := gz_elem[guid] & G_OMSK
  return CHKB[odx].IsIn( MOUS.bound_x, MOUS.bound_y )

PUB CHKBDrawText( guid, pMode ) | odx
'  pMode 0  = 0 for normal
'           = 1 for inverted
  odx := gz_elem[guid] & G_OMSK
  CHKB[odx].DrawText( pMode )

PUB CHKBSelect( guid, pSel ) | odx
'sel = 1 to select   0 to deselect    -1 to toggle it
  odx := gz_elem[guid] & G_OMSK
  CHKB[odx].Select( pSel )


PUB CHKBIsSet( guid ) | odx
'returns the status of the button (set=true  not set=false)
  odx := gz_elem[guid] & G_OMSK
  return CHKB[odx].isSet
  

CON ''=====< RADIO BUTTON INTERFACE FUNCTIONS >===============================

PUB RADBInit( pRow, pCol, pTextWidth, pTextPtr, pGroupID ) | idx, gdx, retVal
'Creates a radio button at the specified location.
'Something like:
'
'  X Text here
'
'     where X is a radio button symbol
'
'  pRow       = row upper location
'  pCol       = col left location
'  pTextWidth = width of button text (MAX 15 characters)
'  pTextPtr   = checkbox text (MAX 15 characters)
'  pGroupID   = the id of the radio button group that this button belongs to
'
'Returns  -1    if there are no more free elements in the RADB object array
'         guid  on success which is unique and used to identify the specific
'               instance of the control.

  retVal := -1
  
  repeat idx from 0 to GZ_RADB - 1
    gdx := RADB[idx].get_gzidx
    if gz_elem[gdx] & G_INIT == 0       'is it free
      retVal := gdx
      gz_elem[gdx] |= G_INIT            'mark it used
      RADB[idx].Init( pRow, pCol, pTextWidth, 1, pTextPtr, @scrn, VGACOLS )
      gz_groups[idx] := pGroupID        'remember group button belongs to       RB_GRP
      quit

  return retVal

PUB RADBIsIn( guid ) | odx
' returns true if the mouse inside the radio button
'         false otherwise
  odx := gz_elem[guid] & G_OMSK
  return RADB[odx].IsIn( MOUS.bound_x, MOUS.bound_y )

PUB RADBDrawText( guid, pMode ) | odx
'  pMode 0  = 0 for normal
'           = 1 for inverted
  odx := gz_elem[guid] & G_OMSK
  RADB[odx].DrawText( pMode )

PUB RADBSelect( guid, pSel ) | odx
'sel = 1 to select   0 to deselect    -1 to toggle it
  odx := gz_elem[guid] & G_OMSK
  RADB[odx].Select( pSel )

PUB RADBIsSet( guid ) | odx
'returns the status of the button (set=true  not set=false)
  odx := gz_elem[guid] & G_OMSK
  return RADB[odx].isSet


CON ''=====< PUSH BUTTON INTERFACE FUNCTIONS >================================

PUB PUSHInit( pRow, pCol, pTextPtr ) | idx, gdx, retVal
'Creates a pushbutton at the specified location.
'Something like:
'   ---------------
'  |ttttttttttttttt|
'   ---------------
'
'    where t = button text (MAX 15 characters)
'
'  pRow       = row upper location
'  pCol       = col left location
'  pTextPtr   = push button text (MAX 15 characters + null terminator)
'
'Returns  -1    if there are no more free elements in the PUSH object array
'         guid  on success which is unique and used to identify the specific
'               instance of the control.

  retVal := -1
  
  repeat idx from 0 to GZ_PUSH - 1
    gdx := PUSH[idx].get_gzidx
    if gz_elem[gdx] & G_INIT == 0       'is it free
      retVal := gdx
      gz_elem[gdx] |= G_INIT            'mark it used
      PUSH[idx].Init( pRow, pCol, pTextPtr, @scrn, VGACOLS )
      quit

  return retVal

PUB PUSHIsIn( guid ) | odx
' returns true if the mouse is inside the push button
'         false otherwise
  odx := gz_elem[guid] & G_OMSK
  return PUSH[odx].IsIn( MOUS.bound_x, MOUS.bound_y )

PUB PUSHDrawText( guid, pMode ) | odx
'draws the pusbutton text in normal or inverted video.
'  mode bit 0 = 0 for normal
'             = 1 for inverted
  odx := gz_elem[guid] & G_OMSK
  PUSH[odx].DrawText( pMode )

PUB PUSHSetText( guid, pPtr ) | odx
'sets new text for the pushbutton
' pPtr points to the text, it MUST be the same size (or less) as the text
'      it is replacing
  odx := gz_elem[guid] & G_OMSK
  PUSH[odx].SetText( pPtr )


CON ''=====< TEXT BOX INTERFACE FUNCTIONS >===================================

PUB TBOXInit( pRow, pCol, pWidth, pHeight, pWrap, pTitlePtr ) | idx, gdx, retVal
'Creates a box with specified width and text. Something like:
'   -------------
'  |             |  - title area ( non-existent if no title supplied)
'   -------------
'  |             |
'  |             |  - text area with optional scolling print capability
'  |             |
'   -------------
'
'  pRow       = row upper location
'  pCol       = col left location
'  pWidth     = width 
'  pHeight    = height
'  pWrap      = 0 = truncate     1 = wrap lines
'  pTitlePtr  = title text text  (text must be 2 less than width ore 32 MAX)
'
'Returns  -1    if there are no more free elements in the TBOX object array
'         guid  on success which is unique and used to identify the specific
'               instance of the control.
'
' NOTE: Columns must be LONG aligned to take advantage of the most efficient  
'       scrolling (via LONGMOVE). The start column must be on a long boundary
'       (multiple of 4) and the width must be a multiple of 4. If print scrolling
'       is not required this restriction can be ignored. 

  retVal := -1
  
  repeat idx from 0 to GZ_TBOX - 1
    gdx := TBOX[idx].get_gzidx
    if gz_elem[gdx] & G_INIT == 0       'is it free
      retVal := gdx
      gz_elem[gdx] |= G_INIT            'mark it used
      TBOX[idx].Init( pRow, pCol, pWidth, pHeight, pWrap, pTitlePtr, @scrn, VGACOLS )
      quit

  return retVal


PUB ClearRectangle (pRow, pCol, pWidth, pHeight,  pVgaWidth) | vgaIdx, vgaStartIdx , pVgaPtr
  pVgaPtr := @scrn
  vgaStartIdx := pRow * pVgaWidth + pCol
  
  vgaIdx := vgaStartIdx                         'clear the area first
  repeat pHeight
    bytefill(@byte[pVgaPtr][vgaIdx],32,pWidth)
    vgaIdx += pVgaWidth


PUB TBOXIsIn( guid ) | odx
' returns true if the mouse is inside the text box text area
'                (i.e. excluding title area if there is one)
'         false otherwise
  odx := gz_elem[guid] & G_OMSK
  return TBOX[odx].IsIn( MOUS.bound_x, MOUS.bound_y )

PUB TBOXClear( guid ) | odx
'clears the text box.
  odx := gz_elem[guid] & G_OMSK
  TBOX[odx].Clear

PUB TBOXHide( guid ) | odx
'clears the text box.
  odx := gz_elem[guid] & G_OMSK
  TBOX[odx].Hide

PUB TBOXPrint( guid, pTxtPtr, pSize ) | odx
'Prints a line of text. Iif already at the last row the existing text is
'scrolled up one line first and the top line is removed. Inverted text is
'written with the high bit of each character set. If line wrap is enabled the
'lines that are wrapped are marked with a preceding inverted right arrow
'character (non-printable Ascii). Leading and trailing CRLF characters are
'stripped out. Any intra line CRLFs are ignored and will display as 'funny'
'characters.
'
' pTxtPtr = pointer to null terminated string
' size    = 0 for null terminated strings
'         = the string length for non-null terminated strings
  odx := gz_elem[guid] & G_OMSK
  TBOX[odx].Print( pTxtPtr, pSize )

PUB TBOXScroll( guid ) | odx
'scroll the test area up one line
  odx := gz_elem[guid] & G_OMSK
  TBOX[odx].Scroll

PUB TBOXTitle( guid, pTxtPtr ) | strIdx, vgaIdx, odx
'replace the original titlebar caption with new text. If no title was declared
'on initialization then this method will do nothing
'
' pTxtPtr = pointer to text to place in titlebar
  odx := gz_elem[guid] & G_OMSK
  TBOX[odx].Title( pTxtPtr )


CON ''=====< MENU ITEM INTERFACE FUNCTIONS >==================================

PUB MENUInit( pRow, pCol, pTextPtr ) | idx, gdx, retVal
'Creates a menu item at the specified location.
'Something like:
' StttttttttttttttS
'
'    where S = space character
'          t = character position (MAX 15 characters)
'
'  pRow       = row upper location
'  pCol       = col left location
'  pTextPtr   = menu item text (MAX 15 characters + null terminator)
'
'Returns  -1    if there are no more free elements in the MENU object array
'         guid  on success which is unique and used to identify the specific
'               instance of the control.

  retVal := -1
  
  repeat idx from 0 to GZ_MENU - 1
    gdx := MENU[idx].get_gzidx
    if gz_elem[gdx] & G_INIT == 0       'is it free
      retVal := gdx
      gz_elem[gdx] |= G_INIT            'mark it used
      MENU[idx].Init( pRow, pCol, pTextPtr, @scrn, VGACOLS )
      quit

  return retVal

PUB MENUIsIn( guid ) | odx
' returns true if the mouse is inside the menu item
'         false otherwise
  odx := gz_elem[guid] & G_OMSK
  return MENU[odx].IsIn( MOUS.bound_x, MOUS.bound_y )

PUB MENUSetColor(guid, BackClr, ForeClr) | wdClr
  wdClr := BackClr << 10 + ForeClr << 2 
  WORDFILL( @colors[41], wdClr, 1 )
  'WORDFILL( @colors, wdClr, VGAROWS )

PUB MENUDrawText( guid, pMode ) | odx
'draws the menu item text in normal or inverted video.
'  mode bit 0 = 0 for normal
'             = 1 for inverted
  odx := gz_elem[guid] & G_OMSK
  MENU[odx].DrawText( pMode )

PUB MENUSetText( guid, pPtr ) | odx
'Place new text on the menu item.
' pPtr points to the text, it MUST be the same size (or less) as the text
'      it is replacing
  odx := gz_elem[guid] & G_OMSK
  MENU[odx].SetText( pPtr )

PUB MENUSetStatus( guid, pStat ) | odx
'set a user defined status BYTE (any value fro 0 to 255)
  odx := gz_elem[guid] & G_OMSK
  MENU[odx].SetStatus( pStat )

PUB MENUGetStatus( guid ) | odx
'get the use defined status
  odx := gz_elem[guid] & G_OMSK
  return MENU[odx].GetStatus


CON ''=====< INPUT FIELD INTERFACE FUNCTIONS >================================

PUB INPFInit(pRow, pCol, pWidth, pType, pTitlePtr ) | idx, gdx, retVal
'Creates an input field box with specified width and text. Something like:
'   -----------------------
'  |Title| input field     |
'   -----------------------
'
'  pRow       = row upper location
'  pCol       = col left location
'  pWidth     = width of the control in columns
'  pType      = 0 = standalone    1=tacked on to above
'  pHeight    = height of the control in rows
'  pTitlePtr  = title text ( remainder is used for the input field )
'
'Returns  -1    if there are no more free elements in the SPIN object array
'         guid  on success which is unique and used to identify the specific
'               instance of the control.

  retVal := -1
  
  repeat idx from 0 to GZ_INPF - 1
    gdx := INPF[idx].get_gzidx
    if gz_elem[gdx] & G_INIT == 0       'is it free
      retVal := gdx
      gz_elem[gdx] |= G_INIT            'mark it used
      INPF[idx].Init( pRow, pCol, pWidth, pType, pTitlePtr,  @scrn, VGACOLS )
      quit

  return retVal

PUB INPFIsIn( guid ) | odx
' returns true if the mouse is inside the input field
'         false otherwise
  odx := gz_elem[guid] & G_OMSK
  return INPF[odx].IsIn( MOUS.bound_x, MOUS.bound_y )

PUB INPFClear( guid ) | odx
'clear the input field
  odx := gz_elem[guid] & G_OMSK
  INPF[odx].clear

PUB INPFSelect( guid, pSel ) | odx
'pSel = 1 to select   0 to deselect    -1 to toggle it
  odx := gz_elem[guid] & G_OMSK
  INPF[odx].Select( pSel, @cx1, @cy1 )
  liveINPF := odx
  cm1 := %111               'turn text cursor on, underscore slow blink
  
PUB INPFGetString( guid, pBuf ) | odx, tmp, str, len
'places the string in the input field into the buffer provided then clears
'the input field.
  odx := gz_elem[guid] & G_OMSK
  tmp := INPF[odx].GetStringCode
  str := ( tmp & $1FFF0000 ) >> 16
  len := tmp & $000000FF
  bytemove( pBuf, @scrn.byte[str], len )
  byte[pBuf][len] := 0
  INPFClear( guid )

CON ''=====< STATUS LAMP INTERFACE FUNCTIONS >================================

PUB STATInit( pRow, pCol, pWidth, pTitlePtr ) | idx, gdx, retVal
'Creates a status lamp with specified width and text. Something like:
'
'  Title : XXXX
'
'     where XXXX is user supplied condition status
'
'  pRow       = row upper location
'  pCol       = col left location
'  pWidth     = width of the control in columns
'  pHeight    = height of the control in rows
'  pTitlePtr  = title text text  (text must be 7 less than width )
'
'Returns  -1    if there are no more free elements in the SPIN object array
'         guid  on success which is unique and used to identify the specific
'               instance of the control.

  retVal := -1
  
  repeat idx from 0 to GZ_STAT - 1
    gdx := STAT[idx].get_gzidx
    if gz_elem[gdx] & G_INIT == 0       'is it free
      retVal := gdx
      gz_elem[gdx] |= G_INIT            'mark it used
      STAT[idx].Init( pRow, pCol, pWidth, pTitlePtr, @scrn, VGACOLS )
      quit

  return retVal

PUB STATIsIn( guid ) | odx
' returns true if the mouse is inside the menu item
'         false otherwise
  odx := gz_elem[guid] & G_OMSK
  return STAT[odx].IsIn( MOUS.bound_x, MOUS.bound_y )

PUB STATSet( guid, pSet, pStrPtr ) | odx
'pSet = 0 = off mode   (uses normal video)
'       1 = on mode    (uses inverted video)
'pStr = pointer to status string (4 chars max)
  odx := gz_elem[guid] & G_OMSK
  STAT[odx].Set( pSet, pStrPtr )

PUB STATGetStatus( guid ) | odx
'returns the current status of the object (1=on  0=off)
  odx := gz_elem[guid] & G_OMSK
  return STAT[odx].GetStatus


CON ''===== START OF VGA HIGH RES TEXT SCREEN FUNCTIONS ======================
PUB PrintStr( prRow, prCol, strPtr, inv ) | strLen, vgaIdx, idx
'this places text anywhere on the screen and can overwrite UI elements
'
' prRow  = row
' prCol  = column
' strPtr = pointer to null terminated string
' inv    = 0 for normal   1 for inverted video

  if ( prRow < VGAROWS ) AND ( prCol < VGACOLS )
    strLen := strsize( strPtr )
    vgaIdx := prRow * VGACOLS + prCol
    bytemove( @scrn.byte[vgaIdx], strPtr, strLen )
  if inv
    repeat idx from 1 to strLen
      byte[@scrn][vgaIdx] += 128
      vgaIdx++

'PUB ShowQuestion 
  'Stubbing this out. It should save the buffer, display question, display answer, then restore original buffer maybe?
'  LONGFILL( @scrn, $20202020, VGACOLS*VGAROWS/4 )   '4 space characters in long

PUB ClearScreen( ForeClr, BackClr ) | wdClr
' This clears the whole screen and sets all rows to the given colours
' ForeClr and BackClr are best represented as quaternary numbers (base 4)
' - these are represented as %%RGB where there are 4 levels for each ( R, G, B)
' - thus entering %%003 is brightest Green

  wdClr := BackClr << 10 + ForeClr << 2 
  LONGFILL( @scrn, $20202020, VGACOLS*VGAROWS/4 )   '4 space characters in long
  WORDFILL( @colors, wdClr, VGAROWS )


PUB SetLineColor( line, ForeClr, BackClr ) | wdClr
' This sets a single row to the given colours
' ForeClr and BackClr are best represented as quaternary numbers (base 4)
' - these are represented as %%RGB where there are 4 levels for each ( R, G, B)
' - thus entering %%003 is brightest Green

  if line < VGAROWS
    wdClr := BackClr << 10 + ForeClr << 2 
    colors[line] := wdClr



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