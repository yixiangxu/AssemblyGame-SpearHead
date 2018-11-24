*-----------------------------------------------------------
* Title      :SpearHead
* Written by :Yixiang Xu
* Date       :9/28/18
* Description:Assembly Game #1
*-----------------------------------------------------------
BLACK                               EQU     $00000000
WHITE                               EQU     $00FFFFFF
PURPLE	                            EQU	    $00800080
BLUE	                            EQU	    $00FF0000

LEFT_KEY                            EQU     $25
UP_KEY                              EQU     $26
RIGHT_KEY                           EQU     $27
DOWN_KEY                            EQU     $28

OUTPUT_WIDTH                        EQU     1000
OUTPUT_HEIGHT                       EQU     800

KEYBOARD_INPUT_READ_TRAP            EQU     5
GET_TIME_FROM_MIDNIGHT_TRAP         EQU     8
CLEAR_SCREEN_TRAP                   EQU     11
DISPLAY_STRING_TRAP                 EQU     14
KEYBOARD_INPUT_TRAP                 EQU     19
OUTPUT_RESOLUTION_TRAP              EQU     33
PLAY_SOUND_TRAP                     EQU     73
PEN_COLOR_TRAP                      EQU     80
FILL_COLOR_TRAP                     EQU     81
DRAW_PIXEL_TRAP                     EQU     82
DRAW_LINE_TRAP                      EQU     84
DRAW_FILL_RECT_TRAP                 EQU     87
DRAW_FILL_ELLIPSE                   EQU     88
DRAW_RECT_TRAP                      EQU     90
DRAW_MODE_TRAP                      EQU     92
PEN_WIDTH_TRAP                      EQU     93
REPAINT_TRAP                        EQU     94

CLEAR_SCREEN                        EQU     $FF00
DOUBLE_BUFFER                       EQU     17
FRAC_BITS                           EQU     4

LEFT_X_MAIN_CONTAINER               EQU     265<<FRAC_BITS
TOP_Y_MAIN_CONTAINER                EQU     165<<FRAC_BITS
WIDTH_MAIN_CONTAINER                EQU     490
HEIGHT_MAIN_CONTAINER               EQU     490
THICKNESS_MAIN_CONTAINER            EQU     20

LEFT_X_CONTAINER                    EQU     425<<FRAC_BITS
TOP_Y_CONTAINER                     EQU     325<<FRAC_BITS
WIDTH_CONTAINER                     EQU     160
HEIGHT_CONTAINER                    EQU     160
THICKNESS_CONTAINER                 EQU     10
SIZE_TILE                           EQU     50

SIZE_USER_INPUT_CONTROL             EQU     30

NUMBER_SPEARS                       EQU     12
DATA_SIZE_SPEARS_ARRAY              EQU     6
GROUP_SIZE_SPEARS_ARRAY             EQU     18

ISSPAWNED_BIT_SPEAR_VAR             EQU     8
ISATTACKING_BIT_SPEAR_VAR           EQU     9
STATUS_SPEAR_VAR                    EQU     0
OUTPUT_LEFT_X_SPEAR_VAR             EQU     2
OUTPUT_TOP_Y_SPEAR_VAR              EQU     4

SPEAR_IMAGE_SIZE                    EQU     30

GAP_BETWEEN_SPEAR_SIDE_AND_TILE     EQU     10
GAP_BETWEEN_SPEARHEAD_AND_TILE      EQU     20

TOP_DIRECTION                       EQU     $1
RIGHT_DIRECTION                     EQU     $6
BOTTOM_DIRECTION                    EQU     $9
LEFT_DIRECTION                      EQU     $2

NUMBER_SPEARS_ON_EACH_WALL          EQU     9

ACCELERATION_SPEED                  EQU     12

BIT_MASK_0001                       EQU     1
BIT_MASK_0010                       EQU     2
BIT_MASK_0011                       EQU     3
BIT_MASK_0100                       EQU     4
BIT_MASK_1000                       EQU     8
BIT_MASK_01000000                   EQU     64

ONE_BYTE_BITS                       EQU     8
BYTES_OF_A_LONG_WORD                EQU     4

MAX_LOCATION_IN_CONTAINER           EQU     2

LEFT_X_7SEGMENT_IN_ONES             EQU     950
LEFT_X_7SEGMENT_IN_TENS             EQU     900
TOP_Y_7SEGMENT                      EQU     20
SIZE_7SEGMENT                       EQU     30
PEN_WIDTH_7SEGMENT                  EQU     5

START_X_7SEG_VAR                    EQU     0
START_Y_7SEG_VAR                    EQU     1
END_X_7SEG_VAR                      EQU     2
END_Y_7SEG_VAR                      EQU     3

WAVE_PERIOD_DIFFICULTY_UP           EQU     8

CONTAINER_MOVE_SPEED                EQU     300

REST_TIME                           EQU     80

EVERY_X_WAVES                       EQU     5

MAX_SPEAR_SPEED                     EQU     100

START   ORG     $1000

*Set up start layout
SetUp:
    *Set output resolution
    move.b  #OUTPUT_RESOLUTION_TRAP,d0
    move.l  #OUTPUT_WIDTH,d1
    swap.w  d1
    move.w  #OUTPUT_HEIGHT,d1
    TRAP    #15

    *Set pen color to white
    move.b  #PEN_COLOR_TRAP,d0
    move.l  #WHITE,d1
    TRAP    #15
    
    *Set fill color to black
    move.l  #FILL_COLOR_TRAP,d0
    move.l  #BLACK,d1
    TRAP    #15
    
    *Enable double buffer
    move.l  #DRAW_MODE_TRAP,d0
    move.l  #DOUBLE_BUFFER,d1
    TRAP    #15
    
    *Set main container
    jsr     DrawMainContainer
    
    *Set container
    jsr     DrawContainer

    *Set user input control start coordinates
    move.l  #1,d5
    move.l  #1,d6
    jsr     DrawUserInputControl
    
    lea     StartMessage,a1
    move.l  #DISPLAY_STRING_TRAP,d0
    TRAP    #15
    
    move.l  #REPAINT_TRAP,d0
    TRAP    #15
*Wait for any key pressed to start 
WaitUntilStart:
    clr.l   d1
    move.b  #KEYBOARD_INPUT_READ_TRAP,d0
    TRAP    #15
    andi.l  #$FF,d1
    beq     WaitUntilStart
    jsr     InitGameData
GameLoop:
    jsr     UpdateScore
    jsr     UpdateScreen
    jsr     CollisionDetect
    jsr     KeyboardListener
    jsr     DrawMainContainer
    jsr     DrawContainer
    jsr     DrawUserInputControl
    jsr     UpdateWarningSystem
    jsr     UpdateSpears
    jsr     UpdateContainer
    jsr     RestBetweenAttack
    
    bra     GameLoop
    
    SIMHALT

*Gap between each attack
RestBetweenAttack:
    cmp.b   #0,IsResting
    beq     NoRest
    
    move.l  #GET_TIME_FROM_MIDNIGHT_TRAP,d0
    TRAP    #15
    
    move.l  StartRestTime,d0
    sub.l   d0,d1
    
    cmp.l   #REST_TIME,d1
    blt     NoRest
    
    move.b  #0,IsResting
NoRest:
    rts
    
*Handle container movement
UpdateContainer:
    cmp.b   #1,NeedWarning  ;no move when it is warning
    beq     FinishUpdatingContainer
    
    cmp.b   #1,IsWarning    
    beq     FinishUpdatingContainer
    
    cmp.b   #1,IsResting    ;no move when it is rest time
    beq     FinishUpdatingContainer
    
    clr.l   d0
    move.b  WarningIndex,d0 ;warning index determine which attack next order
    move.b  (a6,d0),d0  ;1,2,6,9 trigger container move
    mulu.w  #BYTES_OF_A_LONG_WORD,d0
    
    cmp.b   #1,IsContainerMoving 
    beq     NoSetUpContainerMove
    
    lea     ContainerCheckFunctionTable,a4
    move.l  (a4,d0),a5
    jsr     (a5)
