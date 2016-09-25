'TAMSAT Transponder Code 
'Author : Baris DINC - 2012, Burcu AYBAK - 2016 
'Device : 18F24K22
'OSC    : 4 Mhz (will be replaced by 10.20 Mhz)

'Device 18F24K20
Device 18F24K22
'Device 18F2550
Xtal 4  

Config_Start
    FOSC        = xt                              ' HSHP ' Oscillator Selection HS
    'OSCS       = Off                             ' Osc. Switch Enable Disabled
    PLLCFG      = OFF
    PRICLKEN    = On
    FCMEN       = Off
    IESO        = OFF
    PWRTEN      = On                              ' Power-up Timer Enabled
    'BOR        = Off                             ' Brown-out Reset Disabled
    BOREN       = SBORDIS
    BORV        = 190                             ' Brown-out Voltage 2.5V
    WDTEN       = Off                             ' Watchdog Timer Disabled
    WDTPS       = 128                             ' Watchdog Postscaler 1:128
    CCP2MX      = PORTC1                          ' CCP2 MUX Enable (RC1)
    STVREN      = OFF                             ' Stack Overflow Reset Disabled
    LVP         = Off                             ' Low Voltage ICSP Disabled
    'DEBUG      = Off                             ' Background Debugger Enable Disabled
    MCLRE       = INTMCLR
    CP0         = Off                             ' Code Protection Block 0 Disabled
    CP1         = Off                             ' Code Protection Block 1 Disabled
    CPB         = Off                             ' Boot Block Code Protection Disabled
    CPD         = Off                             ' Data EEPROM Code Protection Disabled
    WRT0        = Off                             ' Write Protection Block 0 Disabled
    WRT1        = Off                             ' Write Protection Block 1Disabled
    WRTB        = Off                             ' Boot Block Write Protection Disabled
    WRTC        = Off                             ' Configuration Register Write Protection Disabled
    WRTD        = Off                             ' Data EEPROM Write Protection Disabled
    EBTR0       = Off                             ' Table Read Protection Block 0 Disabled
    EBTR1       = Off                             ' Table Read Protection Block 1 Disabled
    EBTRB       = Off                             ' Boot Block Table Read Protection Disabled
Config_End

Symbol SPACE         = 0
Symbol LAB           = 1
Symbol SA            = 3                          'Stand Alone, (Transponder) 
Symbol TR_ON         = 1                          'transponder on
Symbol TR_OFF        = 2                          'transponder off
Symbol AGC8317IN     = PORTA.1
Symbol ACS714_5V     = PORTA.2
Symbol PLL_LD        = PORTA.3
Symbol TPS2421EN     = PORTA.4
Symbol PWRLED        = PORTA.5
Symbol SCL2          = PORTB.1
Symbol SDA2          = PORTB.2
Symbol PLL_CLK       = PORTB.3
Symbol PLL_DATA      = PORTB.4
Symbol PLL_LE        = PORTB.5
Symbol PLL_PSRF      = PORTB.6
Symbol PLL_PSIF      = PORTB.7
Symbol LD29300EN     = PORTC.0
Symbol TPS3823WDI    = PORTC.1
Symbol AD8317AGCSET  = PORTC.2
Symbol SCL1          = PORTC.3
Symbol SDA1          = PORTC.4
Symbol AD8317FINAL   = PORTC.7
Symbol GIE           = INTCON.7                   ' Global Interrupt Enable Bit  
Symbol TMR1_VAL      = 64536                      ' Set the initial value of TMR1  
Symbol TMR1_MS       = 1                          ' Time period of TMR1  
Symbol TIMER1        = TMR1L.Word                 ' A special way of addressing both TMR1L and TMR1H with one register 
Symbol TMR1_ENABLE   = PIE1.0                     ' TMR1 interrupt enable 
Symbol TMR1_OVERFLOW = PIR1.0                     ' TMR1 overflow flag 
Symbol TMR1_ON       = T1CON.0                    ' Enables TMR1 to start incrementing           
Symbol SSPIF         = PIR1.3                     ' SSP (I2C) interrupt flag
Symbol SSPIP         = IPR1.3                     ' SSP (I2C) Interrupt Priority bit 1 = High priority
Symbol SSPIE         = PIE1.3                     ' SSP (I2C) Interrupt enable
Symbol BF            = SSPSTAT.0                  ' SSP (I2C) Buffer Full
Symbol R_W           = SSPSTAT.2                  ' SSP (I2C) Read/Write
Symbol D_A           = SSPSTAT.5                  ' SSP (I2C) Data/Address
Symbol CKP           = SSPCON1.4                  ' SSP (I2C) SCK Release Control
Symbol SSPEN         = SSPCON1.5                  ' SSP (I2C) Enable
Symbol SSPOV         = SSPCON1.6                  ' SSP (I2C) Receive Overflow Indicator
Symbol WCOL          = SSPCON1.7                  ' SSP (I2C) Write Collision Detect
Symbol SMP           = SSPSTAT.7                  ' SSP (I2C) Rate Control
Symbol SEN           = SSP1CON2.0                 ' clock strecthing enabled
Symbol AHEN          = SSP1CON3.1                 ' address hold            
Symbol PEIE          = INTCON.6                   ' Peripheral Interrupt Enable same as GIEL
'Symbol IPEN = RCON.7                             ' Interrupt Priority Enable bit

