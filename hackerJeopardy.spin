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


  'terminal
  pst           : "Parallax Serial Terminal"       

VAR
  '---------------------------------------------------------------------------
  ' UI element IDs  YOU MUST HAVE THESE to remember the GUI ID's (guid) of the
  '                 elements you create. In this demo APP there are 29 items,
  '                 your application will have more or fewer (as required).
  '                 These are returned by the element Init() calls
  '                     (  i.e.   CHKB1 := GUI.CHKBInit(..)     )
  '---------------------------------------------------------------------------
  byte  Team1ScoreTBOX
  byte  Team2ScoreTBOX
  byte  Team3ScoreTBOX    
  byte  Cat1TBOX
  byte  Cat2TBOX
  byte  Cat3TBOX
  byte  Cat4TBOX
  byte  Cat5TBOX
  byte  Cat6TBOX
  byte  QUESTMENU[31] '0 is junk so we use indices 1-30
  byte  Question[64]
  byte  Answer[64]
  long  questVal ' Hold the value of the current question
  byte  AnswerBox
  byte buzzerAlert
  byte buzzerTeam
  'byte AnswerBoxCreated
  byte buzzerEligible
  '---------------------------------------------------------------------------
  ' Screen Geometry  returned by call to GUI.Init() (may be useful)
  '---------------------------------------------------------------------------
  byte  vga_rows, vga_cols

  byte  strBuf[36]
  byte  strBuf2[64]
  byte  strBufTmp[128]
  
  byte Team1Increment
  byte Team1Decrement
  byte Team2Increment
  byte Team2Decrement
  byte Team3Increment
  byte Team3Decrement  
  
  long buzzerLine
  long team1Score
  long team2Score
  long team3Score
  
  byte tmr1

PUB start | gx, {tmr1,} tmr2, idx, str, tmp, i

  'debugging - start Terminal"
  pst.Start(115200)
  pst.Str (string("terminal running", 13))
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

  team1Score := 0
  team2Score := 0
  team3Score := 0

  '---------------------------------------------------------------------------
  ' Create the UI
  '---------------------------------------------------------------------------
  CreateUI
  '---------------------------------------------------------------------------
  ' Everything is setup, now the MAIN LOOP begins ...
  '---------------------------------------------------------------------------
  repeat
    gx := GUI.ProcessUI     'process the UI

    case gx 'handle GUI Events ( Mouse click or Enter Key in Input Field )
      -1 : 'do nothing

      0 : GUI.TBOXClear(AnswerBox)'User clicked empty space, handle clear box
          GUI.TBOXClear(buzzerTeam)
          DisableBuzzer
          restoreColors
          'questVal := 0

      -98 : 'b key pressed. Use this after a team gives a wrong answer
          EnableBuzzer

      'QuestMenu[0]: HandleQuestionFunction(gx)
      'gx is the object the user clicked on. This simply turns that in to the 
      'index and passes that to HandleQuestionFunction
       'Given that we already mucked about with the GUIBase object we could've handled this more elegantly.
      'Todo: make this less horrible.
      QuestMenu[1]: HandleQuestionFunction(1)
      QuestMenu[2]: HandleQuestionFunction(2)
      QuestMenu[3]: HandleQuestionFunction(3)
      QuestMenu[4]: HandleQuestionFunction(4)
      QuestMenu[5]: HandleQuestionFunction(5)
      QuestMenu[6]: HandleQuestionFunction(6)
      QuestMenu[7]: HandleQuestionFunction(7)
      QuestMenu[8]: HandleQuestionFunction(8)
      QuestMenu[9]: HandleQuestionFunction(9)
      QuestMenu[10]: HandleQuestionFunction(10)
      QuestMenu[11]: HandleQuestionFunction(11)
      QuestMenu[12]: HandleQuestionFunction(12)
      QuestMenu[13]: HandleQuestionFunction(13)
      QuestMenu[14]: HandleQuestionFunction(14)
      QuestMenu[15]: HandleQuestionFunction(15)
      QuestMenu[16]: HandleQuestionFunction(16)
      QuestMenu[17]: HandleQuestionFunction(17)
      QuestMenu[18]: HandleQuestionFunction(18)
      QuestMenu[19]: HandleQuestionFunction(19)
      QuestMenu[20]: HandleQuestionFunction(20)
      QuestMenu[21]: HandleQuestionFunction(21)
      QuestMenu[22]: HandleQuestionFunction(22)
      QuestMenu[23]: HandleQuestionFunction(23)
      QuestMenu[24]: HandleQuestionFunction(24)
      QuestMenu[25]: HandleQuestionFunction(25)
      QuestMenu[26]: HandleQuestionFunction(26)
      QuestMenu[27]: HandleQuestionFunction(27)
      QuestMenu[28]: HandleQuestionFunction(28)
      QuestMenu[29]: HandleQuestionFunction(29)
      QuestMenu[30]: HandleQuestionFunction(30)

      'maybe shouldn't use space bar considering players presumably have access
      AnswerBox:
        GUI.TBOXClear(AnswerBox)
        GUI.TBOXPrint(AnswerBox, @Answer, 64)

      Team1Decrement: 
        pst.Str(Nums.dec(Team1Decrement))
        Team1Score -= questVal
        GUI.TBOXClear(Team1ScoreTBOX)
        GUI.TBOXPrint(Team1ScoreTBOX, Nums.dec(team1score), 0)
      Team1Increment: Team1Score += questVal
        GUI.TBOXClear(Team1ScoreTBOX)
        GUI.TBOXPrint(Team1ScoreTBOX, Nums.dec(team1score), 0)

      Team2Decrement: Team2Score -= questVal
        GUI.TBOXClear(Team2ScoreTBOX)
        GUI.TBOXPrint(Team2ScoreTBOX, Nums.dec(team2score), 0)
      Team2Increment: Team2Score += questVal
        GUI.TBOXClear(Team2ScoreTBOX)
        GUI.TBOXPrint(Team2ScoreTBOX, Nums.dec(team2score), 0)

      Team3Decrement: 
        Team3Score -= questVal
        GUI.TBOXClear(Team3ScoreTBOX)
        GUI.TBOXPrint(Team3ScoreTBOX, Nums.dec(team3score), 0)
      Team3Increment: 
        Team3Score += questVal
        GUI.TBOXClear(Team3ScoreTBOX)
        GUI.TBOXPrint(Team3ScoreTBOX, Nums.dec(team3score), 0)

      -97, -59, -53:
        gx := -gx 'flip this back to positive
        if buzzerEligible == 1
          HandleBuzzer(gx)
      'other :
      '  pst.str(string("key pressed"))
      '  pst.Str(Nums.dec(gx))

    '----------------------------------------------------------------------
    'user application code goes here or after the ProcessUI call (but still
    'within the REPEAT loop!).
    '----------------------------------------------------------------------