NoSetUpContainerMove:
    cmp.b   #0,IsContainerMoving
    beq     FinishUpdatingContainer
    
    move.l  #ACCELERATION_SPEED,d2  ;calculate speed based on frame
    move.l  FrameTime,d1
    mulu.w  d1,d2
    add.l   d2,ContainerSpeed
    
    lea     ContainerMoveFunctionTable,a1   ;move based on direction
    move.l  (a1,d0),a5
    jsr     (a5)
    
    cmp.b   #0,FinishContainerMove
    beq     FinishUpdatingContainer
    
    move.b  #0,IsContainerMoving    ;reset status if a container move is finished
    move.b  #0,FinishContainerMove
    move.l  #0,ContainerSpeed
    
    move.b  #1,IsResting    ;player needs time to prepare between attack
    move.l  #GET_TIME_FROM_MIDNIGHT_TRAP,d0
    TRAP    #15
    move.l  d1,StartRestTime
    
    addi.b  #1,WarningIndex ;if spear attack is finished, move to next attack
    clr.l   d0
    move.b  WarningIndex,d0
    move.b  (a6,d0),d0
    cmp.l   #$FF,d0
    bne     FinishUpdatingContainer
    
    jsr     PutContainerBackToCenter    ;if current attack is "FF" wave is over
    
    move.b  #1,NeedWarning  ;reopen warning system
    addi.b  #1,Score    ;pass each wave give one point
    
    move.b  Score,d0
    divu.w  #EVERY_X_WAVES,d0
    beq     FinishUpdatingContainer
    addi.b  #1,SpearSpawnChance ;each several waves increases the chance spears spawn
FinishUpdatingContainer:
    rts

*Move container to center
PutContainerBackToCenter:
    move.w  #LEFT_X_CONTAINER,LeftXContainer
    move.w  #TOP_Y_CONTAINER,TopYContainer
    
    rts

*Container move Check function
StartContainerMove:
    move.b  #1,IsContainerMoving
NoContainerMove:
    rts

*Functions for container move based on direction
UpdateContainerLeftMove:
    move.l  FrameTime,d2
    move.l  ContainerSpeed,d1
    mulu.w  d1,d2
    sub.w   d2,LeftXContainer
    
    *if touch the bottom,reset position
    move.w  LeftXContainer,d0   ;left wall
    asr.l   #FRAC_BITS,d0
    move.l  #(LEFT_X_MAIN_CONTAINER>>FRAC_BITS + THICKNESS_CONTAINER),d7
    cmp.l   d7,d0
    bgt     NoTouchBottom
    asl.l   #FRAC_BITS,d7
    move.w  d7,LeftXContainer
    
    move.b  #1,FinishContainerMove
    
    rts    

UpdateContainerRightMove:
    move.l  FrameTime,d2
    move.l  ContainerSpeed,d1
    mulu.w  d1,d2
    add.w   d2,LeftXContainer
    
    move.w  LeftXContainer,d0   ;right wall
    asr.l   #FRAC_BITS,d0
    move.l  #(LEFT_X_MAIN_CONTAINER>>FRAC_BITS + WIDTH_MAIN_CONTAINER - THICKNESS_MAIN_CONTAINER - WIDTH_CONTAINER),d7
    cmp.l   d7,d0
    blt     NoTouchBottom
    asl.l   #FRAC_BITS,d7
    move.w  d7,LeftXContainer
    
    move.b  #1,FinishContainerMove
    
    rts    
    
UpdateContainerUpMove:
    move.l  FrameTime,d2
    move.l  ContainerSpeed,d1
    mulu.w  d1,d2
    sub.w   d2,TopYContainer
    
    move.w  TopYContainer,d0   ;top wall
    asr.l   #FRAC_BITS,d0
    move.l  #(TOP_Y_MAIN_CONTAINER>>FRAC_BITS + THICKNESS_CONTAINER),d7
    cmp.l   d7,d0
    bgt     NoTouchBottom
    asl.l   #FRAC_BITS,d7
    move.w  d7,TopYContainer
    
    move.b  #1,FinishContainerMove
    
    rts    
    
UpdateContainerDownMove:
    move.l  FrameTime,d2
    move.l  ContainerSpeed,d1
    mulu.w  d1,d2
    add.w   d2,TopYContainer
    
    move.w  TopYContainer,d0   ;bottom wall
    asr.l   #FRAC_BITS,d0
    move.l  #(TOP_Y_MAIN_CONTAINER>>FRAC_BITS + HEIGHT_MAIN_CONTAINER - THICKNESS_MAIN_CONTAINER - HEIGHT_CONTAINER),d7
    cmp.l   d7,d0
    blt     NoTouchBottom
    asl.l   #FRAC_BITS,d7
    move.w  d7,TopYContainer
    
    move.b  #1,FinishContainerMove
    
    rts

NoTouchBottom:
    rts
    
*Before each wave, container changes color to hint attack
UpdateWarningSystem:
    clr.l   d0
    move.b  NeedWarning,d0
    beq     ContainerChangeColor
    
    lea     WarningSequence,a6
    
    clr.l   d1
    move.b  Score,d1
    divu.w  #WAVE_PERIOD_DIFFICULTY_UP,d1   ;score / wave period = x, x is the range of attack during a wave
    ext.l   d1
    addi.l  #1,d1
    clr.l   d7
    jsr     GetRandomByteIntoD7 ;random number / x, get the remainder y, y is attack number for this wave
    divu.w  d1,d7
    swap.w  d7
    ext.l   d7
    move.l  d7,d1
    
    move.l  #0,d2   ;counter
WarningLoop:
    jsr     GetRandomByteIntoD7
    divu.w  #10,d7  ;0,3,4,5,7,8 spears attack
    swap.w  d7      ;1,2,6,9 four direction container movement
    ext.l   d7
    move.b  d7,(a6,d2)
    addi.l  #1,d2
    
    dbf     d1,WarningLoop
    move.b  #$FF,(a6,d2)    ;end of wave
    move.b  #0,NeedWarning  ;run once each wave
    move.b  #0,WarningIndex
    move.b  #1,IsWarning
ContainerChangeColor:
    cmp.b   #0,IsWarning
    beq     NoWarning
    
    lea     WarningFunctionTable,a0
    move.l  ColorChangeSpeed,d3
    sub.l   d3,ContainerColor   ;slowly turn to black
    andi.l  #$FFFFFF,ContainerColor
    bne     CheckIfExceedMaximum
    move.l  #0,ContainerColor
    neg.l   ColorChangeSpeed    ;back to white after become black
CheckIfExceedMaximum:
    cmp.l   #$FFFFFF,ContainerColor
    bne     DrawPartOfFrame
    move.l  #$FFFFFF,ContainerColor ;avoid rgb value higher than 255
    neg.l   ColorChangeSpeed    ;reset to positive value
DrawPartOfFrame:
    move.b  #PEN_COLOR_TRAP,d0
    move.l  ContainerColor,d1
    TRAP    #15
    
    move.l  #PEN_WIDTH_TRAP,d0  ;cover the frame of container
    move.l  #THICKNESS_CONTAINER,d1
    TRAP    #15
    
    clr.l   d7  ;draw frame based on direction container moves to
    move.b  WarningIndex,d7
    move.b  (a6,d7),d7
    mulu.w  #BYTES_OF_A_LONG_WORD,d7
    move.l  (a0,d7),a1
    jsr     (a1)
    
    cmp.l   #$FFFFFF,ContainerColor
    bne     NoWarning
    addi.b  #1,WarningIndex ;next warning
    clr.l   d0
    move.b  WarningIndex,d0
    cmp.b   #$FF,(a6,d0)
    bne     NoWarning   
    move.b  #0,IsWarning    ;pause warning system
    move.b  #0,WarningIndex
NoWarning:
    rts

