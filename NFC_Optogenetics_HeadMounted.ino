 /*  
    This sript runs the firmware of the NFC-Optogenetics on an ATtiny84 @ 1MHz.
    It connects to a M24LR04E NFC RFID chip via TinyWireM library using I2C communication protocol.
    The NFC memory can be writen wirelessly via NFC, and the microcontroller will
    update the working parameters upon interruption (RF WIP).
    Four channels have been programed to work independently.
    Intensity modulation control on individual operation, 10 us resolution possible.

    Indicator has a 1000 ms @ 10 % period of the idle state and
    it copies the actual period and dc from the active channel in the active state.

    Author: Abraham Vázquez-Guardado.
    Center for Bio-Integrated Electronics
    Northwestern University
    Evanston, IL. 2020.

    Last Revision: Nov 3rd 2020
*/

// Include libraries
#include <avr/io.h>
#include <TinyWireM.h>

void InitTimer0(void);
void StopTimer0(void);
void StartTimer0(void);
void InitTimer1(unsigned int T, unsigned int DC);
void StopTimer1(void);
void StartTimer1(void);
void ScreenMode(char MODE0);
void PresentPassword(char DEV_ADDR);
void TinyReadI2CPage(char *DATA, char DEV_ADDR, int DATA_ADDR);
void TinyWriteI2CByte(char DATA, char DEV_ADDR, int DATA_ADDR);
void TinyWriteI2CPage(char *DATA, char DEV_ADDR, int DATA_ADDR);
void SetOperationMode(char *DATA);
void InitPeriodsDutyCycles(void);
void InitMemory(void);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Define device specific addressess for ports
# define      DDR_Channels      DDRA
# define      PORT_Channels     PORTA
# define      DDR_Indicator     DDRB
# define      PORT_Indicator    PORTB

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Define contant and variables
const byte    Indicator = PINB0;
const byte    CH3 = PINA3;
const byte    CH2 = PINA2;
const byte    CH1 = PINA1;
const byte    CH0 = PINA0;

unsigned int  CH0_T1 = 0, CH0_DC1 = 0, CH0_T2 = 0, CH0_DC2 = 0;
unsigned int  CH1_T1 = 0, CH1_DC1 = 0, CH1_T2 = 0, CH1_DC2 = 0;
unsigned int  CH2_T1 = 0, CH2_DC1 = 0, CH2_T2 = 0, CH2_DC2 = 0;
unsigned int  CH3_T1 = 0, CH3_DC1 = 0, CH3_T2 = 0, CH3_DC2 = 0;
unsigned int  T1_inPhase = 0, DC1_inPhase = 0;
unsigned int  T2_inPhase = 0, DC2_inPhase = 0;
unsigned int  T2_outPhase = 0, DC2_outPhase = 0;
unsigned int  t1 = 0, t2 = 0, t3 = 0, t4 = 0;

volatile byte FLAG0 = 0;        // This flag will trigger reconfig.
volatile byte MODE = 0;         // Mode of operation.
volatile byte MASK = 0;         // Mask to output.
volatile byte MASK0 = 0;        // Mask used for out of phase calculations
volatile byte MASK1 = 0;        // Mask to treat out of phase.
volatile byte MASK2 = 0;        // Mask for indicator.
volatile byte PHASE = 0;        // 0-out of phase, 1-in phase
volatile int  COUNT0 = 0;       
volatile int  COUNT1 = 0;
volatile int  COUNT2 = 0;
volatile int  COUNT3 = 0;
volatile int  BLINKT = 0;
volatile int  BLINKCNT = 0;
volatile byte ONOFF = 0;
volatile byte INDONOFF = 1;

unsigned char I2C_BUFFER[8]    = "EMPTYREG";               // I2C read buffer, up to 8 bytes.
char          *PTR;
byte          INIT = 0;
byte          PTEMP = 0;

// M24LR04E Memory addres for config registers
const byte RFID_ADDR           = 0x0A;        // Device I2C address
const byte RFID_DEV_I2C_ENBL   = 0x07;        // Device enable I2C Memory, to be used during device address assembly
const byte RFID_DEV_RF_ENBL    = 0x03;        // Device enable RF Memory, to be used during device address assembly
const byte RFID_DEV_SEL_I2C    = (RFID_ADDR << 3) | RFID_DEV_I2C_ENBL;
const byte RFID_DEV_SEL_RF     = (RFID_ADDR << 3) | RFID_DEV_RF_ENBL;

