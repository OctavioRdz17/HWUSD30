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
 input int StartRangeHour = 12;
 input int EndRangeHour   = 15;
 input int StopTradingHour = 21;//Hora de fin del trading
 input int pointsSL = 5000; //Sl en entradas(Puntos)
 input int pointsAddOrder = 50;
 input double TPratio = 2;
 input double BEratio = 1;
 
 enum TipoDeRiesgo
  {
   PORCENTAJE,
   DOLARES
  };
 input TipoDeRiesgo RiesgoTipo= 0;//Tipo de Riesgo
 input double CantidadRiesgo = .5; //Cantidad de riesgo por operación
//+------------------------------------------------------------------+
//|  Memoria                                                         |
//+------------------------------------------------------------------+
 bool newRange= false;
 string activeRange;
 datetime lastRangeTime;
 double deltaRangeValue;
 double maxMemory = 0, minMemory = 0;


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

   //Comment("maxMemory: "+ (string)maxMemory +"\nminMEmory: "+(string)minMemory);
   
   //gestion de empate
   
   //Cerras las operaciones despues de la hora de trading
   deletePendingOrders(StopTradingHour);
   orderMannageBE( BEratio,pointsSL);
   
   //revisamos si hay un nuevo rango
   if(newRange==true){
      activeRange =drawRange(StartRangeHour,EndRangeHour);
      newRange = false;
   }
   
   //activamos nuevo rango cuando cumple 24hrs del anterior
   if(check4NewRange(activeRange)){
      newRange = true;
   }
     
   if(timeConditional(EndRangeHour,StopTradingHour)
      /*&& TotalOrderCount()<2*/ ) //condicional en horas de trading 
   //condicional para ver operaciones abiertas
   {
      placePendingStops(maxMemory,minMemory,pointsSL,pointsAddOrder);
      
   
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
   
   maxMemory = maxValue   = rangeMax(hourStart,hourEnd);
   //Print("Se cambio la memoria maxima"+(string)maxMemory);
   minMemory = minValue   = rangeMin(hourStart,hourEnd);
   //Print("Se cambio la memoria minima"+ (string)minMemory);
   
   timeStartValue = iBarShift(Symbol(),Period(),dateConverter(hourStart));
   timeEndValue   = iBarShift(Symbol(),Period(),dateConverter(hourEnd));
   
   //variable para registrar que pasaron 24 hrs del ultimo rango
   lastRangeTime = dateConverter(hourEnd);
   
   //nombre del objeto random para no repetir
   string recName = newName("rango");
   //Comment("maxValue ="+maxValue+"\nminValue ="+minValue+"\ntimeStartValue ="+timeStartValue+"\ntimeEndValue ="+timeEndValue);
   ObjectCreate(NULL,recName,OBJ_RECTANGLE,0,iTime(Symbol(),Period(),timeStartValue),maxValue,iTime(Symbol(),Period(),timeEndValue),minValue);
   ObjectSetInteger(NULL,recName,OBJPROP_COLOR,clrLightSalmon);
   
   //algoritmo para cuando el SL es menor a pntSL
   deltaRangeValue = (maxValue - minValue)/ Point();
   
   
   
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
   //Comment(lastTimeShift);
   
    //revisar las 24 hrs segun el shiflt
    if((60*22/Period())<lastTimeShift){
         
      return true;     
    }
   
   
   return false;
}

//+------------------------------------------------------------------+
//|   Condocional para saber cuando se puede abrir las entradas      |
//+------------------------------------------------------------------+
bool timeConditional(int timeStart, int timeEnd){
   
   if(TimeHour(TimeCurrent())>= timeStart && TimeHour(TimeCurrent()) < timeEnd ){
      //Print("Tiempo current"+TimeHour(TimeCurrent())+"\ntime start"+timeStart+"\nTimeEnd"+timeEnd+" true");
      return true;
      
   }
   
   return false;

}