*Make the frames blink based on direction
DrawLeftFrame:
    move.l  #(LEFT_X_CONTAINER>>FRAC_BITS - THICKNESS_CONTAINER>>1),d1
    move.l  #(TOP_Y_CONTAINER>>FRAC_BITS - THICKNESS_CONTAINER),d2
    move.l  d1,d3
    move.l  #(TOP_Y_CONTAINER>>FRAC_BITS + HEIGHT_CONTAINER),d4
    
    move.l  #DRAW_RECT_TRAP,d0
    TRAP    #15
    
    rts
    
DrawRightFrame:
    move.l  #(LEFT_X_CONTAINER>>FRAC_BITS - THICKNESS_CONTAINER>>1 + WIDTH_CONTAINER),d1
    move.l  #(TOP_Y_CONTAINER>>FRAC_BITS - THICKNESS_CONTAINER),d2
    move.l  d1,d3
    move.l  #(TOP_Y_CONTAINER>>FRAC_BITS + HEIGHT_CONTAINER),d4
    
    move.l  #DRAW_RECT_TRAP,d0
    TRAP    #15
    
    rts

DrawTopFrame:
    move.l  #(LEFT_X_CONTAINER>>FRAC_BITS - THICKNESS_CONTAINER),d1
    move.l  #(TOP_Y_CONTAINER>>FRAC_BITS - THICKNESS_CONTAINER>>1),d2
    move.l  #(LEFT_X_CONTAINER>>FRAC_BITS + WIDTH_CONTAINER),d3
    move.l  d2,d4
    
    move.l  #DRAW_RECT_TRAP,d0
    TRAP    #15

    rts
    
DrawBottomFrame:
    move.l  #(LEFT_X_CONTAINER>>FRAC_BITS - THICKNESS_CONTAINER),d1
    move.l  #(TOP_Y_CONTAINER>>FRAC_BITS - THICKNESS_CONTAINER>>1 + HEIGHT_CONTAINER),d2
    move.l  #(LEFT_X_CONTAINER>>FRAC_BITS + WIDTH_CONTAINER),d3
    move.l  d2,d4
    
    move.l  #DRAW_RECT_TRAP,d0
    TRAP    #15
    
    rts
    
DrawWholeFrame:
    move.l  #(LEFT_X_CONTAINER>>FRAC_BITS - THICKNESS_CONTAINER>>1),d1
    move.l  #(TOP_Y_CONTAINER>>FRAC_BITS - THICKNESS_CONTAINER>>1),d2
    move.l  #(LEFT_X_CONTAINER>>FRAC_BITS - THICKNESS_CONTAINER>>1 + WIDTH_CONTAINER),d3
    move.l  #(TOP_Y_CONTAINER>>FRAC_BITS - THICKNESS_CONTAINER>>1 + HEIGHT_CONTAINER),d4
    
    move.b  #DRAW_RECT_TRAP,d0
    TRAP    #15
    
    rts
   
*Count score and draw 7 segment LED
UpdateScore:
    *Set pen color to white
    move.b  #PEN_COLOR_TRAP,d0
    move.l  #WHITE,d1
    TRAP    #15
    
    lea     SevenSegLEDArray,a0 ;score in ones
    lea     SevenSegIndexArray,a1
    
    clr.l   d0
    clr.l   d2

    move.b  Score,d0 
    divu.w  #10,d0
    swap.w  d0
    ext.l   d0
    move.l  #BIT_MASK_01000000,d1
    move.b  (a0,d0),d2
    move.l  #LEFT_X_7SEGMENT_IN_ONES,d7
    
    jsr     SevenSegLEDLoop
    
    lea     SevenSegLEDArray,a0 ;score in tens
    lea     SevenSegIndexArray,a1
    
    clr.l   d0
    clr.l   d2
    
    move.b  Score,d0
    divu.w  #10,d0
    ext.l   d0
    move.l  #BIT_MASK_01000000,d1
    move.b  (a0,d0),d2
    move.l  #LEFT_X_7SEGMENT_IN_TENS,d7
    
    jsr     SevenSegLEDLoop
    
    rts

SevenSegLEDLoop:
    move.l  d2,d3
    and.l   d1,d3
    beq     NotTurnOn
    jsr     DrawSevenSegLED
    bra     NextSegment
NotTurnOn:
    adda.l  #4,a1
NextSegment:
    asr.l   #1,d1
    bne     SevenSegLEDLoop
FinishScore:
    rts
    
*Draw seven segment LED score
DrawSevenSegLED:
    movem.l d0-d4,-(sp)
    
    clr.l   d1
    clr.l   d2
    clr.l   d3
    clr.l   d4
    
    move.l  #PEN_WIDTH_TRAP,d0
    move.l  #PEN_WIDTH_7SEGMENT,d1
    TRAP    #15
    
    move.b (a1)+,d1 ;start index, x0,y0,x1,y1
    move.b (a1)+,d2
    move.b (a1)+,d3
    move.b (a1)+,d4
    
    mulu.w  #SIZE_7SEGMENT,d1   ;index * size = length of line
    mulu.w  #SIZE_7SEGMENT,d2
    mulu.w  #SIZE_7SEGMENT,d3
    mulu.w  #SIZE_7SEGMENT,d4
    
    add.l   d7,d1 ;add output position
    add.l   #TOP_Y_7SEGMENT,d2
    add.l   d7,d3
    add.l   #TOP_Y_7SEGMENT,d4
    
    move.l  #DRAW_LINE_TRAP,d0
    TRAP    #15
    
    move.l  #PEN_WIDTH_TRAP,d0
    move.l  #1,d1
    TRAP    #15
    
    movem.l (sp)+,d0-d4
    
    rts
    
*Initialize initial game data
InitGameData:
    move.l  #1,d5
    move.l  #1,d6
    jsr     InitSpears
    jsr     SpawnSpears
    move.l  #0,SpearSpeed
    move.l  #0,ContainerSpeed
    move.b  #0,Score
    move.b  #1,NeedWarning
    move.b  #0,IsSpearAttacking
    move.b  #0,IsWarning
    move.b  #0,FinishSpearAttack
    move.w  #LEFT_X_CONTAINER,LeftXContainer
    move.w  #TOP_Y_CONTAINER,TopYContainer
    move.b  #0,IsContainerMoving
    move.b  #0,FinishContainerMove
    move.b  #0,IsResting
    move.b  #0,IsDead
    move.b  #3,SpearSpawnChance
    
    move.l  #GET_TIME_FROM_MIDNIGHT_TRAP,d0 ;store game start time
    TRAP    #15
    move.l  d1,GameStartTime
    
    *Randomness
    move.l  #GET_TIME_FROM_MIDNIGHT_TRAP,d0
    TRAP    #15
    move.l  d1,RANDOMVAL
    
    rts
    
*Player dies if there is a collision with spears detected 
CollisionDetect:
    lea     SpearsData,a0
    lea     SpearsDataEnd,a1
    
    clr.l   d1
    clr.l   d2
    move.l  #DATA_SIZE_SPEARS_ARRAY,d0
CollisionLoop:
    btst    #ISSPAWNED_BIT_SPEAR_VAR,STATUS_SPEAR_VAR(a0)
    beq     NextCollisionDetect
    
    move.w  OUTPUT_LEFT_X_SPEAR_VAR(a0),d1
    move.w  OUTPUT_TOP_Y_SPEAR_VAR(a0),d2
    asr.l   #FRAC_BITS,d1
    asr.l   #FRAC_BITS,d2
    
    jsr     DetectRowHit
    jsr     DetectColumnHit
NextCollisionDetect:    
    add.l   d0,a0
    cmp.l   a1,a0
    blt     CollisionLoop

    rts

*check if collision happen in row
DetectRowHit:
    move.l  d1,d3
    move.l  d2,d4
    
    cmp.l   UserInputY,d4
    bne     NoRowHit
    
    cmp.l   UserInputX,d3   ;first check hit from left
    bge     HitFromRight
    addi.l  #SPEAR_IMAGE_SIZE,d3
    cmp.l   UserInputX,d3
    ble     NoRowHit
    bra     LoseGame
