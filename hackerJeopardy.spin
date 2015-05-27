'DEFCON 2012 Badge Example
'Simple program shows how to use the DEFCON 2012 Badge to drive a VGA display,
'and interface with a mouse and a keyboard

CON

  'Propeller clock mode declarations
  _xinfreq = 5_000_000          'Timing crystal frequency, in Hz
  _clkmode = xtal1 + pll16x     'Use crystal type 1, with the 16x PLL to wind the clock up to 80 MHz

  'Propeller pin constant definitions.  Works with any Defcon 20 board.
  VGA_BASE_PIN  = 16
  
  MOUSE_DATA_PIN     = 24
  MOUSE_CLOCK_PIN    = 25
  KEYBOARD_DATA_PIN  = 26 
  KEYBOARD_CLOCK_PIN = 27

  'screen character size definitions
  COLS = vga#COLS               'value is actually defined in the 
  ROWS = vga#ROWS               'VGA_Text_Defcon object's constant section

  'bitwise map for the mouse buttons
  MOUSE_LEFT    = 1<<0
  MOUSE_RIGHT   = 1<<1
  MOUSE_CENTER  = 1<<2
  MOUSE_L_SIDE  = 1<<3
  MOUSE_R_SIDE  = 1<<4

  'constant definitions for VGA screen manipulation functionality
  VGA_CLS       = $00           'clear screen
  VGA_HOME      = $01           'home
  VGA_BACKSPACE = $08           'backspace
  VGA_TAB       = $09           'tab (8 spaces per)
  VGA_SET_X     = $0A           'set X position (X follows)
  VGA_SET_Y     = $0B           'set Y position (Y follows)
  VGA_SET_COLOR = $0C           'set color (color follows)
  VGA_CR        = $0D           'carriage return

OBJ

  'object declarations
  VGA     : "VGA_Text_Defcon.spin"
  Mouse   : "Mouse.spin"
  Keyboard: "Keyboard.spin"
  'Quiz    : "Quiz.spin"

VAR

  long xPos           'raw X value for the mouse
  long yPos           'raw Y value for the mouse
  long zPos           'raw Z value for the mouse wheel
  byte mouse_buttons  'bitwise variable, holds which mouse buttons are pressed

  byte questionAddr   'hold address where question is stored
  long kb_x, old_kb_x           'cursor (from kb) x position
  long kb_y, old_kb_y           'y position
  long questionCat    ' category index (0,1,2,etc.)
  long questionAmount ' amount (0, 1, 2)
  
  long cursorX        'scale and limited mouse cursor position
  long cursorY

  long keyVal         'variable to hold the last keyboard keypress value
  long questions[4]
  
PRI getQuestionText(category, amount)

  VGA.Out(VGA_SET_X)
  VGA.Out(0)
  VGA.Out(VGA_SET_Y)
  VGA.Out(12)

  if category == 0

    case amount
    'History questions
        'Grace Hopper
        0: VGA.Str(string("I wrote the first compiler                                                           "))

       'Alan Turing
        1: VGA.Str(string("I was chemically castrated despite helping the allies in WWII                        "))

        
        2: VGA.str(string("These MS founders were at a strip club while Paul Allen was making their first deal?"))

    'Gottfried Liebnitz
        3: VGA.str(string("I invented the first four function calculator                                        "))
    
        '2004
        4: VGA.str(string("In this year Firefox 1.0 was released                                                 "))        


  if category == 1
    'Port Math
     case amount 
       '443
       0: VGA.str(string("https                                                                                 "))
    
       '25
       1: VGA.str(string("smtp                                                                                "))

       '53
       2: VGA.str(string("DNS                                                                                "))
       
       '70
       3: VGA.str(string("gopher                                                                                "))
       
       '2379
       4: VGA.str(string("etcd client                                                                                 "))
       
  if category == 2
    case amount
    'Carmen Ortiz
      0 : VGA.Str(string("I was Aaron Swartz' prosecutor before his suicide                                 "))
      1 : VGA.Str(string("This country has the largest number of elected Pirate Party members                 "))
      2 : VGA.Str(string("This act makes any unauthorized access a felony                                   "))
      3 : VGA.Str(string("I was the first US president to send an email                                    "))
      4 : VGA.Str(string("This country now offers 'e-residency' to people from anywhere in the world         "))

  if category == 3
    case amount
      0 : VGA.Str(string("Need to add questions!!                                                             "))
      1 : VGA.Str(string("Need to add questions!!                                                             "))
      2 : VGA.Str(string("Need to add questions!!                                                             "))
      3 : VGA.Str(string("Need to add questions!!                                                             "))
      4 : VGA.Str(string("Need to add questions!!                                                             "))

  if category == 4
    case amount
      0 : VGA.Str(string("Need to add questions!!                                                             "))
      1 : VGA.Str(string("Need to add questions!!                                                             "))
      2 : VGA.Str(string("Need to add questions!!                                                             "))
      3 : VGA.Str(string("Need to add questions!!                                                             "))
      4 : VGA.Str(string("Need to add questions!!                                                             "))