Dim TR_MD               As Byte
Dim TRANSPONDER_MODE    As Byte
Dim FREQ_IN             As Word                   ' Frequency of VCO ( MHz )
Dim FREQ_OUT            As Word                   ' Frequency of VCO ( KHz )
Dim FREQ_STEP           As Word                   ' Frequency of Step ( KHz )
Dim REF_OSC             As Word                   ' Frequency of Referance ( KHz )
Dim A_COUNTER           As Word                   ' Value of A
Dim N_COUNTER           As Word                   ' Value of N
Dim R_COUNTER           As Word                   ' Value of R
Dim DIVISION_RATIO      As Word              
Dim DATAOUT             As Dword
Dim COUNT_VAR           As Byte
Dim SEC_WAIT            As Byte
Dim TPS_CURRENT         As Word
Dim PWM_VAL             As Byte
Dim OUTPUT_POWER        As Word
Dim MILI_SEC            As Word
Dim SECONDS             As Byte
Dim MINUTES             As Byte
Dim HOURS               As Byte
Dim DAYS                As Byte
Dim WEEKS               As Byte
Dim DAYCOUNT            As Byte
Dim LASTDATA            As Byte
Dim SLAVE_ADDRESS       As Byte                   ' Initialise I2C slave mode
Dim I2C_DATA[10]        As Byte                   ' Array for I2C Values
Dim I2C_DATACOUNT       As Byte                   ' Counter for I2C
Dim STATE               As Byte                       
SLAVE_ADDRESS = $14

All_Digital   = true

Declare CCP1_Pin PORTC.2                          ' AD8317 AGC set pin
Declare CCP2_Pin PORTC.7                          ' AD8317 final power

TRISA.0 = 1                                       ' read power over AD8317 (final part)
TRISA.1 = 1                                       ' read power over AD8317 (AGC part)
TRISA.2 = 1                                       ' 5V out of ACS714 LLCTR
TRISA.3 = 1                                       ' MB1503 Lock Detect
TRISA.4 = 0                                       ' TPS2421 Enable leg
TRISA.5 = 0                                       ' Has been made for test with LED !!! Change Before Launch !!! Don't forget to made INPUT at the end.
TRISB.0 = 1                                       ' blank
TRISB.1 = 1                                       ' SCL2
TRISB.2 = 1                                       ' SDA2
TRISB.3 = 0                                       ' MB1503 Clock
TRISB.4 = 0                                       ' MB1503 Data
TRISB.5 = 0                                       ' MB1503 LE
TRISB.6 = 0                                       ' MB1503 PSRF  High=normal Low=powersave
TRISB.7 = 0                                       ' MB1503 PSIF  High=normal Low=powersave
TRISC.0 = 0                                       ' LD29300 enable (high=enable)
TRISC.1 = 0                                       ' TPS3823 WDI
TRISC.2 = 0                                       ' AD8317 AGC Vset
TRISC.3 = 1                                       ' SCL1
TRISC.4 = 1                                       ' SDA1
TRISC.5 = 1                                       ' blank
TRISC.6 = 1                                       ' blank
TRISC.7 = 0                                       ' AD8317 Vset Final
'SSP1ADD = SLAVE_ADDRESS                          ' Set our Address
'SSP1CON2 = 0                                     ' General call address disabled
'SSP1CON1 = $36                                   ' Set to I2C slave with 7-bit address
SSPADD = SLAVE_ADDRESS                            ' Set our Address
SSPCON2 = 0                                       ' General call address disabled
SSPCON1 = $36                                     ' Set to I2C slave with 7-bit address
T1CON.1 = 0                                       ' 1 = External clock from pin RC0/T1OSO/T1CKI (on the rising edge)  ' 0 = Internal clock (FOSC/4)  'TRISC.0 = 1 ' If External clock, then set clock as an input  'HPWM 1,128,32000 ' Set TMR1's External Source   T1CON.2 = 1 ' 1 = Do not synchronize external clock input  ' 0 = Synchronize external clock input  ' When T1CON.1 = 0;  ' this bit is ignored. Timer1 uses the internal clock when TMR1CS = 0.  
T1CON.4 = 0                                       ' 11 = 1:8 prescale value  T1CON.5 = 0 ' 10 = 1:4 prescale value  ' 01 = 1:2 prescale value  ' 00 = 1:1 prescale value  Timer1 = TMR1_Val