HitFromRight:
    move.l  d1,d3
    move.l  d2,d4
    
    subi.l  #SPEAR_IMAGE_SIZE,d3
    cmp.l   UserInputX,d3
    bge     NoRowHit
    bra     LoseGame
NoRowHit:
    rts

*check if collision happen in column
DetectColumnHit:
    move.l  d1,d3
    move.l  d2,d4
    
    cmp.l   UserInputX,d1
    bne     NoColumnHit
    
    cmp.l   UserInputY,d4   ;first check hit from left
    bge     HitFromBottom
    addi.l  #SPEAR_IMAGE_SIZE,d4
    cmp.l   UserInputY,d4
    ble     NoColumnHit
    bra     LoseGame
HitFromBottom:
    move.l  d1,d3
    move.l  d2,d4
    
    subi.l  #SPEAR_IMAGE_SIZE,d4
    cmp.l   UserInputY,d4
    bge     NoColumnHit
    bra     LoseGame
NoColumnHit:
    rts
    
LoseGame:
    move.b  #1,IsDead
    lea     StartMessage,a1
    move.l  #DISPLAY_STRING_TRAP,d0
    TRAP    #15
    
    rts
    
*Draw spears around the walls based on direction
UpdateSpears:
    cmp.b   #1,NeedWarning
    beq     NoSetUpAttack
    
    cmp.b   #1,IsResting
    beq     NoSetUpAttack
    
    cmp.b   #1,IsWarning
    beq     NoSetUpAttack
    
    cmp.b   #1,IsSpearAttacking
    beq     NoSetUpAttack
    
    clr.l   d0
    move.b  WarningIndex,d0
    move.b  (a6,d0),d0  ;0,3,4,5,7,8 trigger spear attack
    mulu.w  #BYTES_OF_A_LONG_WORD,d0
    lea     SpearCheckFunctionTable,a4
    move.l  (a4,d0),a5
    jsr     (a5) 
NoSetUpAttack: 
    lea     SpearsData,a1
    lea     SpearsDataEnd,a2
    lea     SpearsAttackFunctionTable,a3
    move.l  #DATA_SIZE_SPEARS_ARRAY,d7
    
    clr.l   d4
    andi.b  #$FF,IsSpearAttacking   ;if spears are attacking, add aceleration speed to spear speed
    beq     SpearLoop
    move.l  #ACCELERATION_SPEED,d2
    move.l  FrameTime,d1
    mulu.w  d1,d2
    add.l   d2,SpearSpeed
    move.l  SpearSpeed,d2   ;limit highest spear speed
    cmp.l   #MAX_SPEAR_SPEED,d2
    ble     NoLimitSpeed
    move.l  #MAX_SPEAR_SPEED,SpearSpeed
    bra     SpearSpeedLimit
NoLimitSpeed:
    move.l  d2,SpearSpeed
SpearSpeedLimit:
    move.l  SpearSpeed,d4
    move.l  FrameTime,d0
    mulu.w  d0,d4
    clr.l   d0
SpearLoop:
    btst    #ISSPAWNED_BIT_SPEAR_VAR,STATUS_SPEAR_VAR(a1)
    beq     NextSpear
    
    move.w  STATUS_SPEAR_VAR(a1),d0
    ext.w   d0
    mulu.w  #BYTES_OF_A_LONG_WORD,d0
    move.l  (a3,d0),a4
    jsr     (a4)
    
    btst    #ISSPAWNED_BIT_SPEAR_VAR,STATUS_SPEAR_VAR(a1)
    beq     NextSpear
DrawSpear:
    movem.l d4-d7,-(sp) ;save coordinates
    
    move.l  a0,-(sp)
    
    move.l  #0,-(sp)   ;full image
    move.l  #0,-(sp)
    move.l  #SPEAR_IMAGE_SIZE,-(sp)
    move.l  #SPEAR_IMAGE_SIZE,-(sp)

    move.w  OUTPUT_TOP_Y_SPEAR_VAR(a1),d0
    asr.l   #FRAC_BITS,d0
    move.l  d0,-(sp)
    
    move.w  OUTPUT_LEFT_X_SPEAR_VAR(a1),d0
    asr.l   #FRAC_BITS,d0
    move.l  d0,-(sp)
    
    jsr     DrawBitmapChunk
    movem.l (sp)+,d4-d7
NextSpear:
    add.l   d7,a1
    cmp.l   a2,a1
    blt     SpearLoop
    
    cmp.b   #0,FinishSpearAttack
    beq     BackToGameLoop
    
    move.b  #0,IsSpearAttacking ;reset datas after spear attack finish
    move.l  #0,SpearSpeed
    jsr     SpawnSpears
    move.b  #0,FinishSpearAttack
    
    move.b  #1,IsResting
    move.l  #GET_TIME_FROM_MIDNIGHT_TRAP,d0
    TRAP    #15
    move.l  d1,StartRestTime
    
    addi.b  #1,WarningIndex ;if spear attack is finished, move to next attack
    clr.l   d0
    move.b  WarningIndex,d0
    move.b  (a6,d0),d0
    cmp.l   #$FF,d0
    bne     BackToGameLoop
    jsr     PutContainerBackToCenter
    move.b  #1,NeedWarning  ;if all attacks are finished,start new turn
    addi.b  #1,Score
    
    clr.l   d0
    move.b  Score,d0
    divu.w  #EVERY_X_WAVES,d0
    beq     FinishUpdatingContainer
    addi.b  #1,SpearSpawnChance
BackToGameLoop:
    rts

StartSpearAttack:
    move.b  #1,IsSpearAttacking
    lea     ShootSound,a1
    move.l  #PLAY_SOUND_TRAP,d0
    TRAP    #15
NoSpearAttack:
    rts

*Move spear based on direction if it is attacking
UpdateTopSpears:
    clr.l   d0
    move.b  FinishSpearAttack,d0
    cmp.b   #1,d0
    beq     FinishTopSpearAttack
    
    clr.l   d0  ;change spear bmp file to hint which spears are directing at player
    move.w  OUTPUT_LEFT_X_SPEAR_VAR(a1),d0
    asr.l   #FRAC_BITS,d0
    
    cmp.l   UserInputX,d0
    beq     IsTopSpearTargetingPlayer
    
    move.w  OUTPUT_TOP_Y_SPEAR_VAR(a1),d0
    asr.l   #FRAC_BITS,d0
    
    cmp.l   UserInputY,d0
    beq     IsTopSpearTargetingPlayer
    
    lea     TopSpearBmp,a0
    bra     TopSpearNotTargeting
IsTopSpearTargetingPlayer:
    lea     TopSpearDBmp,a0
TopSpearNotTargeting:
    andi.b  #$FF,IsSpearAttacking
    beq     SpearNoChange
    
    add.w   d4,OUTPUT_TOP_Y_SPEAR_VAR(a1)
    
    *if touch the bottom,reset position
    move.w  OUTPUT_TOP_Y_SPEAR_VAR(a1),d0
    asr.l   #FRAC_BITS,d0
    cmp.l   #(TOP_Y_MAIN_CONTAINER>>FRAC_BITS + HEIGHT_MAIN_CONTAINER - THICKNESS_MAIN_CONTAINER - THICKNESS_CONTAINER - SPEAR_IMAGE_SIZE - 5),d0
    blt     SpearNoChange
    move.b  #1,FinishSpearAttack
FinishTopSpearAttack:
    move.l  #(TOP_Y_MAIN_CONTAINER>>FRAC_BITS + THICKNESS_CONTAINER),d0
    asl.l   #FRAC_BITS,d0
    move.w  d0,OUTPUT_TOP_Y_SPEAR_VAR(a1)
    
    bclr    #ISSPAWNED_BIT_SPEAR_VAR,STATUS_SPEAR_VAR(a1)
    
    rts
    
