/*
  QCloneTwo - Peggy clone of QClockTwo
 	Version 1.0 - 13/05/2010
 	Copyright (c) 2010 Joel Chia.  All right reserved.
 	
 	Based off:
 		Clock.pde - Peggy 2.0 Digital Clock
 		Version 1.0 - 06/13/2008
 		Copyright (c) 2008 Arthur J. Dahm III.  All right reserved.
 		Email: art@mindlessdiversions.com
 		Web: mindlessdiversions.com/peggy2
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
 	USAGE:
 	 - Press the "Any" button to cycle through time display, set hours, and minutes.
 	 - Press the "Off/Select" button to set the  hours & minutes.
         - Time will flash if the clock is powered up without a DS1307 connected. The flashing will stop once a time is set.
         - Clock can still be used without a DS1307, but it will not keep its current time when powered off.
         - The left button (b2) increases the background's brightness (and eventually cycles back to off).
 
 */

#include <Peggy2.h>
#include <Wire.h>


Peggy2 foregroundFrame;
Peggy2 backgroundFrame; // this is the all-on frame (used to partially light up the other letters

float rate = 60.0;

#define BUTTON_DEBOUNCE 20UL	// Time in mS to wait until next poll
#define BUTTON_ANY 1			// b1 "any" button
#define BUTTON_LEFT 2			// b2 "left" button
#define BUTTON_DOWN 4			// b3 "down" button
#define BUTTON_UP 8				// b4 "up" button
#define BUTTON_RIGHT 16		// b5 "right" button
#define BUTTON_OFF_SEL 32	// s2 "off/select" button
#define BUTTONS_CURRENT (PINC & B00011111) | ((PINB & 1)<<5)

enum mode_t {
  MODE_RUN, MODE_SET_HRS, MODE_SET_MINS};

struct time_t {
  uint8_t hh;
  uint8_t mm;
  uint8_t ss;
};

// regions
struct region_t {
  uint8_t x;
  uint8_t y;
  uint8_t width;
  uint8_t height;
};

// Display variables
region_t regions[27];
// The above array is populated from the qlockTwo array via InitRegions() as defined in clockRegions.pde
#define REGION_IT regions[0]
#define REGION_IS regions[1]
// Hours
#define H_1 regions[11]
#define H_2 regions[16]
#define H_3 regions[13]
#define H_4 regions[14]
#define H_5 regions[15]
#define H_6 regions[12]
#define H_7 regions[19]
#define H_8 regions[17]
#define H_9 regions[10]
#define H_10 regions[21]
#define H_11 regions[18]
#define H_12 regions[20]
// Minutes
#define M_FIVE regions[5]
#define M_TEN regions[7]
#define M_A regions[2]
#define M_QUARTER regions[3]
#define M_TWENTY regions[4]
#define M_HALF regions[6]
#define M_PAST regions[9]
#define M_TO regions[8]
#define M_OCLOCK regions[22]
#define M_1 regions[23]
#define M_2 regions[24]
#define M_3 regions[25]
#define M_4 regions[26]

#define MAX_BACKGROUND_BRIGHTNESS 4
byte backgroundBrightness = 0;

// Button variables
uint32_t buttonDebounce;
uint8_t buttonPollState;
uint8_t buttonPollStatePrev;
uint8_t buttonsPressed;
uint8_t buttonsReleased;

// Timer variables
int32_t currentTime;	//the current time, so the reading stays consistant through a whole update cycle
int32_t lastMillis;				//used to prevent a breakdown when SafeMillis() goes back to 0
int32_t lastTimeUpdate;		//used to see when a second is up
const int32_t oneSec=1000L;	//the length of 1 second in ms

// Clock variables
// sec = 0 - 59, min = 0 - 59, hr = 0 - 23
#define DEFAULT_TIME_HR 12
#define DEFAULT_TIME_MIN 0
#define DEFAULT_TIME_SEC 0
time_t time = {DEFAULT_TIME_HR, DEFAULT_TIME_MIN, DEFAULT_TIME_SEC};
mode_t mode = MODE_RUN;

bool isTimeSet = false;
bool haveDs1307 = false; // is the DS1307 RTC present?

#define ROW_ALL_ON 0x1FFFFFF

