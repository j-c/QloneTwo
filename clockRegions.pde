// x, y, width, height
region_t qlockTwo[27] = {
  {    1, 1, 4, 2    }  , // IT
  {    7, 1, 4, 2    }  , // IS
  {    1, 3, 2, 2    }  , // A
  {    5, 3, 14, 2    }  , // QUARTER
  {    1, 5, 12, 2    }  , // TWENTY
  {    13, 5, 8, 2    }  , // FIVE (minutes)
  {    1, 7, 8, 2    }  , // HALF
  {    11, 7, 6, 2    }  , // TEN (minutes)
  
  {    19, 7, 4, 2    }  , // TO
  {    1, 9, 8, 2    }  , // PAST
  
  {    15, 9, 8 ,2    }  , // NINE
  {    1, 11, 6, 2    }  , // ONE
  {    7, 11, 6, 2    }  , // SIX
  {    13, 11, 10, 2    }  , // THREE
  {    1, 13, 8, 2    }  , // FOUR
  {    9, 13, 8, 2    }  , // FIVE
  {    17, 13, 6, 2    }  , // TWO
  {    1, 15, 10, 2    }  , // EIGHT
  {    11, 15, 12, 2    }  , // ELEVEN
  {    1, 17, 10, 2    }  , // SEVEN
  {    11, 17, 12, 2    }  , // TWELVE
  {    1, 19, 6, 2    }  , // TEN
  
  {    11, 19, 12, 2    }  , // O'CLOCK
  
  {    22, 22, 1, 1    }  , // 1 minute
  {    21, 22, 2, 1    }  , // 2 minutes
  {    20, 22, 3, 1    }  , // 3 minutes
  {    19, 22, 4, 1    } // 4 minutes
};
  
void InitRegions()
{
 byte qlockTwoLength = sizeof(qlockTwo);
 for (int i = 0; i < qlockTwoLength; i++) {
   regions[i] = qlockTwo[i];
 }
}