UpdateRightSpears:
    clr.l   d0
    move.b  FinishSpearAttack,d0
    cmp.b   #1,d0
    beq     FinishRightSpearAttack
    
    clr.l   d0
    move.w  OUTPUT_LEFT_X_SPEAR_VAR(a1),d0
    asr.l   #FRAC_BITS,d0
    
    cmp.l   UserInputX,d0
    beq     IsRightSpearTargetingPlayer
    
    move.w  OUTPUT_TOP_Y_SPEAR_VAR(a1),d0
    asr.l   #FRAC_BITS,d0
    
    cmp.l   UserInputY,d0
    beq     IsRightSpearTargetingPlayer
    
    lea     RightSpearBmp,a0
    bra     RightSpearNotTargeting
IsRightSpearTargetingPlayer:
    lea     RightSpearDBmp,a0
RightSpearNotTargeting:
    andi.b  #$FF,IsSpearAttacking
    beq     SpearNoChange
    
    sub.w   d4,OUTPUT_LEFT_X_SPEAR_VAR(a1)
    
    move.w  OUTPUT_LEFT_X_SPEAR_VAR(a1),d0
    asr.l   #FRAC_BITS,d0
    cmp.l   #(LEFT_X_MAIN_CONTAINER>>FRAC_BITS + THICKNESS_CONTAINER),d0
    bgt     SpearNoChange
    move.b  #1,FinishSpearAttack
FinishRightSpearAttack:
    move.l  #(LEFT_X_MAIN_CONTAINER>>FRAC_BITS + WIDTH_MAIN_CONTAINER - THICKNESS_MAIN_CONTAINER - THICKNESS_CONTAINER - SPEAR_IMAGE_SIZE),d0
    asl.l   #FRAC_BITS,d0
    move.w  d0,OUTPUT_LEFT_X_SPEAR_VAR(a1)
    
    bclr    #ISSPAWNED_BIT_SPEAR_VAR,STATUS_SPEAR_VAR(a1)
    
    rts
    
UpdateBottomSpears: 
    clr.l   d0
    move.b  FinishSpearAttack,d0
    cmp.b   #1,d0
    beq     FinishBottomSpearAttack
    
    clr.l   d0
    move.w  OUTPUT_LEFT_X_SPEAR_VAR(a1),d0
    asr.l   #FRAC_BITS,d0
    
    cmp.l   UserInputX,d0
    beq     IsBottomSpearTargetingPlayer
    
    move.w  OUTPUT_TOP_Y_SPEAR_VAR(a1),d0
    asr.l   #FRAC_BITS,d0
    
    cmp.l   UserInputY,d0
    beq     IsBottomSpearTargetingPlayer
    
    lea     BottomSpearBmp,a0
    bra     BottomSpearNotTargeting
IsBottomSpearTargetingPlayer:
    lea     BottomSpearDBmp,a0
BottomSpearNotTargeting:
    andi.b  #$FF,IsSpearAttacking
    beq     SpearNoChange
    
    sub.w   d4,OUTPUT_TOP_Y_SPEAR_VAR(a1)
    
    move.w  OUTPUT_TOP_Y_SPEAR_VAR(a1),d0
    asr.l   #FRAC_BITS,d0
    cmp.l   #(TOP_Y_MAIN_CONTAINER>>FRAC_BITS + THICKNESS_CONTAINER),d0   
    bgt     SpearNoChange
    move.b  #1,FinishSpearAttack
FinishBottomSpearAttack:
    move.l  #(TOP_Y_MAIN_CONTAINER>>FRAC_BITS + HEIGHT_MAIN_CONTAINER - THICKNESS_MAIN_CONTAINER - THICKNESS_CONTAINER - SPEAR_IMAGE_SIZE),d0
    asl.l   #FRAC_BITS,d0
    move.w  d0,OUTPUT_TOP_Y_SPEAR_VAR(a1)
    
    bclr    #ISSPAWNED_BIT_SPEAR_VAR,STATUS_SPEAR_VAR(a1)
    
    rts
    
UpdateLeftSpears:
    clr.l   d0
    move.b  FinishSpearAttack,d0
    cmp.b   #1,d0
    beq     FinishLeftSpearAttack
    
    clr.l   d0
    move.w  OUTPUT_LEFT_X_SPEAR_VAR(a1),d0
    asr.l   #FRAC_BITS,d0
    
    cmp.l   UserInputX,d0
    beq     IsLeftSpearTargetingPlayer
    
    move.w  OUTPUT_TOP_Y_SPEAR_VAR(a1),d0
    asr.l   #FRAC_BITS,d0
    
    cmp.l   UserInputY,d0
    beq     IsLeftSpearTargetingPlayer
    
    lea     LeftSpearBmp,a0
    bra     LeftSpearNotTargeting
IsLeftSpearTargetingPlayer:
    lea     LeftSpearDBmp,a0
LeftSpearNotTargeting:
    andi.b  #$FF,IsSpearAttacking
    beq     SpearNoChange
    
    add.w   d4,OUTPUT_LEFT_X_SPEAR_VAR(a1)
    
    move.w  OUTPUT_LEFT_X_SPEAR_VAR(a1),d0
    asr.l   #FRAC_BITS,d0
    cmp.l   #(LEFT_X_MAIN_CONTAINER>>FRAC_BITS + WIDTH_MAIN_CONTAINER - THICKNESS_MAIN_CONTAINER - THICKNESS_CONTAINER - SPEAR_IMAGE_SIZE),d0
    blt     SpearNoChange
    move.b  #1,FinishSpearAttack
FinishLeftSpearAttack:
    move.l  #(LEFT_X_MAIN_CONTAINER>>FRAC_BITS + THICKNESS_CONTAINER),d0
    asl.l   #FRAC_BITS,d0
    move.w  d0,OUTPUT_LEFT_X_SPEAR_VAR(a1)
    
    bclr    #ISSPAWNED_BIT_SPEAR_VAR,STATUS_SPEAR_VAR(a1)
    
    rts

SpearNoChange:
    rts

*Spawn random spears
SpawnSpears:
    lea     SpearsData,a0
    lea     SpearsDataEnd,a1
ChooseRandomSpear:
    jsr     GetRandomByteIntoD7 ;no spawn if random value [0,SpearSpawnChance) = 0
    clr.l   d0
    move.b  SpearSpawnChance,d0
    divu.w  d0,d7
    swap.w  d7
    ext.l   d7
    cmp.l   #0,d7
    beq     NoSpawn
    
    clr.l   d7
    jsr     GetRandomByteIntoD7
    divu.w  #3,d7   ;get a random value in range 0-2
    swap.w  d7  ;choose 1 for each spears 3 spears to be spawned
    ext.l   d7
    
    mulu.w  #DATA_SIZE_SPEARS_ARRAY,d7
    bset    #ISSPAWNED_BIT_SPEAR_VAR,STATUS_SPEAR_VAR(a0,d7)
NoSpawn:
    add.l   #GROUP_SIZE_SPEARS_ARRAY,a0
    
    cmp.l   a1,a0
    blt     ChooseRandomSpear
    
    rts