'MARK: Set Startup Values
SEN         = 1
TMR1_ENABLE = 0
PEIE        = 1                                   ' Peripheral Interrupts
SSPIF       = 0                                   ' clear SSP1 flag 
SSPIE       = 1                                   ' enable the Interrupt     
SMP         = 1                                   ' set the rate to 100KHz
TMR1_ENABLE = 1 
TMR1_ON     = 1  
GIE         = 1

DelayMS 500

GoTo PreMain
On_Interrupt GoTo InterruptSection

'*** InterruptSection Begin
InterruptSection:
Context Save
 GIE = 0  
 If TMR1_OVERFLOW = 1 And TMR1_ENABLE = 1 Then
     TMR1_ENABLE = 0
     TIMER1 = TIMER1 + TMR1_VAL
     TMR1_ENABLE = 1
     TMR1_OVERFLOW = 0
     MILI_SEC = MILI_SEC + TMR1_MS
     If MILI_SEC >= 1000 Then
         'MILI_SEC = MILI_SEC - 1000
         MILI_SEC = 0
         SECONDS = SECONDS + 1
         If SECONDS >= 60 Then 
             SECONDS = 0
             MINUTES = MINUTES + 1
             If MINUTES >= 60 Then
                MINUTES = 0
                HOURS = HOURS + 1
                If HOURS >= 24 Then
                    HOURS = 0
                    DAYS = DAYS + 1
                    If DAYS >= 7 Then 
                        DAYS = 0
                        WEEKS = WEEKS + 1
                        If WEEKS = 52 Then WEEKS = 0
                    EndIf
                EndIf
             EndIf
         EndIf
     EndIf
 EndIf 
  
 If SSPIF = 1 Then
    SSPIF = 0                                   ' clear interrupt flag
'    If SSP1STAT.4 = 1 Then I2C_DataCount = 0   ' stop sign received, reset counter
    If SSPSTAT.4 = 1 Then I2C_DATACOUNT = 0     ' stop sign received, reset counter

    If R_W = 1 Then                             ' master will send data
        SSP1BUF = 0
        SSP1BUF = STATE
        CKP = 1
    Else
        STATE = 0xFF
        If BF = 1 Then                          ' data received, buffer is full
           LASTDATA = SSPBUF                    ' read data 
           I2C_DATA[I2C_DATACOUNT] = LASTDATA
           GoSub ZamanSifirla                   ' ******** reset time counter on I2C Data Received
           Inc I2C_DATACOUNT
           Select I2C_DATA[0]
               Case 0x15
                    TR_MD = TR_ON               ' open transponder
                    STATE = 0x0A
                    I2C_DATACOUNT = 0
               Case 0x16
                    TR_MD = TR_OFF              ' close transponder
                    STATE = 0x0A
                    I2C_DATACOUNT = 0
               Case 0x17
                    STATE = 0xFF
                    If TR_MD = TR_ON  Then STATE = 0x15
                    If TR_MD = TR_OFF Then STATE = 0x16
                    I2C_DATACOUNT = 0
               Case 0x18
                    STATE = TPS_CURRENT
                    I2C_DATACOUNT = 0
               Case 0x1A
                    PWM_VAL = 5
                    STATE = PWM_VAL
                    I2C_DATACOUNT = 0
               Case 0x1B
                    PWM_VAL = 64
                    STATE = PWM_VAL
                    I2C_DATACOUNT = 0
               Case 0x1C
                    PWM_VAL = 127
                    STATE = PWM_VAL
                    I2C_DATACOUNT = 0
               Case 0x20
                    STATE = OUTPUT_POWER
                    I2C_DATACOUNT = 0
           EndSelect
           If SSPOV = 1 Then SSPOV = 0
        EndIf
    EndIf