CON   ''=====< START OF UI HELPER FUNCTIONS >==================================
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
  GUI.ClearScreen( %%333, %%003 )               'each is %%RGB 4 levels per R-G-B
  initRectangles
  initScores

PRI RestoreBoard
  GUI.ClearScreen( %%333, %%003 )               'each is %%RGB 4 levels per R-G-B

  initRectangles
  initScores

PRI initRectangles | c, r
  'TODO: Need to accept array indicating which cells to block out
  'Make outline boxes
  repeat c from 0 to 5
    repeat r from 1 to 5
      GUI.SBoxInit(7*r, 16*c,16,6,0)

  'Make prices
  repeat c from 0 to 5
    repeat r from 1 to 5
      QUESTMENU[(c*5)+r] := GUI.MENUInit(2 + 7*r, 5 + 16*c, NUMS.dec(r*100)  )
      '1 indicates available
      GUI.MENUSetStatus(QUESTMENU[(c*5)+r], 1)
      GUI.MENUDrawText(QUESTMENU[(c*5)+r], 0)

  Cat1TBOX := GUI.TBOXInit( 0,0,16,6,1,0)
  Cat2TBOX := GUI.TBOXInit( 0,16,16,6,1,0)
  Cat3TBOX := GUI.TBOXInit( 0,32,16,6,1,0)
  Cat4TBOX := GUI.TBOXInit( 0,48,16,6,1,0)
  Cat5TBOX := GUI.TBOXInit( 0,64,16,6,1,0)
  Cat6TBOX := GUI.TBOXInit( 0,80,16,6,1,0)

  GUI.TBOXPrint( Cat1TBOX, string("Freedom Isn't Free"), 0 )
  GUI.TBOXPrint( Cat2TBOX, string("History"), 0 )
  GUI.TBOXPrint( Cat3TBOX, string("Port Math"), 0 )
  GUI.TBOXPrint( Cat4TBOX, string("Fucking it Up"), 0 )
  GUI.TBOXPrint( Cat5TBOX, string("History"), 0 )
  GUI.TBOXPrint( Cat6TBOX, string("History"), 0 )
  

  AnswerBox := GUI.TBOXInit( 26, 15, 66, 3, 0,0)      'Needs to be two wider than max answer length
  buzzerLine := 5
  buzzerAlert := GUI.TBOXInit(buzzerLine,45,5,3,0,0)
  buzzerTeam := GUI.TBOXInit(33,15,66,3,0,0)
  Team1Decrement := GUI.MENUInit(41,1,string("-"))
  Team1Increment := GUI.MENUInit(41,28,string("+"))

  Team2Decrement := GUI.MENUInit(41,33,string("-"))
  Team2Increment := GUI.MENUInit(41,60,string("+"))

  Team3Decrement := GUI.MENUInit(41,65,string("-"))
  Team3Increment := GUI.MENUInit(41,92,string("+"))
  'GUI.MenuSetColor(Team3Increment, %%300, %%030)


