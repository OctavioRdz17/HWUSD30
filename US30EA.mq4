//+------------------------------------------------------------------+
//|                                                       US30EA.mq4 |
//|                                Copyright 2021, Octavio Rodriguez |
//|                                                   toktrading.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Octavio Rodriguez"
#property link      "toktrading.net"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
 int StartRangeHour = 12;
 int EndRangeHour   = 15;
 
//+------------------------------------------------------------------+
//|  Memoria                                                         |
//+------------------------------------------------------------------+
 bool newRange= false;
 string activeRange;
 datetime lastRangeTime;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   ObjectsDeleteAll();
   
   //iniciamos dibujando el ultimo rango
   activeRange =drawRange(StartRangeHour,EndRangeHour);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+ 
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   //revisamos si hay un nuevo rango
   if(newRange==true){
      activeRange =drawRange(StartRangeHour,EndRangeHour);
      newRange = false;
   }
   if(check4NewRange(activeRange)){
      newRange = true;
   }
   
   
   
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Algoritmo para sacar el maximo de las horas de rango |
//| del dia de hoy                                                   |
//+------------------------------------------------------------------+

double rangeMax(int hourStart, int hourEnd){
   double max = 0;

   
   int modHourStar =iBarShift(Symbol(),Period(),dateConverter(hourStart));
   int modHourEnd  =iBarShift(Symbol(),Period(),dateConverter(hourEnd));
     
   int maxPoint =iHighest(Symbol(),Period(),MODE_HIGH,modHourStar - modHourEnd,modHourEnd);
   max = iHigh(Symbol(),Period(),maxPoint);
   
   return max;
}

//+------------------------------------------------------------------+
//| Algoritmo para sacar el minimo de las horas de rango |
//| del dia de hoy                                                   |
//+------------------------------------------------------------------+

double rangeMin(int hourStart, int hourEnd){
   double min = 0;

   
   int modHourStar =iBarShift(Symbol(),Period(),dateConverter(hourStart));
   int modHourEnd  =iBarShift(Symbol(),Period(),dateConverter(hourEnd));
     
   int minPoint =iLowest(Symbol(),Period(),MODE_LOW,modHourStar - modHourEnd,modHourEnd);
   min = iLow(Symbol(),Period(),minPoint);
   
   return min;
}

//+------------------------------------------------------------------+
//|  Convertir las horas a datetime                                  |
//+------------------------------------------------------------------+

datetime dateConverter(int hour){  
   int intRelevante,now;
   
   now = TimeHour(TimeCurrent());
   
   if(now >= EndRangeHour){
      intRelevante =  now - hour;     
   }else{
      intRelevante = 24 - hour + now;
   }
   //////////////
   return iTime(Symbol(),60,intRelevante);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string drawRange(int hourStart, int hourEnd){
   int timeStartValue,timeEndValue;
   double maxValue, minValue;
   
   maxValue   = rangeMax(hourStart,hourEnd);
   minValue   = rangeMin(hourStart,hourEnd);
   
   timeStartValue = iBarShift(Symbol(),Period(),dateConverter(hourStart));
   timeEndValue   = iBarShift(Symbol(),Period(),dateConverter(hourEnd));
   
   //variable para registrar que pasaron 24 hrs del ultimo rango
   lastRangeTime = dateConverter(hourEnd);
   
   //nombre del objeto random para no repetir
   string recName = newName("rango");
   //Comment("maxValue ="+maxValue+"\nminValue ="+minValue+"\ntimeStartValue ="+timeStartValue+"\ntimeEndValue ="+timeEndValue);
   ObjectCreate(NULL,recName,OBJ_RECTANGLE,0,iTime(Symbol(),Period(),timeStartValue),maxValue,iTime(Symbol(),Period(),timeEndValue),minValue);
   ObjectSetInteger(NULL,recName,OBJPROP_COLOR,clrLightSalmon);
   
   
   return recName;
}


//+------------------------------------------------------------------+
//|   Nombre random con prefijo                                      |
//+------------------------------------------------------------------+
string newName(string prefix)
  {
   string namex;
   int existe;

   do
     {
      namex = StringConcatenate(prefix,(string)MathRand());
      existe = ObjectFind(0,namex);
     }
   while(existe != -1);

   return namex;
  }
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool check4NewRange(string name){
   int lastTimeShift;
   
   lastTimeShift = iBarShift(Symbol(),Period(),lastRangeTime);
   Comment(lastTimeShift);
   
    //revisar las 24 hrs segun el shiflt
    if((60*24/Period())<lastTimeShift){
         
      return true;     
    }
   
   
   return false;
}