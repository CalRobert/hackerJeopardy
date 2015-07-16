''***********************************/*********
''* VGA High-Res Text UI Elements Demo v1.2   *
''*                                           *
''* File: GUIDemo.spin                        *
''* Author: Allen Marincak                    *
''* Copyright (c) 2009 Allen Marincak.        *
''* See end of file for terms of use.         *
''*                                           *
''* Parts are from a demo by Chip Gracey      *
''* Copyright (c) 2006 Parallax, Inc.         *
''* Under the same MIT license                *
''* ( see end of file )                       *
''*********************************************
'
' Notes on the VGA High Res Driver from Chip Gracey's Demo program.
' ----------------------------------------------------------------------------
'
' 3 June 2006
'
' This program (a quick piece of junk) demonstrates the VGA_HIRES_TEXT
' object. It is meant for use on the Propeller Demo Board Rev C. You can
' plug in a mouse for screen action. The mouse driver has been upgraded
' to provided bounded mouse coordinates. This makes constrained and
' scaled mouse movement mindless.
'
' The VGA_HIRES_TEXT went through much metamorphosis before completion.
' Initially, it ran on five COGs! I thought this was a miracle, since I
' didn't think we'd be able to get such high-res displays on the current
' Propeller chip. It used four COGs to build scan lines, and a fifth COG
' to display them. I kept looking at the problem and realized that it
' all came down to how little monkeying could be done with the data in
' order to display it. The scan line building was reorganized so that a
' single RDLONG picks up four lines worth of pixels for a character, and
' then buffers them within the COG, to later output them with back-to-
' back 'WAITVID color,pixels' and 'SHR pixels,#8' instruction sequences.
' This was so much faster that only two COGs were required for the job!
' They had to be synchronized so that they could step seamlessly into
' eachother's shoes as they traded the tasks of building scan lines and
' then displaying them. Anyway, it all came together nicely.

' Note that the driver has different VGA mode settings which you can de-
' comment and try. Also, the driver contains its own font. You will see
' the character set printed out when you run the program. There are some
' characters within the font that provide quarter-character-cell block
' pixels (for 128x64 characters, you can get 256x128 'pixels'). They can
' be used for graphing or crude picture drawing, where text can be inter-
' mingled.
'
' If you have a 15" LCD monitor, you must see the 1024x768 mode on it.
' At least on my little Acer AL1511 monitor, every pixel locks perfectly.
'
'-----------------------------------------------------------------------------
'
' Allen Marincak Feb 2009 Demo program Notes
'
' Chip states above that this demo is for use on the Propeller Demo Board. It
' will however work on any Propeller board with VGA and Mouse driver
' functionality.
'
' The info above was from the VGA_HiRes_Text demo program Chip Gracey wrote.
' There is nothing of consequence left here of that file but the VGA Driver
' driver itself remains intact. *This* demo is setup to show how to use some
' very simple text based graphical user interface elements written for the VGA
' HiRes Text mode. It is an ultra trivial implementation, with virtually no
' error checking so heads up! I did this on purpose to keep it lean. After the
' VGA driver uses some 6K to 10K bytes of memory and 2 cogs to display text I
' did not want to use up most of the rest of the memory with a boatload of
' error checking and a fancier UI on its own COG. I opted to leave as much
' memory as possible for applications that could benefit from cheap and simple
' buttons, menus, text panels and such. Especially since one needs the Mouse
' and Keyboard drivers as well, each of these take up 1 more COG. After loading
' those drivers and creating 10 or so UI elements you will have 2/3 to 1/2 of
' available memory left for your application (depending on VGA Resolution
' desired, I tend to use 800x600 as a good compromise between memory and real
' estate).
'
' There are several UI elements implemented, you stitch together what you need
' and lay it out how you want to use it. There are 9 objects (well 8, the Radio
' Button and Check Box objects are both from the RadioCheck.spin object), and
' some glue functions in the package (in GUIBase.spin). The UI elements are
' rudimentary and lean but provide adequate funtionality for many control and
' monitoring applications. I did not implement repositioning the items, any
' buffering of data in text boxes, pop-up windows or drop down lists, etc.
' These would just use up more memory and I was after a simple light-weight
' (thereby static) UI to provide simple control and feedback for some of my
' projects.
'
'
'   SimpleBox.spin
'     - draws boxes in the area specified, with or without a "title bar"
'     - useful to visually group and organize other control
'
'   RadioCheck.spin
'     - creates Check Box and Radio Button controls
'
'   TextBox.spin
'     - creates simple text windows controls that are line based.
'     - truncates or wraps lines into the window pane
'     - optional (but useful) titlebar avaiable
'
'   MenuItem.spin
'     - simple text "button" that to create a rudimentary menubar.
'
'   PushButton.spin
'     - creates a straightforward pushbutton
'
'   InputField.spin
'     - creates a one line input field with a caption / title. There is only
'       simple editing via backspace.
'     - keyboard input focus can be switched between controls on the fly with
'       mouse click
'
'   SpinBox.spin
'     - created straight forward spin button controls
'
'   StatusLamp.spin
'     - a simple annunciator 'lamp' for condition feedback
'
'   GUIBase.spin
'     - This is actually the main interface to the GUI objects
'     - you call functions here, not in the object files themselves
'     - GUI initialization and processing is done with functions here
'           - Init() starts VGA, Mouse, and Keyboard drivers and initializes
'                    data structures used by the UI
'           - ProcessUI() manages the UI infrastructure you must call this in
'                         your main loop regularly for a responsive UI. It
'                         returns ID of elements that require actionm (i.e.
'                         the mouse was clicked on a Push Button, etc).
'
'   Memory requirements with UI
'     - 1/3 to 1/2 of RAM depending on VGA resolution
'
'   COGS used
'     - the UI does not use a new COG it runs out of the main app's COG.
'     - 2 COGS for the High Res VGA Text driver
'     - 1 COG for the Mouse Driver
'     - 1 COG for the Keyboard Driver (optional, for Input Field Object only)
'
'-----------------------------------------------------------------------------

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
  ' UI element objects  YOU NEED THIS
  '---------------------------------------------------------------------------
  GUI           : "GUIBase"             'starts VGA, Mouse, & Keyboard drivers

  '---------------------------------------------------------------------------
  ' Auxiliary objects   (these are just used in the demo app only)
  '---------------------------------------------------------------------------
  TMRS          : "Timer"
  NUMS          : "simple_numbers"


VAR
  '---------------------------------------------------------------------------
  ' UI element IDs  YOU MUST HAVE THESE to remember the GUI ID's (guid) of the
  '                 elements you create. In this demo APP there are 29 items,
  '                 your application will have more or fewer (as required).
  '                 These are returned by the element Init() calls
  '                     (  i.e.   CHKB1 := GUI.CHKBInit(..)     )
  '---------------------------------------------------------------------------
  byte  CHKB1           
  byte  CHKB2
  byte  CHKB3           
  byte  CHKB4 
  byte  RADB1
  byte  RADB2
  byte  RADB3
  byte  RADB4
  byte  RADB5
  byte  RADB6
  byte  TBOX1
  byte  TBOX2
  byte  TBOX3  
  byte  MENU1
  byte  MENU2
  byte  MENU3
  byte  MENU4
  byte  MENU5
  byte  MENU6  
  byte  INPF1
  byte  INPF2
  byte  INPF3
  byte  PUSH1
  byte  PUSH2
  byte  PUSH3
  byte  STAT1
  byte  STAT2
  byte  SPIN1
  byte  SPIN2

  '---------------------------------------------------------------------------
  ' Screen Geometry  returned by call to GUI.Init() (may be useful)
  '---------------------------------------------------------------------------
  byte  vga_rows, vga_cols
   
  '---------------------------------------------------------------------------
  ' variables used by local main loop processing, not required by library
  ' functions. You can get rid of these when creating your own app.
  '---------------------------------------------------------------------------
  long  cnt1                'line counter for textbox 1
  long  cnt2                'line counter for textbox 2
  long  clrCnt              'clear textbox counter
  long  random              'random number seed
  long  logging             'logging flag
  byte  strBuf[36]
  byte  strBuf2[64]

  
PUB start | gx, tmr1, tmr2, idx, str, tmp

  '---------------------------------------------------------------------------
  'Some houskeeping ... timers and "logging" status
  'This TIMER object started here is used for this demo only. It is used to
  'periodically trigger printing to text boxes to simulate "live text" comming
  'in. It is not needed by the UI stuff and you don't need it in your program
  'unless you want a timer object to do timed activity. Note that it uses a
  'separate COG (so it is not cheap).
  '---------------------------------------------------------------------------
  TMRS.start( 10 )                      'start timer object (1/10 sec timer)
  tmr1 := TMRS.register                 'register 2 timers
  tmr2 := TMRS.register

  logging := 1                          'logging is on to start


  '---------------------------------------------------------------------------
  ' Create the UI
  '---------------------------------------------------------------------------
  CreateUI

  
  '---------------------------------------------------------------------------
  'some final non UI related houskeeping ...
  '---------------------------------------------------------------------------
  TMRS.set( tmr1, 10 )                  'start 1 second timeout
  TMRS.set( tmr2, 17 )                  'start 1.7 second timeout


  '---------------------------------------------------------------------------
  ' Everything is setup, now the MAIN LOOP begins ...
  '---------------------------------------------------------------------------
  repeat
    gx := GUI.ProcessUI     'process the UI

    case gx     'handle GUI Events ( Mouse click or Enter Key in Input Field )
    
      CHKB1:  UserDoSomethingFunction( gx )
                 
      CHKB2:  UserDoSomethingFunction( gx )
      
      CHKB3:  UserDoSomethingFunction( gx )
                 
      CHKB4:  UserDoSomethingFunction( gx )
       
      RADB1:  UserDoSomethingFunction( gx )
      
      RADB2:  UserDoSomethingFunction( gx )
      
      RADB3:  UserDoSomethingFunction( gx )
      
      RADB4:  UserDoSomethingFunction( gx )
      
      RADB5:  UserDoSomethingFunction( gx )
      
      RADB6:  UserDoSomethingFunction( gx )
      
      MENU1:  DoMenu1Action
      
      MENU2:  DoMenu2Action
      
      MENU3:  DoMenu3Action
      
      MENU4:  DoMenu4Action
      
      MENU5:  DoMenu5Action
      
      MENU6:  DoMenu6Action
      
      PUSH1:  UserDoSomethingFunction( gx )
      
      PUSH2:  UserDoSomethingFunction( gx )
      
      PUSH3:  UserDoSomethingFunction( gx )
      
      SPIN1:  UserDoSomethingFunction( gx )
      
      SPIN2:  UserDoSomethingFunction( gx )

      INPF1:  DoInputFieldAction( INPF1 )

      INPF2:  DoInputFieldAction( INPF2 )
      
      INPF3:  DoInputFieldAction( INPF3 )
      

    '----------------------------------------------------------------------
    'user application code goes here or after the ProcessUI call (but still
    'within the REPEAT loop!).
    '----------------------------------------------------------------------
    idx := GUI.GetMouseXY
    GUI.PrintStr( vga_rows-1, 15, NUMS.decf( idx >> 8,  2 ), 0 )
    GUI.PrintStr( vga_rows-1, 20, NUMS.decf( idx & $FF, 2 ), 0 )
    
    if TMRS.isClr( tmr2 )       'if timer 2 expired write line text into textbox 2
      TMRS.set( tmr2, 17 )
      cnt2++
      bytemove( @strBuf, string( "Text # " ), 7 )
      str := NUMS.dec( cnt2 )
      tmp := strsize( str ) + 1
      bytemove( @strBuf[7], str, tmp )
      GUI.TBOXPrint( TBOX2, @strBuf, 0 )
      
    if logging == 1
      if TMRS.isClr( tmr1 )     'if timer 1 expired write line text into textbox 1
        TMRS.set( tmr1, 10 )
        cnt1++
        bytemove( @strBuf, string( "This is line number " ), 20 )
        str := NUMS.dec( cnt1 )
        tmp := strsize( str ) + 1
        bytemove( @strBuf[20], str, tmp )
        GUI.TBOXPrint( TBOX1, @strBuf, 0 )



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
  GUI.ClearScreen( %%020, %%000 )               'green on black each is %%RGB 4 levels per R-G-B
  GUI.SetLineColor( 0, %%220, %%000 )           'Menu Area colour Line 1
  GUI.SetLineColor( 1, %%220, %%000 )           'Menu Area colour Line 2
  GUI.SetLineColor( 2, %%220, %%000 )           'Menu Area colour Line 3

  repeat tmp from vga_rows-15 to vga_rows-2
    GUI.SetLineColor( tmp, %%111, %%000 )       'Console Window colour
  
  GUI.SetLineColor(vga_rows-1,%%222,%%111)      'Status Line colour


  '---------------------------------------------------------------------------
  'put up some menu items                               
  '---------------------------------------------------------------------------
  GUI.SBOXInit( 0,  0, vga_cols, 3, 0 )         'menu group box
  MENU1 := GUI.MENUInit(1, 3,string(" Open Port  ")) 'Menu Items setup
  MENU2 := GUI.MENUInit(1,19,string("Stop Logging"))
  MENU3 := GUI.MENUInit(1,35,string("New Text Box"))
  MENU4 := GUI.MENUInit(1,51,string("Chk Battery "))
  MENU5 := GUI.MENUInit(1,67,string("Read Sensors"))
  MENU6 := GUI.MENUInit(1,83,string(" Clear Log  "))
  GUI.MENUSetStatus( MENU2, logging )


  '---------------------------------------------------------------------------
  'put up some check boxes
  '---------------------------------------------------------------------------
  GUI.SBOXInit( 11, 4, 18,  8, string("Terminal")) 'checkbox group box
  CHKB1 := GUI.CHKBInit( 14, 6, 12, string( "7-bit ASCII" ) )
  CHKB2 := GUI.CHKBInit( 15, 6, 12, string( "Show Cursor" ) )
  CHKB3 := GUI.CHKBInit( 16, 6, 12, string( "Local Echo" ) )
  CHKB4 := GUI.CHKBInit( 17, 6, 12, string( "Append LF" ) )
  GUI.CHKBSelect( CHKB3, 1 )   'select this one as the group's startup default

    
  '---------------------------------------------------------------------------
  'put up some radio buttons
  '---------------------------------------------------------------------------
  GUI.SBOXInit( 20, 4, 18, 10, string("Baud Rate")) 'radio button group box
  RADB1 := GUI.RADBInit( 23, 6, 11, string( "115200" ), 0 )
  RADB2 := GUI.RADBInit( 24, 6, 11, string( "57600 " ), 0 )
  RADB3 := GUI.RADBInit( 25, 6, 11, string( "19200 " ), 0 )
  RADB4 := GUI.RADBInit( 26, 6, 11, string( "9600 " ), 0 )
  RADB5 := GUI.RADBInit( 27, 6, 11, string( "4800 " ), 0 )
  RADB6 := GUI.RADBInit( 28, 6, 11, string( "1200 " ), 0 )
  GUI.RADBSelect( RADB4, 1 )   'select this one as the group's startup default


  '---------------------------------------------------------------------------
  'put up some status lamps
  '---------------------------------------------------------------------------
  GUI.SBOXInit( 4,4,18,6,string("Status") )     'status lamp group box
  STAT1 := GUI.STATInit( 7,6, 14, string( "Logging" ) )
  STAT2 := GUI.STATInit( 8,6, 14, string( "   Port" ) )
  GUI.STATSet( STAT1, 1, string("ON") )
  GUI.STATSet( STAT2, 0, string("OFF") )


  '---------------------------------------------------------------------------
  'put up some text boxes, one without a title
  '---------------------------------------------------------------------------
  TBOX1 := GUI.TBOXInit( 4,28,36,26,1,string("Logging Window") )
  TBOX2 := GUI.TBOXInit(11,72,20,19,1,0 )
  TBOX3 := GUI.TBOXInit(vga_rows-15,0,vga_cols,12,1,string("Console Window") )
  cnt1 := 0                             'line counter for textbox 1
  cnt2 := 0                             'line counter for textbox 2
  clrCnt := 0                           'clear textbox counter
  random := 0                           'random number seed

  
  '---------------------------------------------------------------------------
  'put up a couple of input fields
  '---------------------------------------------------------------------------
  INPF1 := GUI.INPFInit(  4, 70, 24, 0, string("Speed") )
  INPF2 := GUI.INPFInit( 31,  4, 60, 0, string("Message") )
  INPF3 := GUI.INPFInit( vga_rows-4, 0, VGA_cols, 1, string("Command") )
  GUI.INPFSelect( INPF3, 1 )
  
  '---------------------------------------------------------------------------
  'put up some push buttons
  '---------------------------------------------------------------------------
  PUSH1 := GUI.PUSHInit( 7, 70, string( "Slower" ) )
  PUSH2 := GUI.PUSHInit( 7, 78, string( " Stop " ) )
  PUSH3 := GUI.PUSHInit( 7, 86, string( "Faster" ) )


  '---------------------------------------------------------------------------
  'put up some spin buttons
  '---------------------------------------------------------------------------
  SPIN1 := GUI.SPINInit( 31, 68, 16, 0,  4, @SpinDat0 ) 'languages
  SPIN2 := GUI.SPINInit( 31, 86, 12, 1, 10, @SpinDat1 ) 'log scale
 

  '---------------------------------------------------------------------------
  'Put something in the status bar (just the mouse coordinates in this demo)
  '---------------------------------------------------------------------------
  GUI.PrintStr(vga_rows-1,0,string( "Status Line: X=xx Y=xx" ), 0 )


PRI UserDoSomethingFunction( val )      ' - USER ACTION FUNCTION
'this is a dummy ... in a real app the user would have one of these for each
'UI action that required some activity. For this Demo where the user would
'normally call their own function I just call this dummy placeholder instead.
  GUI.TBOXPrint( TBOX3, string( "Normally a user function would be called." ), 0 )
  return val


PRI DoMenu1Action | mStat

  mStat := GUI.MENUGetStatus( MENU1 )         'get current user status of menu item

  if mStat == 0
    GUI.TBOXPrint( TBOX3, string( "Opened port."), 0 )  'announce activity to console window
    GUI.MENUSetText( MENU1, string( "Close Port" ) )    'change the menu item text
    GUI.MENUSetStatus( MENU1, 1 )                       'set new status of the menu item
    GUI.STATSet( STAT2, 1, string("OPEN") )             'set status lamp ON
  else
    GUI.TBOXPrint( TBOX3, string( "Closed port." ), 0 ) 'announce activity to console window
    GUI.MENUSetText( MENU1, string( " Open Port" ) )    'change the menu item text
    GUI.MENUSetStatus( MENU1, 0 )                       'set new status of the menu item
    GUI.STATSet( STAT2, 0, string("OFF") )              'set status lamp OFF


PRI DoMenu2Action | mStat
 
  mStat := GUI.MENUGetStatus( MENU2 )         'get current user status of menu item

  if mStat == 0
    GUI.TBOXPrint( TBOX3, string("Started Logging."),0) 'announce activity to console window
    GUI.MENUSetText( MENU2, string( "Stop Logging" ))   'change the menu item text
    GUI.MENUSetStatus( MENU2, 1 )                       'set new status of the menu item
    GUI.STATSet( STAT1, 1, string("ON") )               'set status lamp ON
    logging := 1
  else
    GUI.TBOXPrint(TBOX3,string("Stopped logging." ),0)  'announce activity to console window
    GUI.MENUSetText( MENU2, string( "  Log Data  " ) )  'change the menu item text
    GUI.MENUSetStatus( MENU2, 0 )                       'set new status of the menu item
    GUI.STATSet( STAT1, 0, string("OFF") )              'set status lamp OFF
    logging := 0


PRI DoMenu3Action
  GUI.TBOXPrint( TBOX1, @longstring, 0 )                
  GUI.TBOXPrint( TBOX2, @longstring, 0 )
  GUI.SBOXInit( 12, 36, 14, 10, string("New Text Box")) 'create new simple box


PRI DoMenu4Action | rnd
  rnd := ?random / 100_000_000
  rnd *= rnd                                            'formulate a random number
  bytemove( @strbuf, string( "Battery = 9." ), 12 )
  bytemove( @strbuf[12], NUMS.decx( rnd, 3 ), 3 )
  bytemove( @strbuf[15], string( " vdc." ), 4 )
  strbuf[19] := 0
  GUI.TBOXPrint(TBOX3, @strbuf, 0 )                     'display 'voltage' in console window


PRI DoMenu5Action
  GUI.TBOXPrint(TBOX3,string("Sensors are not ready."),0) 'announce activity to console window


PRI DoMenu6Action | tmp
  GUI.TBOXClear( TBOX1 )                                'ACTION: clear the text box
  bytemove(@strBuf,string("Logging Window  Cleared "),24) 'create new text box title
  clrCnt++
  bytemove(@strBuf[24],NUMS.decf(clrCnt,3),3)           'tack on cleared count
  tmp := 16
  repeat while strBuf[tmp] <> 0                         'make cleared count text inverted
    strBuf[tmp++] += 128
  GUI.TBOXTitle( TBOX1, @strBuf )                       'put new title in text box


PRI DoInputFieldAction( guid )
  GUI.INPFGetString( guid, @strBuf2 )
  GUI.TBOXPrint(TBOX3, @strbuf2, 0 )                    'display 'voltage' in console window
  


DAT

longstring    byte  13,10,"This is a long string. It will take up ",13,10,"several lines. The leading and trailing CRLF should be stripped off but not the one inside the string.",13,10,0


'-----------------------------------------------------------------------------
'Data for the spin buttons. Text type spin buttons will have an array of null
'terminated stings here. Numeric type spin buttons will have an array of long
'values.
'-----------------------------------------------------------------------------
SpinDat0      byte "English",0
              byte "French",0
              byte "Spanish", 0
              byte "Slovak", 0

SpinDat1      long 1,2,5,10,20,50,100,200,500,1000
    
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