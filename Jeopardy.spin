''***********************************/*********
''* Hacker Jeopardy v 0.1   *
''*                                           *
''* File: Jeopardy.spin                       *
''* Author: Robert Lawson                     *
''* Copyright (c) 2015 Robert Lawson.        *
''* See end of file for terms of use.         *
''*                                           *
''* Parts are from a demo by Chip Gracey      *
''* Copyright (c) 2006 Parallax, Inc.         *
''* Under the same MIT license                *
''* ( see end of file )                       *
''*********************************************
''
''
''
CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  vga_base          = 16        'VGA - VSync
  
  mouse_dat         = 24        'MOUSE data
  mouse_clk         = 25        'MOUSE clock
  keyboard_dat      = 26        'KEYBOARD data
  keyboard_clk      = 27        'KEYBOARD clock  


OBJ
  '---------------------------------------------------------------------------
  ' UI element objects  
  '---------------------------------------------------------------------------
  GUI           : "GUIBase"             'starts VGA, Mouse, & Keyboard drivers


VAR
  '---------------------------------------------------------------------------
  ' UI element IDs  YOU MUST HAVE THESE to remember the GUI ID's (guid) of the
  '                 elements you create. In this demo APP there are 29 items,
  '                 your application will have more or fewer (as required).
  '                 These are returned by the element Init() calls
  '                     (  i.e.   CHKB1 := GUI.CHKBInit(..)     )
  '---------------------------------------------------------------------------
  byte  	TBOX1
  byte   TBOX2
  byte   TBOX3
  byte   TBOX4
  byte   TBOX5
    
'  long  cnt1                'line counter for textbox 1
'  long  cnt2                'line counter for textbox 2
                            '
                            '
  long  clrCnt              'clear textbox counter
  long  random              'random number seed
  
    '---------------------------------------------------------------------------
  ' Screen Geometry  returned by call to GUI.Init() (may be useful)
  '---------------------------------------------------------------------------
  byte  vga_rows, vga_cols	
  
  
PUB start | gx, tmr1, tmr2, idx, str, tmp

  'logging := 1                          'logging is on to start


  '---------------------------------------------------------------------------
  ' Create the UI
  '---------------------------------------------------------------------------
  CreateUI

  
  
CON   ''=====< START OF UI HELPER FUNTIONS >==================================
PRI CreateUI | tmp
'You create this function to create your GUI.
'
'This function is called during startup to create and position the UI elements
'that you will use. The total number of UI elements of each type must be
'declared in the OBJ section (i.e. if you need 5 pushbuttons, delcare an array
'of 5 pushbutton objects).

  '---------------------------------------------------------------------------
  'Initialize GUI, starts VGA, Mouse, and Keyboard Drivers
  '
  'YOU MUST DO THIS FIRST   (saving screen geometry is optional)
  '---------------------------------------------------------------------------
  tmp := GUI.Init(vga_base, mouse_dat, mouse_clk, keyboard_dat, keyboard_clk )
  vga_rows := ( tmp & $0000FF00 ) >> 8
  vga_cols := tmp & $000000FF

  
  '---------------------------------------------------------------------------
  'setup screen colours
  '---------------------------------------------------------------------------
  GUI.ClearScreen( %%333, %%001 )               'white on blue each is %%RGB 4 levels per R-G-B
'  GUI.SetLineColor( 0, %%220, %%000 )           'Menu Area colour Line 1
'  GUI.SetLineColor( 1, %%220, %%000 )           'Menu Area colour Line 2
'  GUI.SetLineColor( 2, %%220, %%000 )           'Menu Area colour Line 3

'  repeat tmp from vga_rows-15 to vga_rows-2
'    GUI.SetLineColor( tmp, %%111, %%000 )       'Console Window colour
  
'  GUI.SetLineColor(vga_rows-1,%%222,%%111)      'Status Line colour




  '---------------------------------------------------------------------------
  'put up some text boxes, one without a title
  '---------------------------------------------------------------------------
   'row column width height wrap title
  TBOX1 := GUI.TBOXInit(0,0,15,36,0,string("Potent"))
  TBOX2 := GUI.TBOXInit(0,17,15,36,0,string("Port Math" ))
  TBOX3 := GUI.TBOXInit(0,34,15,36,0,string("History" ))
  TBOX4 := GUI.TBOXInit(0,51,15,36,0,string("Hacks" ))
'  TBOX5 := GUI.TBOXInit(0,75,15,36,1,string("G-Man" ))
'  cnt1 := 0                             'line counter for textbox 1
'  cnt2 := 0                             'line counter for textbox 2
  clrCnt := 0                           'clear textbox counter
  random := 0                           'random number seed

  