PRI resetHighlights | x, i

  repeat x from 0 to 15
    VGA.out(VGA_SET_X)
    VGA.out(x)
    repeat i from 0 to 15
      VGA.out(VGA_SET_Y)
      VGA.out(i)
      
      VGA.out(VGA_SET_COLOR)
      VGA.out(0)
      VGA.replace(x,i,VGA.GetChar(x,i))


PRI highlightBox(x,y, oldKbX, oldKbY)

  'resetHighlights
  'Need to handle un-highlighting old boxes
{{
  VGA.out(VGA_SET_X)
  VGA.out(5)
  VGA.out(VGA_SET_Y)
  VGA.out(10)
  VGA.str(string("     "))
  VGA.dec(oldKbX)
  
  VGA.out(VGA_SET_X)
  VGA.out(10)
  VGA.out(VGA_SET_Y)
  VGA.out(12)
  VGA.str(string("     "))
  VGA.dec(oldKbY)
  }}
  VGA.out(VGA_SET_X)
  VGA.out(oldKbX)
  VGA.out(VGA_SET_Y)
  VGA.out(oldKbY)
  VGA.str(string("$"))
  
{{
  VGA.Out(VGA_SET_COLOR)
  VGA.out(0)
  VGA.str(string("$"))


  VGA.out(VGA_SET_X)
  VGA.out(2)
  VGA.out(VGA_SET_Y)
  VGA.out(12)
  VGA.dec(oldKbX)

  VGA.out(VGA_SET_Y)
  VGA.out(14)
  VGA.dec(oldKbY)
}}
  'Now highlight new ones
  VGA.out(VGA_SET_X)
  VGA.out(x)
  VGA.out(VGA_SET_Y)
  VGA.out(y)
  'Vga.str(string("X"))
  
  VGA.Out(VGA_SET_COLOR)
  VGA.out(2)
  VGA.str(string("$"))
    
PRI printQuestion(question)
  'cruft
  VGA.Out(VGA_SET_X)
  VGA.Out(0)
  VGA.Out(VGA_SET_Y)
  VGA.Out(11)
  VGA.Str(question)

'PRI drawBoard
'   ' Draw Board
'   repeat i from 1 to 5
'      repeat 5
'        VGA.str(string("$"))
'        VGA.dec(i)
'        VGA.str(string("00  " ))
'    VGA.str(string(" ", 13))
  