// M24LR04E Memory addresses for data
const int  RFID_CONF_BYTE_ADDR = 2320;    // Memory address of the config register
const int  RFID_UID_ADDR       = 2324;    // Memory address of the device UID
const int  RFID_CTRL_REG_ADDR  = 2336;    // Memory address of the control register
const int  RFID_WRT_LOCK_ADDR  = 2048;    // Memory address of the write lock bit
const int  RFID_I2C_PSSW_ADDR  = 2304;    // Memory address for the I2C password protection
const int  MODE_ADDR           = 0;       // Block address for reading data stored by the RF channel
const int  CH0_1_ADDR          = 4;       // They reside in sector 0
const int  CH0_2_ADDR          = 8;       // They reside in sector 0
const int  CH1_1_ADDR          = 12;
const int  CH1_2_ADDR          = 16;
const int  CH2_1_ADDR          = 20;
const int  CH2_2_ADDR          = 24;
const int  CH3_1_ADDR          = 28;
const int  CH3_2_ADDR          = 32;
const int  InPh1_ADDR          = 36;
const int  InPh2_ADDR          = 40;
const int  OutPh1_ADDR         = 44;
const int  OutPh2_ADDR         = 48;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

//------------------------------------------------------------------
//------------------------------------------------------------------
void setup() {

  //  delay(100);
  MCUCR |= 1 << PUD;
  // Set up outpout ports
  DDR_Indicator = (1 << Indicator); // Outputs PORTB0-4
  DDR_Channels = 0x0F;              // Input RF WIP (PA7), Indicator PORTA-0

  TIMSK1 = 0x00;
  TCCR1A = 0x00;
  TCCR1B = 0x00;

  // Initializes the I2C communication channel
  delay(250);
  TinyWireM.begin();

//  for (int i = 0; i <5; i++){  
//    bitClear(PORT_Indicator, Indicator); delay(150);
//    bitSet(PORT_Indicator, Indicator); delay(50);
//  }
  
  // Config RF/WIP output.
  PresentPassword(RFID_DEV_SEL_I2C);
  TinyWriteI2CByte(0x00, RFID_DEV_SEL_I2C, RFID_CTRL_REG_ADDR);
  TinyWriteI2CByte(0xF8, RFID_DEV_SEL_I2C, RFID_CONF_BYTE_ADDR);

  // Check if the memory is empty. This will be true when the first four bytes are 0xFF
  TinyReadI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, MODE_ADDR);

  if ((I2C_BUFFER[3] == 0xFF)) {
    bitClear(PORT_Indicator, Indicator); delay(50);
    bitSet(PORT_Indicator, Indicator); delay(50);
    bitClear(PORT_Indicator, Indicator); delay(50);
    bitSet(PORT_Indicator, Indicator);
    InitMemory();
    delay(1000);
    bitClear(PORT_Indicator, Indicator); delay(50);
    bitSet(PORT_Indicator, Indicator); delay(50);
    bitClear(PORT_Indicator, Indicator); delay(50);
    bitSet(PORT_Indicator, Indicator);
  }

  //  Load M24LR04E-R stored variables to the program, always before SetOperationMode
  //  InitPeriodsDutyCycles();

  // Set the mode of operation.
  //  TinyReadI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, MODE_ADDR);
  //  SetOperationMode(I2C_BUFFER);

  // Sets up an interruption on pin PINA7/PCINT7
  MCUCR = 0x00;
  GIMSK |= 1 << PCIE0;
  PCMSK0 |= 1 << PCINT7; //<<---------------------------------------|||||
  GIFR  = 0x00; // Clear flags

  // Initializes TIMER0 with 1 ms resolution
  InitTimer0();

  ONOFF = 0xFF;
  FLAG0 = 1;
  MASK = 1;

  MCUCR |= _BV(BODS) | _BV(BODSE);
  ADCSRA &= ~ bit(ADEN); // disable the ADC
  bitSet(PRR, PRADC); // power down the ADC
}