' clear I2C collision and errors
 If R_W = 0 And SSPOV = 1 Then  SSPOV = 0 
 CKP = 1
 If R_W = 1 And WCOL = 1 Then WCOL = 0
 EndIf
 GIE = 1
Context Restore
'*** InterruptSection End

'*** PreMain Begin
PreMain:
' reset time counters after every reset.
SEC_WAIT = 15
PWM_VAL= 5
I2C_DATACOUNT = 0
STATE = 0              
TR_MD = TR_OFF                              ' set state on first open. If we are in the lab, first value must be ON because there isn't anybody to send i2c data
TRANSPONDER_MODE = LAB                      ' !!! Change Before Launch !!! Parameters: LAB/SPACE
HPWM 1,PWM_VAL,2000                         ' %5 duty cycle with 2Khz to AD9317 AGCset port for test (maximum gain)
MINUTES = 0
SECONDS = 0
DAYCOUNT = 14                               ' If there isn't any data received along 14 days, we will open ourself

                                            ' Exit PLL from LOW-POWER mode   *** TODO: low power mode will be activated
Low PLL_PSRF
Low PLL_PSIF
DelayMS 10
Low PLL_LE
High PLL_PSRF                                ' low power mode closed
High PLL_PSIF                                ' low power mode closed

                                            ' !!! Change Before Launch !!! If we are in the lab, give energy to transponder 
'If TRANSPONDER_MODE = SA Then
'    Low  TPS2421en
'   'High LD29300EN
'EndIf 
GoSub Pll_Programla                         ' Load first values
'*** PreMain End

'*** Main Begin
Main:
If DAYS >= DAYCOUNT Then
   If DAYS < 21 Then
      TR_MD = TR_ON
      If MINUTES  > 6 Then 
        TR_MD = TR_OFF
      Else If MINUTES > 12 Then
        TR_MD = TR_ON
      Else If MINUTES > 18 Then
        TR_MD = TR_OFF
      Else If MINUTES > 24 Then
        TR_MD = TR_ON
      Else If MINUTES > 30 Then
        TR_MD = TR_OFF
      Else If MINUTES > 36 Then
        TR_MD = TR_ON
      Else If MINUTES > 42 Then
        TR_MD = TR_OFF
      Else If MINUTES > 48 Then
        TR_MD = TR_ON
      Else If MINUTES > 54 Then
        TR_MD = TR_OFF
      EndIf
   Else
      TR_MD = TR_OFF
      'PWRled = 0
      DAYS = 12
   EndIf
EndIf

Dim say As Byte

For say = 1 To 2                            ' !!! Change Before Launch !!! Don't forget to set this 20. It makes noise.
    If TR_MD = TR_ON Then                   ' Check energy of system.
        Low  TPS2421EN
        High LD29300EN
    Else
        High TPS2421EN
        Low LD29300EN                       ' In this state PLL and the others also PIC if it is possible change state to no power mode.
    EndIf                                            
    TPS_CURRENT = ADIn 1                    ' We can generate working state error code using this current value.
    TPS_CURRENT = TPS_CURRENT >> 2
    OUTPUT_POWER = ADIn 2                   ' Read output power from here
    OUTPUT_POWER = OUTPUT_POWER >> 2    
    'If TPS_CURRENT > 2048 Then 
    '    High PORTC.6 
    'Else 
    '    Low PORTC.6    
    'EndIf

    'if SEC_WAIT.0 = 1 then 
     '   Toggle TPS3823WDI                  ' Inform WatchDog
     '   'SEC_WAIT = 10
            
    'endif
    'TPS3823WDI = MILI_SEC.7
    DelayMS 250
    Toggle TPS3823WDI
    DelayMS 250
    Toggle TPS3823WDI