void setup()
{
  // Set up input buttons
  PORTB = B00000001;	// Pull up on ("OFF/SELECT" button)
  PORTC = B00011111;	// Pull-ups on C
  DDRB = B11111110;		// B0 is an input ("OFF/SELECT" button)
  DDRC = B11100000;		// All inputs

  buttonPollStatePrev = BUTTONS_CURRENT;
  buttonDebounce = SafeMillis();
  
  InitRegions();

  // Init time variables
  currentTime = lastMillis = lastTimeUpdate = SafeMillis();

  // get time from DS1307 and set isTimeSet flag to true.
  Wire.begin();
  GetDs1307Time();
  if (time.hh > 0) {
    isTimeSet = true;
    haveDs1307 = true;
  } else {
    time.hh = DEFAULT_TIME_HR;
    time.mm = DEFAULT_TIME_MIN;
    time.ss = DEFAULT_TIME_SEC;
  }
  
  // Set up display
  foregroundFrame.HardwareInit();
  // fill the background frame
  for (int y = 24; y >=0; --y) {
    backgroundFrame.WriteRow(y, ROW_ALL_ON);
  }
}

void loop()
{
  int32_t oldticks = 0;

  PollButtons();

  if (mode == MODE_RUN)
    Clock();
  else
    SetTime();

  // Write time to frame buffer
  DisplayTime();

}

void Clock()
{
  if (haveDs1307) {
    GetDs1307Time();
  } else {
    //for when millis resets, this method results in a loss of less than 1 min over a year
    lastMillis = currentTime;
    currentTime = SafeMillis();

    //reset lastTimeUpdate when the timer resets
    if (currentTime < lastTimeUpdate)
      lastTimeUpdate -= lastMillis;

    //update the time
    if (currentTime >= (lastTimeUpdate + oneSec))
    {
      //update the counter
      lastTimeUpdate += oneSec;
  
      //get the new time
      time.ss++;
      if (time.ss > 59)
      {
        time.ss = 0;
        time.mm++;
        if (time.mm > 59)
        {
          time.mm = 0;
          time.hh++;
          if (time.hh > 23)
          {
            time.hh = 0;
          }
        }
      }
    }
  }

  if (buttonsReleased & BUTTON_ANY)
  {
    mode = MODE_SET_HRS;
    time.ss = 0;
  }
  
  if (buttonsReleased & BUTTON_LEFT)
  {
    SetBackgroundBrightness();
  }
}


void SetTime()
{
  if (buttonsReleased & BUTTON_ANY)
  {
    if (mode == MODE_SET_HRS)
      mode = MODE_SET_MINS;
    else
    {
      mode = MODE_RUN;
      lastTimeUpdate = SafeMillis();
    }
  }

  if (buttonsReleased & BUTTON_OFF_SEL)
  {
    if (mode == MODE_SET_HRS)
    {
      time.hh++;
      if (time.hh > 23)
        time.hh = 0;
    }
    else if (mode == MODE_SET_MINS)
    {
      time.mm++;
      if (time.mm > 59)
        time.mm = 0;
    }
    
    if (haveDs1307) SetDs1307Time(); // send the time to the DS1307
  }

  // the time has been set (or at least modified)
  isTimeSet = true;
}