// Outputs were adjusgted to demo board
//------------------------------------------------------------------
//------------------------------------------------------------------
void loop() {

  while (MASK) {

    //    PORT_Channels = 0x00;
    StopTimer0();
    StopTimer1();
    delay(250);

    bitClear(PRR, PRUSI);       // enable USI h/w
    TinyWireM.begin();          // start wire library
    TinyReadI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, MODE_ADDR);
    SetOperationMode(I2C_BUFFER);
    INDONOFF = I2C_BUFFER[2];   // Sets indicator blinking or not

    StartTimer0();
    ScreenMode(I2C_BUFFER[1]);
    bitSet(PRR, PRUSI);         // disable USI h/w
    DDR_Channels = 0x0F;                // leave only channel pins as output

    MASK   = 0;
    COUNT0 = 0;
    COUNT1 = 0;
    COUNT2 = 0;
    COUNT3 = 0;
    BLINKCNT = 0;
    TCNT1H = 0x00;
    TCNT1L = 0x00;
    TCNT0 = 0x00;
    PORT_Channels = 0xF0;
    PORT_Channels |= MASK1;
    sei();

  }

  while (FLAG0) {

    switch (MODE) {
      case 0:
        if (COUNT0 == 100) {
          bitSet(PORT_Indicator, Indicator);
        }
        if (COUNT0 == 1000)  {
          PORT_Indicator &= ~((1 << Indicator) & (INDONOFF)); // Indicator/Optional
          COUNT0 = 0;
        }
        break;

      case 1:
        // Channel 0
        if (COUNT0 == CH0_DC1) {
          TIMSK1 = 0x00;  // Dissable interrupt timer 1
          bitClear(PORT_Channels, CH0);
          PORT_Indicator &= ~((1 << Indicator) & (INDONOFF)); // Indicator/Optional
          ONOFF = 0x00;
        }
        if (COUNT0 == CH0_T1)  {
          TIMSK1  = (1 << OCIE1A) | (1 << OCIE1B); // Enables interruption A and B.
          bitSet(PORT_Channels, CH0);
          bitSet(PORT_Indicator, Indicator);
          TCNT1H = 0x00;  TCNT1L = 0x00;
          COUNT0 = 0;     ONOFF = 0xFF;
        }
        break;

      case 2:
        // Channel 1
        if (COUNT0 == CH1_DC1) {
          TIMSK1 = 0x00;  // Dissable interrupt timer 1
          bitClear(PORT_Channels, CH1);
          PORT_Indicator &= ~((1 << Indicator) & (INDONOFF)); // Indicator/Optional
          ONOFF = 0x00;
        }
        if (COUNT0 == CH1_T1)  {
          TIMSK1  = (1 << OCIE1A) | (1 << OCIE1B); // Enables interruption A and B.
          bitSet(PORT_Channels, CH1);
          bitSet(PORT_Indicator, Indicator);
          TCNT1H = 0x00;  TCNT1L = 0x00;
          COUNT0 = 0;     ONOFF = 0xFF;
        }
        break;


      // Update dual mode with indicator
      case 3: case 5: case 6: case 9: case 10: case 12:
        if (PHASE == 0) {   // Out of Phase
          if (COUNT0 == t1) {
            PORT_Channels = 0xF0;
            //            PORT_Channels &= !MASK0;
            bitSet(PORT_Indicator, Indicator);  // Indicator
            MASK1 = MASK0;
            ONOFF = 0x00;
          }
          if (COUNT1 == t2) {
            PORT_Channels = 0xF0 + (MODE - MASK0);
            //            PORT_Channels |= MODE - MASK0;
            MASK1 = MODE - MASK0;
            TCNT1H = 0x00;  TCNT1L = 0x00;
            ONOFF = 0xFF;
          }
          if (COUNT2 == t3) {
            PORT_Channels = 0xF0;
            //            PORT_Channels &= !(MODE - MASK0);
            PORT_Indicator &= ~((1 << Indicator) & (INDONOFF)); // Indicator/Optional
            MASK1 = MODE - MASK0;
            ONOFF = 0x00;
          }
          if (COUNT3 == t4) {
            PORT_Channels = 0xF0 + MASK0;
            //            PORT_Channels |= MASK0;
            MASK1 = MASK0;
            COUNT0 = 0; COUNT1 = 0;
            COUNT2 = 0; COUNT3 = 0;
            TCNT1H = 0x00;  TCNT1L = 0x00;
            ONOFF = 0xFF;
          }

        } else {            // In phase
          if (COUNT0 == DC1_inPhase) {
            TIMSK1 = 0x00;  // Dissable interrupt timer 1
            PORT_Channels = 0xF0;
            bitSet(PORT_Indicator, Indicator);  // Indicator
            ONOFF = 0x00;
          }
          if (COUNT0 == T1_inPhase)  {
            TIMSK1  = (1 << OCIE1A) | (1 << OCIE1B); // Enables interruption A and B.
            MASK1 = MODE;
            PORT_Channels |= MODE - MASK0;
            PORT_Indicator &= ~((1 << Indicator) & (INDONOFF)); // Indicator/Optional
            TCNT1H = 0x00;  TCNT1L = 0x00;
            COUNT0 = 0;     ONOFF = 0xFF;
          }
        }
        break;
    }
    FLAG0 = 0;

  }

}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Initialize memory.
void InitMemory(void) {
  unsigned int P;

  I2C_BUFFER[0] = 0;
  I2C_BUFFER[1] = 0;
  I2C_BUFFER[2] = 1;    // Indicator is active
  I2C_BUFFER[3] = 0;
  TinyWriteI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, MODE_ADDR);

  // Channel 0 - - - - - - - - - - - - - - - - - - - - - - - - - - -
  P = 500;
  I2C_BUFFER[0] = (P / 2) & 0xFF;      // LSB Duty Cycle [ms]
  I2C_BUFFER[1] = (P / 2 >> 8) & 0xFF; // MSB Duty Cycle [ms]
  I2C_BUFFER[2] = P & 0xFF;            // LSB Period [ms]
  I2C_BUFFER[3] = (P >> 8) & 0xFF;     // MSB Period [ms]
  TinyWriteI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, CH0_1_ADDR);

  P = 500;
  I2C_BUFFER[0] = 100;               // Duty cycle [%]
  I2C_BUFFER[1] = P & 0xFF;          // LSB Period [us]
  I2C_BUFFER[2] = (P >> 8) & 0xFF;   // MSB Period [us]
  I2C_BUFFER[3] = 0x00;
  TinyWriteI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, CH0_2_ADDR);

  // Channel 1 - - - - - - - - - - - - - - - - - - - - - - - - - - -
  P = 500;
  I2C_BUFFER[0] = (P / 2) & 0xFF;      // LSB Duty Cycle [ms]
  I2C_BUFFER[1] = (P / 2 >> 8) & 0xFF; // MSB Duty Cycle [ms]
  I2C_BUFFER[2] = P & 0xFF;            // LSB Period [ms]
  I2C_BUFFER[3] = (P >> 8) & 0xFF;     // MSB Period [ms]
  TinyWriteI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, CH1_1_ADDR);

  P = 500;
  I2C_BUFFER[0] = 100;                // Duty cycle [%]
  I2C_BUFFER[1] = P & 0xFF;          // LSB Period [us]
  I2C_BUFFER[2] = (P >> 8) & 0xFF;   // MSB Period [us]
  I2C_BUFFER[3] = 0x00;
  TinyWriteI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, CH1_2_ADDR);

  // Channel 2 - - - - - - - - - - - - - - - - - - - - - - - - - - -
  P = 500;
  I2C_BUFFER[0] = (P / 2) & 0xFF;      // LSB Duty Cycle [ms]
  I2C_BUFFER[1] = (P / 2 >> 8) & 0xFF; // MSB Duty Cycle [ms]
  I2C_BUFFER[2] = P & 0xFF;            // LSB Period [ms]
  I2C_BUFFER[3] = (P >> 8) & 0xFF;     // MSB Period [ms]
  TinyWriteI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, CH2_1_ADDR);

  P = 500;
  I2C_BUFFER[0] = 100;               // Duty cycle [%]
  I2C_BUFFER[1] = P & 0xFF;          // LSB Period [us]
  I2C_BUFFER[2] = (P >> 8) & 0xFF;   // MSB Period [us]
  I2C_BUFFER[3] = 0x00;
  TinyWriteI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, CH2_2_ADDR);

  // Channel 3 - - - - - - - - - - - - - - - - - - - - - - - - - - -
  P = 500;
  I2C_BUFFER[0] = (P / 2) & 0xFF;      // LSB Duty Cycle [ms]
  I2C_BUFFER[1] = (P / 2 >> 8) & 0xFF; // MSB Duty Cycle [ms]
  I2C_BUFFER[2] = P & 0xFF;            // LSB Period [ms]
  I2C_BUFFER[3] = (P >> 8) & 0xFF;     // MSB Period [ms]
  TinyWriteI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, CH3_1_ADDR);

  P = 500;
  I2C_BUFFER[0] = 100;               // Duty cycle [%]
  I2C_BUFFER[1] = P & 0xFF;          // LSB Period [ms]
  I2C_BUFFER[2] = (P >> 8) & 0xFF;   // MSB Period [ms]
  I2C_BUFFER[3] = 0x00;
  TinyWriteI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, CH3_2_ADDR);

  // Multichannel - - - - - - - - - - - - - - - - - - - - - - - - -
  P = 500;
  I2C_BUFFER[0] = 240 & 0xFF;      // LSB Duty Cycle [ms]
  I2C_BUFFER[1] = (240  >> 8) & 0xFF; // MSB Duty Cycle [ms]
  I2C_BUFFER[2] = P & 0xFF;            // LSB Period [ms]
  I2C_BUFFER[3] = (P >> 8) & 0xFF;     // MSB Period [ms]
  TinyWriteI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, InPh1_ADDR);
  TinyWriteI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, OutPh1_ADDR);

  I2C_BUFFER[0] = 100;               // Duty cycle [%]
  I2C_BUFFER[1] = P & 0xFF;          // LSB Period [us]
  I2C_BUFFER[2] = (P >> 8) & 0xFF;   // MSB Period [us]
  I2C_BUFFER[3] = 0x00;
  TinyWriteI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, InPh2_ADDR);
  TinyWriteI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, OutPh2_ADDR);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Initializes time values, this will be updated after the RF write