PUB Go | i, oldChar, oldX, oldY  

    
  'Start drivers for the various software peripherals in this application.

  VGA.Start(VGA_BASE_PIN)

  Mouse.Start(MOUSE_DATA_PIN, MOUSE_CLOCK_PIN)
  Mouse.Bound_limits(0, 0, 0, cols - 1, rows - 2, 0)    'set cursor limits
  Mouse.Bound_scales(15, -15, 0)                        'scale the raw values to make mouse actions smoother
  
  Keyboard.Start(KEYBOARD_DATA_PIN, KEYBOARD_CLOCK_PIN)                                      

   ' set init kb position and categories/amounts
  kb_x := 0
  kb_y := 0
  old_kb_x := 0
  old_kb_y := 0
  questionCat := 0
  questionAmount := 0


   ' Draw Board
   repeat i from 1 to 5
 
     repeat 5
        VGA.str(string("$"))
        VGA.dec(i)
        VGA.str(string("00  " ))
    VGA.str(string(" ", 13))

  'initialize the oldChar and cursor values
  cursorX := cursorY := 0
  oldChar := VGA.GetChar(cursorX, cursorY)

  'main loop
  repeat
    VGA.Out(VGA_SET_COLOR)      'reset the drawing color
    VGA.Out(0)

    'get and print the last keyboard key pressed                                        
    keyVal := Keyboard.Key
    VGA.Out(VGA_SET_X)
    VGA.Out(20)
    VGA.Out(VGA_SET_Y)
    VGA.Out(7)    

    if keyVal <> 0
{{
      VGA.Str(string("0x"))  
      VGA.Hex(keyVal,3)
      VGA.str(string("dec: "))
      VGA.dec(keyVal)
      VGA.Out(" ")
      VGA.Out(keyval & $FF)      
}} 
      
      if keyVal == 13
        getQuestionText(questionCat, questionAmount)
      
      if keyVal == 192 and kb_x > 0  'left
        'dollar amounts are six characters wide
        old_kb_x := kb_x
        old_kb_y := kb_y
        kb_x := kb_x - 6
        questionCat := questionCat - 1
        
      if keyVal == 193 and kb_x < 24  'right
        old_kb_x := kb_x
        old_kb_y := kb_y
        kb_x := kb_x + 6
        questionCat := questionCat + 1
        
      if keyVal == 194 and kb_y > 0  'up
        'remember top is 0 and bottom is 16!
        old_kb_x := kb_x
        old_kb_y := kb_y
        kb_y := kb_y - 1
        questionAmount := questionAmount - 1
        
      if keyVal == 195 and kb_y < 4 'down
        old_kb_x := kb_x
        old_kb_y := kb_y
        kb_y := kb_y + 1
        questionAmount := questionAmount + 1

      highlightBox(kb_x, kb_y, old_kb_x, old_kb_y)



{{
    'save the mouse's current x and y postition within the bounds defined at the start of the program
    cursorX := Mouse.Bound_x
    cursorY := Mouse.Bound_y

    'update only when the mouse position or button state has changed
    if oldX <> cursorX or oldY <> cursorY or mouse_buttons <> 0
      VGA.Replace(oldX, oldY, oldChar)                  'replace the last old characer at the appropriate position
      oldChar := VGA.GetChar(cursorX, cursorY)          'save the current character as the old character to be replaced later
      oldX := cursorX                                   'make the current cursor position the old position
      oldY := cursorY

      'set the position for the new cursor
      VGA.Out(VGA_SET_X)                                
      VGA.Out(cursorX)
      VGA.Out(VGA_SET_Y)
      VGA.Out(cursorY)

      'change the color of the mouse cursor when a mouse button is pressed
      if mouse_buttons & MOUSE_LEFT
        VGA.Out(VGA_SET_COLOR)
        VGA.Out(2)              '<--- These colors are defined in the VGA_Text_Defcon.spin object, at the bottom.
      elseif mouse_buttons & MOUSE_RIGHT
        VGA.Out(VGA_SET_COLOR)
        VGA.Out(5)
      elseif mouse_buttons & MOUSE_CENTER
        VGA.Out(VGA_SET_COLOR)
        VGA.Out(6)

      'print the "dot" cursor character
      VGA.Out($0F)

}}

DAT  
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}    