PRI initScores
  Team1ScoreTBOX := GUI.TBOXInit( 41,0,32,6,0,@Team1Name )
  GUI.TBOXPrint(Team1ScoreTBOX, string("0"), 0)
  Team2ScoreTBOX := GUI.TBOXInit( 41,32,32,6,0,@Team2Name )
  GUI.TBOXPrint(Team2ScoreTBOX, string("0"), 0)
  Team3ScoreTBOX := GUI.TBOXInit( 41,64,32,6,0,@Team3Name )
  GUI.TBOXPrint(Team3ScoreTBOX, string("0"), 0)
    
PRI HandleBuzzer(val) | tmp
  'TODO: Check a flag for whether a team can buzz in=
  'a, ; (semicolon), and numpad 5 are 97, 59, and 53

  if buzzerEligible == 1

    case val
      97 : 
           GUI.TBOXPrint(buzzerTeam, @Team1Name, 0)
           'GUI.PrintStr(buzzerRow,30,@Team1Name,0)
           DisableBuzzer
             
      59 : 
           GUI.TBOXPrint(buzzerTeam, @Team2Name, 0)
'          'GUI.PrintStr(buzzerRow,30,@Team2Name,0)
           DisableBuzzer
   
      53 : 
           GUI.TBOXPrint(buzzerTeam, @Team3Name, 0)
           'GUI.PrintStr(buzzerRow,30,@Team3Name,0)
           DisableBuzzer


PRI HighlightQuestion | tmp
  repeat tmp from vga_rows to vga_rows + 2
     GUI.SetLineColor(tmp, %%333, %%003)
  
  
PRI RestoreColors | tmp
    repeat tmp from 0 to vga_rows
      GUI.SetLineColor(tmp, %%333, %%003)


PRI EnableBuzzer
  ifnot buzzerEligible ==1
    GUI.TBOXClear(buzzerAlert)
    GUI.TBOXPrint(buzzerAlert, string("GO!"), 3)
    GUI.SetLineColor(buzzerLine +1, %%333, %%030)
    buzzerEligible := 1


PRI DisableBuzzer
  ifnot buzzerEligible == 0
    GUI.TBOXClear(buzzerAlert)
    GUI.SetLineColor(buzzerLine+1, %%333, %%003)
    buzzerEligible := 0

 