// The period and duty cycle (1) for each channel is encoded in
// two separate bytes. Those corresponding to (2) are DC (one byte)
// and T (two bytes). This only happens at start-up.
void InitPeriodsDutyCycles(void) {
  unsigned int T, DC;

  // Sets for channel 0 - - - - - - - - - - - - - - - - - - - - - - -
  TinyReadI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, CH0_1_ADDR);
  CH0_T1 = (I2C_BUFFER[3] << 8) + I2C_BUFFER[2] + 1;
  CH0_T1 += CH0_T1 / 50;
  CH0_DC1 = (I2C_BUFFER[1] << 8) + I2C_BUFFER[0] + 1;
  CH0_DC1 += CH0_DC1 / 50;

  TinyReadI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, CH0_2_ADDR);
  CH0_T2 = (I2C_BUFFER[2] << 8) + I2C_BUFFER[1];
  CH0_DC2 = I2C_BUFFER[0];

  // Sets for channel 1 - - - - - - - - - - - - - - - - - - - - - - -
  TinyReadI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, CH1_1_ADDR);
  CH1_T1 = (I2C_BUFFER[3] << 8) + I2C_BUFFER[2] + 1;
  CH1_T1 += CH1_T1 / 50;
  CH1_DC1 = (I2C_BUFFER[1] << 8) + I2C_BUFFER[0] + 1;
  CH1_DC1 += CH1_DC1 / 50;

  TinyReadI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, CH1_2_ADDR);
  CH1_T2 = (I2C_BUFFER[2] << 8) + I2C_BUFFER[1];
  CH1_DC2 = I2C_BUFFER[0];

  // Sets for channel 2 - - - - - - - - - - - - - - - - - - - - - - -
  TinyReadI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, CH2_1_ADDR);
  CH2_T1 = (I2C_BUFFER[3] << 8) + I2C_BUFFER[2] + 1;
  CH2_T1 += CH2_T1 / 50;
  CH2_DC1 = (I2C_BUFFER[1] << 8) + I2C_BUFFER[0] + 1;
  CH2_DC1 += CH2_DC1 / 50;

  TinyReadI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, CH2_2_ADDR);
  CH2_T2 = (I2C_BUFFER[2] << 8) + I2C_BUFFER[1];
  CH2_DC2 = I2C_BUFFER[0];

  // Sets for channel 3 - - - - - - - - - - - - - - - - - - - - - - -
  TinyReadI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, CH3_1_ADDR);
  CH3_T1 = (I2C_BUFFER[3] << 8) + I2C_BUFFER[2] + 1;
  CH3_T1 += CH3_T1 / 50;
  CH3_DC1 = (I2C_BUFFER[1] << 8) + I2C_BUFFER[0] + 1;
  CH3_DC1 += CH3_DC1 / 50;

  TinyReadI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, CH3_2_ADDR);
  CH3_T2 = (I2C_BUFFER[2] << 8) + I2C_BUFFER[1];
  CH3_DC2 = I2C_BUFFER[0];

  // Sets for in phase config - - - - - - - - - - - - - - - - - - - -
  TinyReadI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, InPh1_ADDR);
  T1_inPhase = (I2C_BUFFER[3] << 8) + I2C_BUFFER[2] + 1;
  T1_inPhase += T1_inPhase / 50;
  DC1_inPhase = (I2C_BUFFER[1] << 8) + I2C_BUFFER[0] + 1;
  DC1_inPhase += DC1_inPhase / 50;

  TinyReadI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, InPh2_ADDR);
  T2_inPhase = (I2C_BUFFER[2] << 8) + I2C_BUFFER[1];
  DC2_inPhase = I2C_BUFFER[0];

  // Sets for out of phase config - - - - - - - - - - - - - - - - - -
  TinyReadI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, OutPh1_ADDR);
  T = (I2C_BUFFER[3] << 8) + I2C_BUFFER[2] + 1;
  T += T / 50;
  DC = (I2C_BUFFER[1] << 8) + I2C_BUFFER[0] + 1;
  DC += DC / 50;
  t1 = DC;
  t2 = T / 2;
  t3 = t1 + t2;
  t4 = T;

  TinyReadI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, OutPh2_ADDR);
  T2_outPhase = (I2C_BUFFER[2] << 8) + I2C_BUFFER[1];
  DC2_outPhase = I2C_BUFFER[0];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Set Operation mode. This will scan the I2C Buffer and set up the
