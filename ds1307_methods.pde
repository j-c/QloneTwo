/*
Methods to simplify the usage of the DS1307 RTC module

* Requires Wire.begin() in the main code else Wire won't work.
* Modifies time_t time in the main code

*/

#define DS1307_ADDR 0x68
// DS1307 clock registers
#define R_SECS      0
#define R_MINS      1
#define R_HRS       2
#define R_WKDAY     3
#define R_DATE      4
#define R_MONTH     5
#define R_YEAR      6
#define R_SQW       7
void SetDs1307Time()
{
  Wire.beginTransmission(DS1307_ADDR);
  Wire.send(R_SECS); // move write register back to seconds
  Wire.send(DecToBcd(time.ss));
  Wire.send(DecToBcd(time.mm));
  Wire.send(DecToBcd(time.hh)); // If time is set correctly (ie: the bit 6 is 0 after the conversion, the time will be in the 24 hr format.
  /*
  Wire.send(1); // day of week
  Wire.send(1); // day of month
  Wire.send(1); // month
  Wire.send(10); // year
  Wire.send(0); // control
  */
  Wire.endTransmission();
}

void GetDs1307Time()
{
  Wire.beginTransmission(DS1307_ADDR);
  Wire.send(R_SECS); // move read register to seconds
  Wire.endTransmission();
  Wire.requestFrom(DS1307_ADDR, 3);
  time.ss = BcdToDec(Wire.receive() & 0x7f);
  time.mm = BcdToDec(Wire.receive());
  time.hh = BcdToDec(Wire.receive() & 0x3f);
}

// Convert binary coded decimal to normal decimal numbers
byte BcdToDec(byte val)
{
  return ( (val/16*10) + (val%16) );
}

// Convert normal decimal numbers to binary coded decimal
byte DecToBcd(byte val)
{
  return ( (val/10*16) + (val%10) );
}