PRI HandleQuestionFunction( val ) | tmp
  '0 status indicates we've already used this question
  'ifnot GUI.MENUGetStatus(QuestMenu[val]) == 0
  'better to make it possible to click this just in case we need to go back to one

  if 1 == 1  
    case val
      'Dumb and simple, just 30 different options
      1: 'Cat 1 $100 question
         questVal := 100
         bytemove(@Question, string("This U.S. attorney prosecuted Aaron Swartz                      "),64)
         bytemove(@Answer,   string("Who is Carmen Ortiz?                                            "),64)
           
      2: 'Cat 1 $200 question
         questVal := 200
         bytemove(@Question, string("This tool for location obfuscation vanished mysteriously in July"), 64)
         bytemove(@Answer,   string("What is ProxyHam?                                               "), 64)
        
      3: questVal := 300
         bytemove(@Question, string("In 2009 this was placed in the Riviera lobby.                   "), 64)
         bytemove(@Answer,   string("What is a fake ATM?                                             "), 64)
        
      4: questVal := 400
         bytemove(@Question, string("Boston officials demanded a 2008 talk on this topic be canceled "), 64)
         bytemove(@Answer,   string("What is subway card hacking?                                    "), 64)
        
      5: questVal := 500
         bytemove(@Question, string("Juniper Networks canceled a talk on this topic in 2009          "), 64)
         bytemove(@Answer,   string("What is ATM hacking?                                            "), 64)
        
      6: 'Cat 2 $100 question
         questVal := 100
         bytemove(@Question, string("Question                                                        "), 64)
         bytemove(@Answer,   string("What is the question?                                           "), 64)
        
      7: questVal := 200
         bytemove(@Question, string("Question                                                        "), 64)
         bytemove(@Answer,   string("What is the question?                                           "), 64)
        
      8: questVal := 300
         bytemove(@Question, string("Question                                                        "), 64)
         bytemove(@Answer,   string("What is the question?                                           "), 64)
        
      9: questVal := 400
         bytemove(@Question, string("Question                                                        "), 64)
         bytemove(@Answer,   string("What is the question?                                           "), 64)
        
      10: questVal := 500
          bytemove(@Question, string("Question                                                        "), 64)
          bytemove(@Answer,   string("What is the question?                                           "), 64)
        

      11: 'Cat 3 $100
          questVal := 100
          bytemove(@Question, string("Question                                                        "), 64)
          bytemove(@Answer,   string("What is the question?                                           "), 64)
        
      12: questVal := 200
          bytemove(@Question, string("Question                                                        "), 64)
          bytemove(@Answer,   string("What is the question?                                           "), 64)
        
      13: questVal := 300
          bytemove(@Question, string("Question                                                        "), 64)
          bytemove(@Answer,   string("What is the question?                                           "), 64)
        
      14: questVal := 400
          bytemove(@Question, string("Question                                                        "), 64)
          bytemove(@Answer,   string("What is the question?                                           "), 64)
        
      15: questVal := 500
          bytemove(@Question, string("Question                                                        "), 64)
          bytemove(@Answer,   string("What is the question?                                           "), 64)
        
        
      16:'Cat 4 $100
          questVal := 100
          bytemove(@Question, string("Question                                                        "), 64)
          bytemove(@Answer,   string("What is the question?                                           "), 64)
        
      17: questVal := 200
          bytemove(@Question, string("Question                                                        "), 64)
          bytemove(@Answer,   string("What is the question?                                           "), 64)
        
      18: questVal := 300
          bytemove(@Question, string("Question                                                        "), 64)
          bytemove(@Answer,   string("What is the question?                                           "), 64)
        
      19: questVal := 400
          bytemove(@Question, string("Question                                                        "), 64)
          bytemove(@Answer,   string("What is the question?                                           "), 64)
        
      20: questVal := 500
          bytemove(@Question, string("Question                                                        "), 64)
          bytemove(@Answer,   string("What is the question?                                           "), 64)
        
      21:'Cat 5 $100
          questVal := 100
          bytemove(@Question, string("Question                                                        "), 64)
          bytemove(@Answer,   string("What is the question?                                           "), 64)
        
      22: questVal := 200
          bytemove(@Question, string("Question                                                        "), 64)
          bytemove(@Answer,   string("What is the question?                                           "), 64)
        
      23: questVal := 300
          bytemove(@Question, string("Question                                                        "), 64)
          bytemove(@Answer,   string("What is the question?                                           "), 64)
        
      24: questVal := 400
          bytemove(@Question, string("Question                                                        "), 64)
          bytemove(@Answer,   string("What is the question?                                           "), 64)
        
      25: questVal := 500
          bytemove(@Question, string("Question                                                        "), 64)
          bytemove(@Answer,   string("What is the question?                                           "), 64)

      26: 'Cat 6 $100
          questVal := 100
          bytemove(@Question, string("Question                                                        "), 64)
          bytemove(@Answer,   string("What is the question?                                           "), 64)
        
      27: questVal := 200
          bytemove(@Question, string("Question                                                        "), 64)
          bytemove(@Answer,   string("What is the question?                                           "), 64)
        
      28: questVal := 300
          bytemove(@Question, string("Question                                                        "), 64)
          bytemove(@Answer,   string("What is the question?                                           "), 64)
        
      29: questVal := 400
          bytemove(@Question, string("Cat 6 $400 question                                             "), 64)
          bytemove(@Answer,   string("What is the question?                                           "), 64)
        
      30: questVal := 500
          bytemove(@Question, string("Cat 6 $500 question                                             "), 64)
          bytemove(@Answer,   string("What is the question?                                           "), 64)
        
       
    'Use 0 to indicate question has already been asked
    GUI.MENUSetStatus(QuestMenu[val], 0)
    'Set text (the price) to blank
    GUI.MENUSetText(QuestMenu[val], string(" "))

    pst.Str(string("answer is: ",13))
    pst.Str(@Answer)

    'BlankScreen
    'Trying out question box
    'We blanked the screen, now we need to restore normal colors
    'Now make just the lines we need look right
    'repeat tmp from vga_rows/2 to vga_rows/2 + 2
    '  GUI.SetLineColor(tmp, %%333, %%003)

    'Then restore normal colors across screen

    GUI.TBOXClear(AnswerBox)
    GUI.TBOXPrint(AnswerBox, @Question, 64)

    EnableBuzzer
  return val


PRI BlankScreen | tmp
  'make whole screen blue
  repeat tmp from 0 to vga_rows
    GUI.SetLineColor(tmp, %%003, %%003)

DAT

Team1Name      byte "The Fast and the Spurious", 0
Team2Name      byte "Logjammin                ", 0
Team3Name      byte "Taking a Wikileak        ", 0

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