*Listen to key pressed
KeyboardListener:
    cmp.b   #1,IsDead
    beq     AroundNoInput
    
    move.b  #KEYBOARD_INPUT_TRAP,d0
    move.l  #(LEFT_KEY<<24 + RIGHT_KEY<<16 + UP_KEY<<8 + DOWN_KEY),d1
    TRAP    #15
    
    *Remove debouncing
    andi.l  #$FFFFFFFF,d1
    beq     NoInput
    
    move.l  d1,d7
    and.l   KeyPressedLastTime,d1   ;If a key is pressed last time, doesn't count this time
    
    not.l   d7
    move.l  d7,KeyPressedLastTime
    
    *User input control moves when arrow key is pressed
    lea     KeyPressFunctionTable,a0
    
    move.l  d1,d0   ;check if left arrow is pressed
    asr.l   #ONE_BYTE_BITS,d0
    asr.l   #ONE_BYTE_BITS,d0
    asr.l   #ONE_BYTE_BITS,d0
    andi.l  #BIT_MASK_0001,d0
    mulu.w  #BYTES_OF_A_LONG_WORD,d0
    move.l  (a0,d0),a1
    jsr     (a1)
    
    move.l  d1,d0   ;check if right arrow is pressed
    asr.l   #ONE_BYTE_BITS,d0
    asr.l   #ONE_BYTE_BITS,d0
    andi.l  #BIT_MASK_0010,d0
    mulu.w  #BYTES_OF_A_LONG_WORD,d0
    move.l  (a0,d0),a1
    jsr     (a1)
    
    move.l  d1,d0   ;check if up arrow is pressed
    asr.l   #ONE_BYTE_BITS,d0
    andi.l  #BIT_MASK_0011,d0
    mulu.w  #BYTES_OF_A_LONG_WORD,d0
    move.l  (a0,d0),a1
    jsr     (a1)
    
    move.l  d1,d0   ;check if down arrow is pressed
    andi.l  #BIT_MASK_0100,d0
    mulu.w  #BYTES_OF_A_LONG_WORD,d0
    move.l  (a0,d0),a1
    jsr     (a1)
    
    bra     aroundNoInput
NoInput:
    move.l  #$FFFFFFFF,KeyPressedLastTime
AroundNoInput:
    rts

*User input control moves left if left arrow is pressed
PressLeft:
    move.l  d5,d0
    beq     NoPress
    subi.l  #1,d5
    rts

*User input control moves right if left arrow is pressed
PressRight:
    cmp.w   #MAX_LOCATION_IN_CONTAINER,d5
    bge     NoPress
    addi.l  #1,d5
    rts

*User input control moves up if left arrow is pressed  
PressUp:
    move.l  d6,d0
    beq     NoPress
    subi.l  #1,d6
    rts

*User input control moves down if left arrow is pressed   
PressDown:
    cmp.w   #MAX_LOCATION_IN_CONTAINER,d6
    bge     NoPress
    addi.l  #1,d6
    rts
    
NoPress:
    rts

*Clear screen and update
UpdateScreen:
    move.l  #GET_TIME_FROM_MIDNIGHT_TRAP,d0 ;used to calculate frame time
    TRAP    #15
    move.l  StartFrame,d0
    sub.l   d0,d1
    move.l  d1,FrameTime
    
    move.l  #REPAINT_TRAP,d0
    TRAP    #15
    
    move.l  #GET_TIME_FROM_MIDNIGHT_TRAP,d0 ;start time for each loop
    TRAP    #15
    move.l  d1,StartFrame
    
    cmp.b   #0,IsDead
    beq     KeepPlaying
    
    move.l  #$10000000,sp
    bra     WaitUntilStart
KeepPlaying:
    move.b  #CLEAR_SCREEN_TRAP,d0
    move.l  #CLEAR_SCREEN,d1
    TRAP    #15
    
    rts
 
**Draw user input control based on coordinates in container
DrawUserInputControl:
    movem.l d5-d6,-(sp)

    clr.l   d1
    clr.l   d2
    move.w  LeftXContainer,d1
    asr.l   #FRAC_BITS,d1
    move.w  TopYContainer,d2
    asr.l   #FRAC_BITS,d2
    
    lea     UserInputBmp,a0
    move.l  a0,-(sp)
    
    *Calculate output screen x,y position
    move.l  #SIZE_TILE,d0   ;x = thickness_container/2 + size_tile * d5 + (size_tile - size_user_input_control)/2
    mulu    d5,d0
    add.l   d0,d1
    addi.l  #((SIZE_TILE - SIZE_USER_INPUT_CONTROL)>>1),d1
    move.l  #SIZE_TILE,d0   ;y = thickness_container/2 + size_tile * d6 + (size_tile - size_user_input_control)/2
    mulu    d6,d0
    add.l   d0,d2
    addi.l  #((SIZE_TILE - SIZE_USER_INPUT_CONTROL)>>1),d2
    
    move.l  d1,UserInputX
    move.l  d2,UserInputY
    
    move.l  #0,-(sp)
    move.l  #0,-(sp)
    move.l  #SIZE_USER_INPUT_CONTROL,-(sp)
    move.l  #SIZE_USER_INPUT_CONTROL,-(sp)
    move.l  d2,-(sp)
    move.l  d1,-(sp)
    
    jsr     DrawBitmapChunk
    movem.l (sp)+,d5-d6
    rts
   
*Draw external container
DrawMainContainer:
    *Set pen color to white
    move.b  #PEN_COLOR_TRAP,d0
    move.l  #WHITE,d1
    TRAP    #15
    
    move.l  #(LEFT_X_MAIN_CONTAINER>>FRAC_BITS - THICKNESS_MAIN_CONTAINER>>1),d1
    move.l  #(TOP_Y_MAIN_CONTAINER>>FRAC_BITS - THICKNESS_MAIN_CONTAINER>>1),d2
    move.l  #(LEFT_X_MAIN_CONTAINER>>FRAC_BITS - THICKNESS_MAIN_CONTAINER>>1 + WIDTH_MAIN_CONTAINER),d3
    move.l  #(TOP_Y_MAIN_CONTAINER>>FRAC_BITS - THICKNESS_MAIN_CONTAINER>>1 + HEIGHT_MAIN_CONTAINER),d4
    
    move.l  d1,-(sp)
    move.b  #PEN_WIDTH_TRAP,d0
    move.b  #THICKNESS_MAIN_CONTAINER,d1
    TRAP    #15
    move.l  (sp)+,d1
    
    move.b  #DRAW_RECT_TRAP,d0
    TRAP    #15
    
    move.l  d1,-(sp)
    move.b  #PEN_WIDTH_TRAP,d0
    move.l  #1,d1
    TRAP    #15
    move.l  (sp)+,d1
    
    *Draw edge line
    move.l  #(THICKNESS_MAIN_CONTAINER>>1 + THICKNESS_CONTAINER),d0
    add.l   d0,d1
    add.l   d0,d2
    sub.l   d0,d3
    sub.l   d0,d4
    
    move.b  #DRAW_RECT_TRAP,d0
    TRAP    #15
    
    rts
    
*Draw inner container
DrawContainer:
    *Set pen color to white
    move.b  #PEN_COLOR_TRAP,d0
    move.l  #WHITE,d1
    TRAP    #15
    
    clr.l   d1
    clr.l   d2
    
    move.w  LeftXContainer,d1   ;d1 left x, d3 right x
    asr.l   #FRAC_BITS,d1
    subi.l  #(THICKNESS_CONTAINER>>1),d1
    move.l  d1,d3
    addi.l  #WIDTH_CONTAINER,d3
    
    move.w  TopYContainer,d2    ;d2 left x, d4 right x
    asr.l   #FRAC_BITS,d2   
    subi.l  #(THICKNESS_CONTAINER>>1),d2
    move.l  d2,d4
    addi.l  #HEIGHT_CONTAINER,d4
    
    move.l  d1,-(sp)
    move.b  #PEN_WIDTH_TRAP,d0
    move.b  #THICKNESS_CONTAINER,d1
    TRAP    #15
    move.l  (sp)+,d1
    
    move.b  #DRAW_RECT_TRAP,d0
    TRAP    #15
    
    move.l  d1,-(sp)
    move.b  #PEN_WIDTH_TRAP,d0
    move.l  #1,d1
    TRAP    #15
    move.l  (sp)+,d1

    addi.l  #(THICKNESS_CONTAINER>>1 + SIZE_TILE),d1    ;top left line
    subi.l  #(THICKNESS_CONTAINER>>1 + SIZE_TILE),d3   
    subi.l  #SIZE_TILE,d3                              
    
    move.b  #DRAW_LINE_TRAP,d0
    TRAP    #15
    
    addi.l  #SIZE_TILE,d1   ;bottom left line 
    addi.l  #SIZE_TILE,d3
    
    move.b  #DRAW_LINE_TRAP,d0
    TRAP    #15
    
    subi.l  #SIZE_TILE,d1   ;top right line
    subi.l  #SIZE_TILE,d1
    addi.l  #SIZE_TILE,d3
    addi.l  #(THICKNESS_CONTAINER>>1 + SIZE_TILE),d2
    subi.l  #(THICKNESS_CONTAINER>>1 + SIZE_TILE),d4
    subi.l  #SIZE_TILE,d4
    
    move.b  #DRAW_LINE_TRAP,d0
    TRAP    #15
    
    addi.l  #SIZE_TILE,d2   ;bottom right line
    addi.l  #SIZE_TILE,d4
    
    move.b  #DRAW_LINE_TRAP,d0
    TRAP    #15

    rts