//+------------------------------------------------------------------+
//|   Algoritmo de entradas stop                                     |
//+------------------------------------------------------------------+
void placePendingStops(double max, double min,int pntSL, int pipsDif){
   

   //calculo de lotaje segun el SL
   double riskLots = lotsCalculation(pntSL);
   
   double buyStopPrice =NormalizeDouble(max + (pipsDif * Point()),(int)MarketInfo(Symbol(),MODE_DIGITS));
   double buyStopSL = NormalizeDouble(buyStopPrice - pntSL *Point(),(int)MarketInfo(Symbol(),MODE_DIGITS));
   double buyStopTP = NormalizeDouble(buyStopPrice + (TPratio*pntSL*Point()),(int)MarketInfo(Symbol(),MODE_DIGITS));
   
   RefreshRates();
   
   //compra
   
   if(TotalOrderCountDir(1)<1 && Ask <  buyStopPrice){
      int ticket = OrderSend(Symbol(),OP_BUYSTOP,riskLots,buyStopPrice,200,buyStopSL,buyStopTP,NULL,314,0);
      if(ticket<0) 
        { 
         Print("OrderSend BUY failed with error #",GetLastError()); 
        } 
      else 
         Print("OrderSend placed successfully"); 
    }  
   
   double sellStopPrice =NormalizeDouble(min - (pipsDif * Point()),(int)MarketInfo(Symbol(),MODE_DIGITS));
   double sellStopSL = NormalizeDouble(sellStopPrice + pntSL *Point(),(int)MarketInfo(Symbol(),MODE_DIGITS));
   double sellStopTP = NormalizeDouble(sellStopPrice - (TPratio*pntSL*Point()),(int)MarketInfo(Symbol(),MODE_DIGITS));  
    
   
   //compra
   if(TotalOrderCountDir(-1)<1 && Ask > sellStopPrice){
   int ticket2 = OrderSend(Symbol(),OP_SELLSTOP,riskLots,sellStopPrice,200,sellStopSL,sellStopTP,NULL,314,0);
   if(ticket2<0) 
     { 
      Print("OrderSend SELL failed with error #",GetLastError()); 
     } 
   else 
      Print("OrderSend placed successfully"); 
   }
}


//+------------------------------------------------------------------+
//|  Crear lotaje para entrada                                       |
//+------------------------------------------------------------------+
double lotsCalculation(int pksSL){
   double dinero = AccountBalance()  * CantidadRiesgo/100;
   if(RiesgoTipo==1)
      dinero = CantidadRiesgo;
   double tickVal  = MarketInfo(NULL,MODE_TICKVALUE);
   if(tickVal == 0) tickVal = 1;
   double LotSize = dinero/(pksSL*tickVal);

   if(LotSize<.01)
      LotSize = .01;
   if(RiesgoTipo == 2)
      LotSize = CantidadRiesgo;

   LotSize = MathCeil(LotSize *100);
   LotSize = LotSize /100;
   
   if(MarketInfo(Symbol(),MODE_MINLOT) == 1.0)LotSize = NormalizeDouble(LotSize,0);
   if(MarketInfo(Symbol(),MODE_MINLOT) == .10)LotSize = NormalizeDouble(LotSize,1);
   if(MarketInfo(Symbol(),MODE_MINLOT) == 0.01)LotSize = NormalizeDouble(LotSize,2);
   
   return LotSize;

}


//+------------------------------------------------------------------+
//|  Cuenta cuantas ordenes existen pendientes                       |
//+------------------------------------------------------------------+
int TotalOrderCount(){
   int counte=0;

   for(int pos = OrdersTotal()-1; pos >= 0 ; pos--)
     {
      if(OrderSelect(pos, SELECT_BY_POS,MODE_TRADES)                  // Only my orders w/
         &&  StringSubstr((string)OrderMagicNumber(),0,3)  == "314"   // primeros tres numeros del magic
         &&  OrderSymbol()       == Symbol())                         // and my pair.
        {
         counte++;
        }
     }
   return(counte);
}