Next say
    
    GoSub Pll_Programla
GoTo Main
'*** Main End

'*** Pll_Programla Begin
Pll_Programla:                              ' Get frequency from outside and put calculation part in to code
                                            ' Parameters for If: OSC =4Mhz, Freq Range 230-235Mhz, M=16, ChSpacing=10Khz, FRQ=232.810Mhz (Ch 281) //Be carefull it must be 815
                                            ' send IF reference clock value to PLL
                      '12345678901234567890123
    DATAOUT =  %000000000000000100110000010000
    GoSub Pllgonder
                                            ' send IF swallow counter values to PLL
                      '12345678901234567890123
    DATAOUT =  %000000001101100000011110101101
    GoSub Pllgonder
                                            ' Parameters for RF: OSC =4Mhz, Freq Range 348-349Mhz, M=64, ChSpacing=25Khz, FRQ=348.375Mhz (Ch 15) A:47 N:217  R:160  FC:1 LDS:0 Bit19:1
                                            ' send RF reference clock value to PLL
                      '12345678901234567890123
    DATAOUT =  %000000010000000010100000010000
    GoSub Pllgonder
                                            ' send RF swallow counter values to PLL
                      '12345678901234567890123
    DATAOUT =  %000000011011111101010011011000
    GoSub Pllgonder

    Return
'*** Pll_Programla End

'*** Pllgonder Begin
Pllgonder:                                  ' sends data from Data and CLK ports to PLL
                                            ' In: data in the DataOut variable, Out: serial data from PLL_DATA, PLL_CLK
                                            ' For IF/RF reference counter: CN1-CN2-T1-T2-R1-R2-R3-R4-R5-R6-R7-R8-R9-R10-R11-R12-R13-R14-CS--X-X-X-X
                                            ' For IF/RF swallow counter: CN1-CN2-LDS-SW-FC-A1-A2-A3-A4-A5-A6-A7-N1-N2-N3-N4-N5-N6-N7-N8-N9-N10-N11
    For COUNT_VAR = 1 To 23
        Low PLL_DATA
        If (DATAOUT & 1) = 1 Then High PLL_DATA
        DATAOUT = DATAOUT >> 1
        DelayUS 10
        High PLL_CLK
        DelayUS 10
        Low PLL_CLK
        DelayUS 10
    Next COUNT_VAR

    High PLL_LE
    DelayUS 10
    Low PLL_LE                               ' set enable to 0
    DelayUS 10
Return
'*** Pllgonder End

'*** ZamanSifirla Begin
ZamanSifirla:
    SECONDS = 0
    MINUTES = 0
    HOURS   = 0
    DAYS    = 0
    WEEKS  = 0
    'TR_MD = TR_OFF                          ' For all possibilities we will close the transponder.
    DAYCOUNT = 14                            ' If there isn't any data received along 14 days, we will open ourself. If I2C data received, count again for 14 days.
Return
'*** ZamanSifirla End

'I2C interruptini buraya yazacagim
' I2C base address 14
' acma komutu 0x15
' kapama komutu 0x16
'
 
' I2C adresi read write biti dahil olmadan 0x14 (7-bit).
' I2C bus hizimiz 100kHz.
' Biz size a\E7ma-kapama komutu g\F6nderdikten sonra sizden OK (0x0A) ya da ERROR (0xFF) bekleyecegiz.

'\D6rnek Haberlesme:
'OBC: I2C START
'OBC: I2C Adresi (0x15) + Read-Write biti (WRITE)
'TAMSAT: ACK
'OBC: 0x15 (Transponder A\E7ma Komutu) veya 0x16 (Transponder Kapama Komutu)
'TAMSAT: ACK
'OBC: I2C STOP 
'
'100 milisaniye bekleme.
'
'OBC: I2C START
'OBC: I2C Adresi (0x15) + Read-Write biti (READ)
'TAMSAT: 0x0A (Eger Komut alinmissa), 0xFF (Eger  Komut alinmamissa)
'OBC: I2C STOP
'
'
'Biz komut g\F6ndermeden veri istedigimizde 0xFF d\F6nmesi lazim. 0x0A ve 0xFF sadece komut alindi mi emin olmak i\E7in.