*Initialize spears data
InitSpears:
    lea     SpearsIndexTable,a0
    lea     SpearsData,a1
    move.l  #(LEFT_X_MAIN_CONTAINER>>FRAC_BITS + THICKNESS_CONTAINER),d1
    move.l  #(TOP_Y_MAIN_CONTAINER>>FRAC_BITS + THICKNESS_CONTAINER),d2
InitSpearLoop:
    move.w  STATUS_SPEAR_VAR(a0),STATUS_SPEAR_VAR(a1)
    move.w  OUTPUT_LEFT_X_SPEAR_VAR(a0),d0  ;x = xIndex * tile size + gap spear side/gap spearhead
    mulu.w  #SIZE_TILE,d0
    
    move.w  STATUS_SPEAR_VAR(a0),d3 ;xxx1
    andi.w  #BIT_MASK_0001,d3       ;0001
    mulu.w  #GAP_BETWEEN_SPEAR_SIDE_AND_TILE,d3
    
    move.w  STATUS_SPEAR_VAR(a0),d4 ;x1xx
    andi.w  #BIT_MASK_0100,d4       ;0100
    asr.w   #2,d4                   ;0001
    mulu.w  #GAP_BETWEEN_SPEARHEAD_AND_TILE,d4
    
    add.w   d3,d0
    add.w   d4,d0
    add.w   d1,d0
    asl.w   #FRAC_BITS,d0           ;fixed point math
    move.w  d0,OUTPUT_LEFT_X_SPEAR_VAR(a1)
    
    move.w  OUTPUT_TOP_Y_SPEAR_VAR(a0),d0   ;y = yIndex * tile size + gap between spear and tile
    mulu.w  #SIZE_TILE,d0
    
    move.w  STATUS_SPEAR_VAR(a0),d3 ;xx1x
    andi.w  #BIT_MASK_0010,d3       ;0010
    asr.w   #1,d3                   ;0001
    mulu.w  #GAP_BETWEEN_SPEAR_SIDE_AND_TILE,d3
    
    move.w  STATUS_SPEAR_VAR(a0),d4 ;1xxx
    andi.w  #BIT_MASK_1000,d4       ;1000
    asr.w   #3,d4                   ;0001
    mulu.w  #GAP_BETWEEN_SPEARHEAD_AND_TILE,d4
    
    add.w   d3,d0
    add.w   d4,d0
    add.w   d2,d0
    asl.w   #FRAC_BITS,d0           ;fixed point math
    move.w  d0,OUTPUT_TOP_Y_SPEAR_VAR(a1)
    
    clr.l   d0
    clr.l   d3
    clr.l   d4
    
    add.l   #DATA_SIZE_SPEARS_ARRAY,a0
    add.l   #DATA_SIZE_SPEARS_ARRAY,a1
    cmp.l   #SpearsIndexEnd,a0
    blt     InitSpearLoop
    
    rts
    
*Get random number
GetRandomByteIntoD7:
    move.l  d0,-(sp)
    move.l  d1,-(sp)
    move.l  d2,-(sp)
    
    move.l  RANDOMVAL,d0
    moveq	#$AF-$100,d1
    moveq	#18,d2
Ninc0:
	add.l	d0,d0
	bcc	    Ninc1
	eor.b	d1,d0
Ninc1:
	dbf	    d2,Ninc0
	
	clr.l   d7
	move.l	d0,RANDOMVAL
	move.b	d0,d7
	
    move.l (sp)+,d2
    move.l (sp)+,d1
    move.l (sp)+,d0
        
    rts  

REG_INPUT                           REG     D1-D6/A0
OUTPUT_SCREEN_REG                   REG     D1-D2

BMP_SIGNATURE                       EQU     'BM'
OFFSET_TO_PIXELARRAY_OFFSET         EQU     10
IMAGE_WIDTH_OFFSET                  EQU     18
IMAGE_HEIGHT_OFFSET                 EQU     22
BITS_PER_PIXEL_OFFSET               EQU     28

BITS_OF_TWO_BYTES                   EQU     8
BITS_0011                           EQU     3
DEFAULT_BIT_DEPTH                   EQU     24
DEFAULT_BIT_DEPTH_BYTES             EQU     3

DrawBitmapChunk:
    move.l  (sp)+,ReturnAddress ;save return address
    movem.l (sp)+,REG_INPUT
    
    *Prepare data for drawing
    add.l   d4,d2   ;d2 output screen y + chunk height
    sub.l   #1,d2   ;draw from bottom
    
    movem.l OUTPUT_SCREEN_REG,-(sp) ;save output screen location x,y
    bsr     InputErrorCheck ;d1,d2 -> image width,height
    bsr     PixelArraySet
    
    *d5 (image width - chunk width) * 3 + padding
    move.l  d3,d0   
    sub.l   d0,d1
    move.l  d1,d0
    add.l   d1,d0
    add.l   d1,d0
    add.l   d7,d0
    move.l  d0,d5
    
    movem.l (sp)+,OUTPUT_SCREEN_REG
    move.l  d1,d6
    add.l   d1,d3   ;d3 output start x + chunk width
    
*------------------------
*d1 pen color, output screen x position
*d2 output screen start y position
*d3 output start x + chunk width
*d4 chunk height
*d5 (image width - chunk width) * 3 + padding
*d6 output start x position
*------------------------
ContinueRow:
    move.l  d1,d7    ;save x position
    
    *set pixel color
    clr.l   d1
    move.b  (a0)+,d1    ;$000000BB
    lsl.l   #BITS_OF_TWO_BYTES,d1 
    move.b  (a0)+,d1    ;$0000BBGG
    lsl.l   #BITS_OF_TWO_BYTES,d1 
    move.b  (a0)+,d1    ;$00BBGGRR
    
    cmp.l   #BLACK,d1   ;Skip drawing black pixel
    beq     NoDraw      ;Black counts as transparent background
    move.l  #PEN_COLOR_TRAP,d0
    trap    #15
    
    *draw pixel
    move.l  d7,d1   ;restore x position
    move.l  #DRAW_PIXEL_TRAP,d0
    trap    #15
NoDraw:
    move.l  d7,d1   ;restore x position
    *continue to next point
    addi.l  #1,d1   ;move onto next column
    cmp.l   d1,d3   ;if it doesn not exceed chunk width
    bgt     ContinueRow
    
    add.l   d5,a0   ;fill gap between current index to index of next row
    
    move.l  d6,d1   ;reset x position to start position
    subi.l  #1,d2   ;move onto next row
    subi.l  #1,d4
    bne     ContinueRow
    
Finish:
    move.l  ReturnAddress,-(sp)
    rts