// corresponding parameters.
void SetOperationMode(char *DATA) {

  DATA += 1;              // Increases to position two the array
  MODE = *DATA;           // Gets the mode of operation
  DATA -= 1;              // Returns to position one in the array
  MASK1 = MODE;

  // Check if individual operation
  switch (*DATA) {

    case 0x00:  //Individual operation mode

      break;

    case 0x01:  // Multiple but out of phase
      PHASE = 0;
      MASK0 = (MODE - 1) & 0x0E;
      if (MODE == 12) {
        MASK0 = 0x08;
      }
      MASK1 = MASK0;
      break;

    case 0x11:  // Multiple but in phase
      PHASE = 1;
      MASK0 = (MODE - 1) & 0x0E;
      if (MODE == 12) {
        MASK0 = 0x08;
      }
      break;
  }

}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Initializes timer 1 with the proper values for T and DC. Still
// needs the function StartTimer1(). It will also update the
// corresponding timing for the selected channel combination.
void ScreenMode(char MODE0) {
  unsigned int T, DC;

  switch (MODE0) {

    case 1:  // Updates for channel 0 - - - - - - - - - - - - - - - -
      TinyReadI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, CH0_1_ADDR);
      CH0_T1 = (I2C_BUFFER[3] << 8) + I2C_BUFFER[2] + 1;
      CH0_T1 += CH0_T1 / 50;
      CH0_DC1 = (I2C_BUFFER[1] << 8) + I2C_BUFFER[0] + 1;
      CH0_DC1 += CH0_DC1 / 50;

      TinyReadI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, CH0_2_ADDR);
      CH0_T2 = (I2C_BUFFER[2] << 8) + I2C_BUFFER[1];
      CH0_DC2 = I2C_BUFFER[0];
      if (CH0_DC2 < 100) {
        InitTimer1(CH0_T2, CH0_DC2);
      }
      if (CH0_DC1 >= CH0_T1) {
        StopTimer0();
      }
      break;

    case 2:   // Updates for channel 1 - - - - - - - - - - - - - - - -
      TinyReadI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, CH1_1_ADDR);
      CH1_T1 = (I2C_BUFFER[3] << 8) + I2C_BUFFER[2] + 1;
      CH1_T1 += CH1_T1 / 50;
      CH1_DC1 = (I2C_BUFFER[1] << 8) + I2C_BUFFER[0] + 1;
      CH1_DC1 += CH1_DC1 / 50;

      TinyReadI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, CH1_2_ADDR);
      CH1_T2 = (I2C_BUFFER[2] << 8) + I2C_BUFFER[1];
      CH1_DC2 = I2C_BUFFER[0];
      if (CH1_DC2 < 100) {
        InitTimer1(CH1_T2, CH1_DC2);
      }
      if (CH1_DC1 >= CH1_T1) {
        StopTimer0();
      }
      break;

    case 4:   // Updates for channel 2 - - - - - - - - - - - - - - - -
      TinyReadI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, CH2_1_ADDR);
      CH2_T1 = (I2C_BUFFER[3] << 8) + I2C_BUFFER[2] + 1;
      CH2_T1 += CH2_T1 / 50;
      CH2_DC1 = (I2C_BUFFER[1] << 8) + I2C_BUFFER[0] + 1;
      CH2_DC1 += CH2_DC1 / 50;

      TinyReadI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, CH2_2_ADDR);
      CH2_T2 = (I2C_BUFFER[2] << 8) + I2C_BUFFER[1];
      CH2_DC2 = I2C_BUFFER[0];
      if (CH2_DC2 < 100) {
        InitTimer1(CH2_T2, CH2_DC2);
      }
      if (CH2_DC1 >= CH2_T1) {
        StopTimer0();
      }
      break;

    case 8:   // Updates for channel 3 - - - - - - - - - - - - - - - -
      TinyReadI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, CH3_1_ADDR);
      CH3_T1 = (I2C_BUFFER[3] << 8) + I2C_BUFFER[2] + 1;
      CH3_T1 += CH3_T1 / 50;
      CH3_DC1 = (I2C_BUFFER[1] << 8) + I2C_BUFFER[0] + 1;
      CH3_DC1 += CH3_DC1 / 50;

      TinyReadI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, CH3_2_ADDR);
      CH3_T2 = (I2C_BUFFER[2] << 8) + I2C_BUFFER[1];
      CH3_DC2 = I2C_BUFFER[0];
      if (CH3_DC2 < 100) {
        InitTimer1(CH3_T2, CH3_DC2);
      }
      if (CH3_DC1 >= CH3_T1) {
        StopTimer0();
      }
      break;

    case 3: case 5: case 6: case 9: case 10: case 12:
      if (PHASE == 0) { // Updates for out of phase - - - - - - - - - - - - - - - -
        TinyReadI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, OutPh1_ADDR);
        T = (I2C_BUFFER[3] << 8) + I2C_BUFFER[2] + 1;
        T += T / 50;
        DC = (I2C_BUFFER[1] << 8) + I2C_BUFFER[0] + 1;
        DC += DC / 50;
        t1 = DC;
        t2 = T / 2;
        t3 = t1 + t2;
        t4 = T;

        TinyReadI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, OutPh2_ADDR);
        T2_outPhase = (I2C_BUFFER[2] << 8) + I2C_BUFFER[1];
        DC2_outPhase = I2C_BUFFER[0];
        if (DC2_outPhase < 100) {
          InitTimer1(T2_outPhase, DC2_outPhase);
        }
        break;

      } else { // Updates for in phase
        TinyReadI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, InPh1_ADDR);
        T1_inPhase = (I2C_BUFFER[3] << 8) + I2C_BUFFER[2] + 1;
        T1_inPhase += T1_inPhase / 50;
        DC1_inPhase = (I2C_BUFFER[1] << 8) + I2C_BUFFER[0] + 1;
        DC1_inPhase += DC1_inPhase / 50;

        TinyReadI2CPage(I2C_BUFFER, RFID_DEV_SEL_RF, InPh2_ADDR);
        T2_inPhase = (I2C_BUFFER[2] << 8) + I2C_BUFFER[1];
        DC2_inPhase = I2C_BUFFER[0];
        if (DC2_inPhase < 100) {
          InitTimer1(T2_inPhase, DC2_inPhase);
        } else {
          MASK0 = 0;
        }
        break;

      }
  }

}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// This function writes 4 bytes of data from the I2C channel
void TinyWriteI2CPage(char *DATA, char DEV_ADDR, int DATA_ADDR) {

  byte ADDR0;
  // First give the device address, the function adds RW bit.
  TinyWireM.beginTransmission(DEV_ADDR);          // Addresses and enables the device.

  // Sends the 16 bit address location to write to.
  ADDR0 = DATA_ADDR >> 8;
  TinyWireM.send(ADDR0);                          // Send MSB first
  ADDR0 = DATA_ADDR & 0xFF;
  TinyWireM.send(ADDR0);                          // Send LSB at the end.
  TinyWireM.send(*DATA); DATA++;
  TinyWireM.send(*DATA); DATA++;
  TinyWireM.send(*DATA); DATA++;
  TinyWireM.send(*DATA);
  TinyWireM.endTransmission();                        // End tramission but sends a restart
  // endTransmission(0/1) sends a restart/stop commands
  //End transmission and give some delay.
  delay(10);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// This function writes 1 byte of data from the I2C channel
void TinyWriteI2CByte(char DATA, char DEV_ADDR, int DATA_ADDR) {

  byte ADDR0;
  // First give the device address, the function adds RW bit.
  TinyWireM.beginTransmission(DEV_ADDR);          // Addresses and enables the device.

  // Sends the 16 bit address location to write to.
  ADDR0 = DATA_ADDR >> 8;
  TinyWireM.send(ADDR0);                          // Send MSB first
  ADDR0 = DATA_ADDR & 0xFF;
  TinyWireM.send(ADDR0);                          // Send LSB at the end.
  TinyWireM.send(DATA);
  TinyWireM.endTransmission();                        // End tramission but sends a restart
  // endTransmission(0/1) sends a restart/stop commands
  //End transmission and give some delay.
  delay(10);

}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// This function reads 4 bytes of data from the I2C channel
void TinyReadI2CPage(char *DATA, char DEV_ADDR, int DATA_ADDR) {

  byte ADDR0;
  // First give the device address, the function adds RW bit.
  // Give write command to load the address to read.
  TinyWireM.beginTransmission(DEV_ADDR);          // Addresses and enables the device.
  ADDR0 = DATA_ADDR >> 8;
  TinyWireM.send(ADDR0);                          // Send MSB first
  ADDR0 = DATA_ADDR & 0xFF;
  TinyWireM.send(ADDR0);                          // Send LSB at the end.
  TinyWireM.endTransmission();

  // Evoke the read command, which will read the previously sent address.
  DATA = I2C_BUFFER;
  TinyWireM.requestFrom(DEV_ADDR, 4);             // Requests 8 bytes from slave
  while (TinyWireM.available()) {
    *DATA = 0;                                     // Clears the reading buffer.
    *DATA = TinyWireM.receive();
    DATA++;
  }
  delay(10);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// This function writes 4 bytes of data from the I2C channel
void PresentPassword(char DEV_ADDR) {

  // First give the device address, the function adds RW bit.
  TinyWireM.beginTransmission(DEV_ADDR);          // Addresses and enables the device.

  // Sends the 16 bit address location to write to.
  TinyWireM.send(0x09);               // Send MSB first
  TinyWireM.send(0x00);               // Send LSB at the end.

  // Default password is 0x00 00 00 00
  TinyWireM.send(0x00);
  TinyWireM.send(0x00);
  TinyWireM.send(0x00);
  TinyWireM.send(0x00);

  // Confirm password
  TinyWireM.send(0x09);

  TinyWireM.send(0x00);
  TinyWireM.send(0x00);
  TinyWireM.send(0x00);
  TinyWireM.send(0x00);
  TinyWireM.endTransmission();                        // End tramission but sends a restart
  // endTransmission(0/1) sends a restart/stop commands
  //End transmission and give some delay.
  delay(100);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Set up TIMER0 to work inthe CTC mode at 1MHz, 8 prescaler, and
// provide 1 ms interruption.
void InitTimer0(void) {

  TCCR0A = 0x02;        // Clear timer register, set CTC on A
  TCCR0B = 0x02;        // Sets prescaler 1/8
  OCR0A = 125;          // With 1MHz and 1/8 prescaler, 125 gives 1 ms.

  COUNT0 = 0;         // Start software counter
  COUNT1 = 0;
  COUNT2 = 0;
  COUNT3 = 0;

  TCNT0 = 0x00;

}

void StopTimer0(void) {
  TIMSK0 &= !(1 << OCIE0A);// Disables interruption A.
}

void StartTimer0(void) {
  TCNT0 = 0x00;
  TIMSK0 |= 1 << OCIE0A;
  TIFR0 |= 0x02;        // Clears interruption flag
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Set up TIMER1 to work inthe CTC mode at 1MHz, and 1 prescaler.
// Two interruptions are programed, one for register A and B. B is
// first and dictates the duty cycle, A is second and dictates the period.
// Default values are 100 ms @ 50%
void InitTimer1(unsigned int T, unsigned int DC) {

  unsigned int temp = 0;
  temp = DC;

  TIMSK1 = 0x00;
  TCCR1A = 0x00;        // Clear timer register, set CTC on A
  TCCR1B = 0x09;        // Sets prescaller 1/1, and WGM12, or 1us counter.
  TCCR1C = 0x00;

  T += T * 0.033;
  OCR1AH = (T >> 8) & 0xFF;
  OCR1AL = T & 0xFF;

  // Changes DC[%] to 1us counts.
  T /= 100;  DC *= T;

  // Compensate for T = 500 us.
  DC = DC + 0.14 * temp - 34.92;


  OCR1BH = (DC >> 8) & 0xFF;
  OCR1BL = DC & 0xFF;

  TIMSK1  = (1 << OCIE1A) | (1 << OCIE1B);// Enables interruption A and B.
  TIFR0  |= 0x06;         // Clears interruption flag

  TCNT1H = 0x00;
  TCNT1L = 0x00;
  
}

void StopTimer1(void) {
  TIMSK1 = 0x00;
  TCCR1A = 0x00;
  TCCR1B = 0x00;
}

void StartTimer1(void) {
  TIMSK1  = (1 << OCIE1A) | (1 << OCIE1B);// Enables interruption A and B.
  TCNT1H = 0x00;
  TCNT1L = 0x00;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Routine that services TIMER0 compare with OCR0A register.
// It is programmed to work with 1MHz clock, 8 presecaller
// and 1 ms interruption.
ISR(TIM0_COMPA_vect) {
  COUNT0++;
  COUNT1++;
  COUNT2++;
  COUNT3++;
  BLINKCNT++;
  FLAG0 = 1;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Routine that services TIMER1 (8-bit mode) compare with OCR1AL register.
// It is programmed to work with 1MHz clock, 8 presecaller
// and 1 ms interruption.
ISR(TIM1_COMPA_vect) {
  PORT_Channels ^= (MASK1 & ONOFF);
}

ISR(TIM1_COMPB_vect) {
  PORT_Channels ^= (MASK1 & ONOFF);
}

ISR(PCINT0_vect) {
  cli();
  PORT_Channels &= ~0xF0;
  MASK = 1;
}