//+------------------------------------------------------------------+
//|  Cuenta cuantas ordenes existen pendientes                       |
//+------------------------------------------------------------------+
int TotalOrderCountDir(int dir){
   int counte=0;

   for(int pos = OrdersTotal()-1; pos >= 0 ; pos--)
     {
      if(OrderSelect(pos, SELECT_BY_POS,MODE_TRADES)                  // Only my orders w/
         &&  StringSubstr((string)OrderMagicNumber(),0,3)  == "314"   // primeros tres numeros del magic
         &&  OrderSymbol()       == Symbol()                          // and my pair.
         && dir == 1)                                                 //busca si hay una compra 
        {
         if(OrderType() == OP_BUYSTOP || OrderType() == OP_BUY)
         counte++;
        }
     }
     
    // para ventas
    for(int pos = OrdersTotal()-1; pos >= 0 ; pos--)
     {
      if(OrderSelect(pos, SELECT_BY_POS,MODE_TRADES)                  // Only my orders w/
         &&  StringSubstr((string)OrderMagicNumber(),0,3)  == "314"   // primeros tres numeros del magic
         &&  OrderSymbol()       == Symbol()                          // and my pair.
         && dir == -1)                                                 //busca si hay una compra 
        {
         if(OrderType() == OP_SELLSTOP || OrderType() == OP_SELL)
         counte++;
        }
     } 
     
   
   return(counte);
}

//+------------------------------------------------------------------+
//|   Borrar las entradas despues del horario                        |
//+------------------------------------------------------------------+
void deletePendingOrders(int closeHour){

   if(TimeHour(TimeCurrent())>=closeHour ){
      //Comment("Hora de Cerrar");
      for(int pos = OrdersTotal()-1; pos >= 0 ; pos--)
        {
         if(OrderSelect(pos, SELECT_BY_POS,MODE_TRADES)                       // Only my orders w/
            &&  StringSubstr((string)OrderMagicNumber(),0,3)  == "314"        // primeros tres numeros del magic
            &&  OrderSymbol()       == Symbol() 
            &&  (OrderType() == OP_BUYSTOP ||   OrderType() == OP_SELLSTOP)    // and my pair.
           )
                                                                            //busca si hay una compra 
           {
            if(OrderDelete(OrderTicket()))
               {
                  Print("Orden "+(string)OrderTicket()+" cancelada fuera de horario");
               }
            
           }
        }
      
   }
}
//+------------------------------------------------------------------+
//|       Mover las entradas a BE                                    |
//+------------------------------------------------------------------+
void orderMannageBE(double BE,int SLentrada){
   double SLtradesDistance;
   double BePriceBuy =0,BePriceSell=0;
   RefreshRates();
   //encontramos si las entradas son de SL completo o si se creo un SL mas pequeño
    if(deltaRangeValue < SLentrada){
         SLtradesDistance = deltaRangeValue;
    }else{
         SLtradesDistance = SLentrada;
    }
    
   //barrido de las ordenes
   for(int pos = OrdersTotal()-1; pos >= 0 ; pos--)
        {
         //hacemos el sort de las entradas que buscamos especificas
         if(OrderSelect(pos, SELECT_BY_POS,MODE_TRADES)                       // Only my orders w/
            &&  StringSubstr((string)OrderMagicNumber(),0,3)  == "314"        // primeros tres numeros del magic
            &&  OrderSymbol()       == Symbol()                               // este par
            &&  (OrderType() == OP_BUY || OrderType() == OP_SELL)             //busca si hay una compra 
           )                                                              
           {
               if(OrderType () == OP_BUY){
                  BePriceBuy = OrderOpenPrice()+ (SLtradesDistance* Point() * BE);   //sacamos el punto de empate segun el ratio     
                  //Comment("Precio de BE"+BePriceBuy);
                  if(   Ask >= BePriceBuy && 
                        OrderStopLoss() < OrderOpenPrice()
                        ){
                     //Print("Entro en rango de empate la orden=" + (string)OrderTicket()+"/n Ask = "+Ask);
                     bool mod = OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,clrNONE);
                     }
               }
               if(OrderType() == OP_SELL){
                  BePriceSell = OrderOpenPrice()- (SLtradesDistance* Point() * BE);   //sacamos el punto de empate segun el ratio     
                  if(   Ask <= BePriceSell && 
                        OrderStopLoss() > OrderOpenPrice()
                        ){
                    // Print("Entro en rango de empate la orden=" + (string)OrderTicket());
                     bool mod = OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,clrNONE);
                     }
               }
               
               
            
           }
        }
   
}