*Return error if input is wrong
InputErrorCheck:
    move.w  (a0),d0
    cmp.l   #BMP_SIGNATURE,d0 ;finish if it is not a bmp file
    bne     Finish
    
    move.w  BITS_PER_PIXEL_OFFSET(a0),d0
    ror.w   #BITS_OF_TWO_BYTES,d0 ;change to Big Endian format
    cmp.l   #DEFAULT_BIT_DEPTH,d0   ;finish if bit depth is not 24 bits
    bne     Finish
    
    cmpi.l  #0,d1   ;finish if top left chunk x position <= 0
    blt     finish
    
    cmpi.l  #0,d2   ;finish if top left chunk y position <= 0
    blt     finish
    
    move.l  IMAGE_WIDTH_OFFSET(a0),d0
    beq     Finish  ;finish if width is 0
    bsr     ReverseLongWord ;change to Big Endian format
    move.l  d0,d1
    
    move.l  IMAGE_HEIGHT_OFFSET(a0),d0
    beq     Finish  ;finish if height is 0
    bsr     ReverseLongWord
    move.l  d0,d2
    
    move.l  d3,d0
    add.l   d5,d0
    cmp.l   d1,d0   ;finish if chunk is oversized   
    bgt     Finish  
    
    move.l  d4,d0
    add.l   d6,d0
    cmp.l   d2,d0   ;finish if chunk is oversized
    bgt     Finish
    
    rts
    
ReadBmpError:
    lea     ErrorMessage,a1
    move.l  #DISPLAY_STRING_TRAP,d0
    TRAP    #15
    
    SIMHALT

*Move a0 to the first pixel of chunk data
PixelArraySet:
    move.l  d1,d7
    andi.l  #$000000FF,d7
    andi.b  #BITS_0011,d7 ;get padding

    move.l  d2,d0   ;image height - chunk start y - chunk height
    sub.l   d6,d0
    sub.l   d4,d0
    
    move.l  d0,d6   ;(image height - chunk start y - chunk height) * padding
    mulu.w  d7,d6
    
    mulu.w  d1,d0   ;3 * ((image height - chunk start y - chunk height) * image width + chunk start x)
    add.l   d5,d0
    mulu.w  #DEFAULT_BIT_DEPTH_BYTES,d0
    
    add.l   d0,d6
    
    move.l  OFFSET_TO_PIXELARRAY_OFFSET(a0),d0
    bsr     ReverseLongWord
    add.l   d6,d0
    
    add.l   d0,a0   ;move to start pointer of pixel data
    
    rts

ReverseLongWord:
    ror.w   #BITS_OF_TWO_BYTES,d0 ;4 3 1 2
    swap.w  d0                   ;1 2 4 3
    ror.w   #BITS_OF_TWO_BYTES,d0 ;1 2 3 4
    
    rts
    
*********************
RandomVal           ds.l    1
KeyPressedLastTime  ds.l    1
ReturnAddress       ds.l    1
SpearSpeed          dc.l    0
ContainerSpeed      dc.l    0
Container_Speed     ds.l    1
UserInputX          ds.l    1
UserInputY          ds.l    1                         
GameStartTime       ds.l    1
ContainerColor      dc.l    WHITE
ColorChangeSpeed    dc.l    $111111
LeftXContainer      dc.w    425<<FRAC_BITS
TopYContainer       dc.w    325<<FRAC_BITS
ErrorMessage        dc.b    'Bmp File Input Error',0
StartMessage        dc.b    'Press Any Key To Suffer...',0
SpearSpawnChance    dc.b    2 
IsSpearAttacking    dc.b    0
FinishSpearAttack   dc.b    0
IsDead              dc.b    0
NeedWarning         dc.b    1
IsWarning           dc.b    0
WarningSequence     ds.b    10
WarningIndex        dc.b    0
IsContainerMoving   dc.b    0
FinishContainerMove dc.b    0
IsResting           dc.b    0
StartRestTime       ds.l    1
StartFrame          dc.l    0
FrameTime           dc.l    0

*Every three words represent a spear data: direction, xIndex,yIndex
SpearsIndexTable    dc.w    TOP_DIRECTION,0,0,TOP_DIRECTION,1,0,TOP_DIRECTION,2,0,TOP_DIRECTION,3,0,TOP_DIRECTION,4,0,TOP_DIRECTION,5,0,TOP_DIRECTION,6,0,TOP_DIRECTION,7,0,TOP_DIRECTION,8,0
                    dc.w    RIGHT_DIRECTION,8,0,RIGHT_DIRECTION,8,1,RIGHT_DIRECTION,8,2,RIGHT_DIRECTION,8,3,RIGHT_DIRECTION,8,4,RIGHT_DIRECTION,8,5,RIGHT_DIRECTION,8,6,RIGHT_DIRECTION,8,7,RIGHT_DIRECTION,8,8
                    dc.w    BOTTOM_DIRECTION,0,8,BOTTOM_DIRECTION,1,8,BOTTOM_DIRECTION,2,8,BOTTOM_DIRECTION,3,8,BOTTOM_DIRECTION,4,8,BOTTOM_DIRECTION,5,8,BOTTOM_DIRECTION,6,8,BOTTOM_DIRECTION,7,8,BOTTOM_DIRECTION,8,8
                    dc.w    LEFT_DIRECTION,0,0,LEFT_DIRECTION,0,1,LEFT_DIRECTION,0,2,LEFT_DIRECTION,0,3,LEFT_DIRECTION,0,4,LEFT_DIRECTION,0,5,LEFT_DIRECTION,0,6,LEFT_DIRECTION,0,7,LEFT_DIRECTION,0,8
SpearsIndexEnd
SpearsData          ds.w    108
SpearsDataEnd     
WarningFunctionTable:
                    dc.l    DrawWholeFrame,DrawTopFrame,DrawLeftFrame,DrawWholeFrame,DrawWholeFrame,DrawWholeFrame,DrawRightFrame,DrawWholeFrame,DrawWholeFrame,DrawBottomFrame
SpearCheckFunctionTable:
                    dc.l    StartSpearAttack,NoSpearAttack,NoSpearAttack,StartSpearAttack,StartSpearAttack,StartSpearAttack,NoSpearAttack,StartSpearAttack,StartSpearAttack,NoSpearAttack
SpearsAttackFunctionTable:
                    dc.l    0,UpdateTopSpears,UpdateLeftSpears,0,0,0,UpdateRightSpears,0,0,UpdateBottomSpears
ContainerCheckFunctionTable:
                    dc.l    NoContainerMove,StartContainerMove,StartContainerMove,NoContainerMove,NoContainerMove,NoContainerMove,StartContainerMove,NoContainerMove,NoContainerMove,StartContainerMove
ContainerMoveFunctionTable:
                    dc.l    0,UpdateContainerUpMove,UpdateContainerLeftMove,0,0,0,UpdateContainerRightMove,0,0,UpdateContainerDownMove
KeyPressFunctionTable:
                    dc.l    NoPress,PressLeft,PressRight,PressUp,PressDown             

Score               dc.b    00
SevenSegLEDArray    dc.b    $7E,$30,$6D,$79,$33,$5B,$5F,$70,$7F,$7B  
SevenSegIndexArray  dc.b    0,0,1,0 ;a
                    dc.b    1,0,1,1 ;b
                    dc.b    1,1,1,2 ;c
                    dc.b    1,2,0,2 ;d
                    dc.b    0,2,0,1 ;e
                    dc.b    0,1,0,0 ;f
                    dc.b    0,1,1,1 ;g
                    
Gap                 ds.b    1  
TopSpearBmp         INCBIN  "SpearTop.bmp"
RightSpearBmp       INCBIN  "SpearRight.bmp"
LeftSpearBmp        INCBIN  "SpearLeft.bmp"
BottomSpearBmp      INCBIN  "SpearBottom.bmp"
UserInputBmp        INCBIN  "UserInput.bmp"
TopSpearDBmp        INCBIN  "SpearTop-D.bmp"
RightSpearDBmp      INCBIN  "SpearRight-D.bmp"
LeftSpearDBmp       INCBIN  "SpearLeft-D.bmp"
BottomSpearDBmp     INCBIN  "SpearBottom-D.bmp"
ShootSound          dc.b    'Shoot.wav',0

    END    START

































*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