// Display functions
void DisplayTime()
{
  region_t r;
  uint8_t temp;

  foregroundFrame.Clear();

  // Turn on "IT IS" regions
  r = REGION_IT;
  FillRegion(r.x, r.y, r.width, r.height);
  r = REGION_IS;
  FillRegion(r.x, r.y, r.width, r.height);


  if (mode != MODE_RUN)
    currentTime=SafeMillis();

  // hours

    // If mode is MODE_SET_HRS, and it's currently .5 seconds, do not fill frame buffer with hour.
  // This is used to blink the hour while setting the time.
  if (!((mode == MODE_SET_HRS) && (currentTime%1000 >= 500)))
  {
    temp = time.hh;
    if (temp >= 12) temp -= 12;

    // select region
    switch (temp) {
    case 1:
      r = H_1;
      break;
    case 2:
      r = H_2;
      break;
    case 3:
      r = H_3;
      break;
    case 4:
      r = H_4;
      break;
    case 5:
      r = H_5;
      break;
    case 6:
      r = H_6;
      break;
    case 7:
      r = H_7;
      break;
    case 8:
      r = H_8;
      break;
    case 9:
      r = H_9;
      break;
    case 10:
      r = H_10;
      break;
    case 11:
      r = H_11;
      break;
    case 0: // 0 is 12 since hours ranges from 0 to 23
      r = H_12;
      break;
    }
    // fill framebuffer
    FillRegion(r.x, r.y, r.width, r.height);
  }

  // minutes

  // If mode is MODE_SET_MINS, and it's currently .5 seconds, do not fill frame buffer with minute.
  // This is used to blink the hour while setting the time.
  if (!((mode == MODE_SET_MINS) && (currentTime%1000 >= 500)))
  {
    temp = time.mm;

    // display minute words in multiples of 5
    if (temp < 5) {
      // :00 - :04
      r = M_OCLOCK;
    } 
    else if (temp < 10) {
      // :05 - :09
      r = M_FIVE;
    } 
    else if (temp < 15) {
      // :10 - :14
      r = M_TEN;
    } 
    else if (temp < 20) {
      // :15 - :19
      r = M_A;
      FillRegion(r.x, r.y, r.width, r.height);
      r = M_QUARTER;
    } 
    else if (temp < 25) {
      // :20 - :24
      r = M_TWENTY;
    } 
    else if (temp < 30) {
      // :25 - :30
      r = M_TWENTY;
      FillRegion(r.x, r.y, r.width, r.height);
      r = M_FIVE;
    } 
    else if (temp < 35) {
      // :30 - 34
      r = M_HALF;
    } 
    else if (temp < 40) {
      // :35 - 40
      r = M_TWENTY;
      FillRegion(r.x, r.y, r.width, r.height);
      r = M_FIVE;
    } 
    else if (temp < 45) {
      // :40 - :44
      r = M_TWENTY;
    } 
    else if (temp < 50) {
      // :45 - 49
      r = M_A;
      FillRegion(r.x, r.y, r.width, r.height);
      r = M_QUARTER;
    } 
    else if (temp < 55) {
      // :50 - :54
      r = M_TEN;
    } 
    else {
      // :55 - :59
      r = M_FIVE;
    }
    // Fill frame buffer
    FillRegion(r.x, r.y, r.width, r.height);

    // add PAST or TO (if required)
    if (temp >= 5) {
      if (temp < 35) {
        r = M_PAST;
      } 
      else {
        r = M_TO;
      }
      FillRegion(r.x, r.y, r.width, r.height);
    }

    // display minute counter (1 - 4 minutes past displayed time in words)
    temp = temp % 5;
    switch (temp) {
    case 1:
      r = M_1;
      FillRegion(r.x, r.y, r.width, r.height);
      break;
    case 2:
      r = M_2;
      FillRegion(r.x, r.y, r.width, r.height);
      break;
    case 3:
      r = M_3;
      FillRegion(r.x, r.y, r.width, r.height);
      break;
    case 4:
      r = M_4;
      FillRegion(r.x, r.y, r.width, r.height);
      break;
    }

  }

  // blink time the time has not been set yet.
  if (!isTimeSet && (mode == MODE_RUN) && (currentTime%1000 >= 500)) {
    foregroundFrame.Clear();
  }

  // draw frame
  foregroundFrame.RefreshAll(10);
  if (backgroundBrightness > 0) backgroundFrame.RefreshAll(backgroundBrightness);
}

void FillRegion(uint8_t x, uint8_t y, uint8_t width, uint8_t height)
{
  // fill downwards
  uint8_t x2 = x + width - 1;
  for (int i = height; --i >= 0;) {
    //foregroundFrame.Line(x, y + i, x2, y + i);
    foregroundFrame.Line(x, y + i, x2, y + i);
  }
  // fill lines across or downwards depending on which requires less iterations
  /*
  if (height <= width) {
    // fill downwards
    uint8_t x2 = x + width - 1;
    for (int i = height; --i >= 0;) {
      foregroundFrame.Line(x, y + i, x2, y + i);
    }
  } 
  else {
    // fill across
    uint8_t y2 = y + height - 1;
    for (int i = width; --i >= 0;) {
      foregroundFrame.Line(x + i, y, x + i, y2);
    }
  }
  */
}

// sets the background brightness
void SetBackgroundBrightness()
{
  if (++backgroundBrightness > MAX_BACKGROUND_BRIGHTNESS) backgroundBrightness = 0;
}

// Process button input
void PollButtons()
{
  uint32_t debouncetime;
  debouncetime = SafeMillis();

  if (debouncetime > (buttonDebounce + BUTTON_DEBOUNCE))
  {
    buttonDebounce = debouncetime;

    buttonPollState = BUTTONS_CURRENT;
    buttonPollStatePrev ^= buttonPollState;		// buttonPollStatePrev is nonzero if there has been a change.

    buttonsReleased = buttonPollStatePrev & buttonPollState;
    buttonsPressed = buttonPollStatePrev & ~buttonPollState;

    buttonPollStatePrev = buttonPollState;
  }
  else
  {
    buttonsReleased = 0;
    buttonsPressed = 0;
  }
}

uint32_t SafeMillis()
{
  uint32_t result;

  cli();
  result = millis();
  sei();

  return result;
}


