//+------------------------------------------------------------------+
//|                                                  MT5_INVIZZZ.mq4 |
//|                                          https://www.invizzz.com |
//+------------------------------------------------------------------+

#property strict
#include <Trade\Trade.mqh>

input int historySize = 1000;

class Instrument{
   public:
   string instrumentName;
   string tSize;
   int tFrame;
   string lastTime;
};

CTrade trade;

// Переменные, в которых будет записана разница между локальным и серверным временем: ----- //
MqlDateTime mqlDateTimeStructureDiff;
datetime difference;
int diff;
// ---------------------------------------------------------------------------------------- //

string BrockerName = AccountInfoString(ACCOUNT_COMPANY);
string terminalName = "#MT5#";
string brockerName = BrockerName;
string addDescript = terminalName + brockerName;

int buy_ordersArray[100];
int sell_ordersArray[100];
int buy_ordersArrayLength = 0;
int sell_ordersArrayLength = 0;

Instrument instrument;

void rewritingFileOrders(string text){
   int fout_Orders = FileOpen("Invizzz/Orders.txt", FILE_WRITE);
   if (fout_Orders != INVALID_HANDLE) {
      FileWrite(fout_Orders, text);
      FileClose(fout_Orders);
   }
}

int OnInit() {
    instrument.instrumentName = Symbol();
    instrument.tSize = DoubleToString(SymbolInfoDouble(instrument.instrumentName, SYMBOL_TRADE_TICK_SIZE), _Digits);
    instrument.tFrame = Period();
    
    instrument.tFrame = (instrument.tFrame == PERIOD_M1) ? 1 :
                         (instrument.tFrame == PERIOD_M2) ? 2 :
                         (instrument.tFrame == PERIOD_M3) ? 3 :
                         (instrument.tFrame == PERIOD_M4) ? 4 :
                        (instrument.tFrame == PERIOD_M5) ? 5 :
                        (instrument.tFrame == PERIOD_M6) ? 6 :
                        (instrument.tFrame == PERIOD_M10) ? 10 :
                        (instrument.tFrame == PERIOD_M12) ? 12 :
                        (instrument.tFrame == PERIOD_M15) ? 15 :
                        (instrument.tFrame == PERIOD_M20) ? 20 :
                        (instrument.tFrame == PERIOD_M30) ? 30 :
                        (instrument.tFrame == PERIOD_H1) ? 60 :
                        (instrument.tFrame == PERIOD_H2) ? 120 :
                        (instrument.tFrame == PERIOD_H3) ? 180 :
                        (instrument.tFrame == PERIOD_H4) ? 240 :
                        (instrument.tFrame == PERIOD_H6) ? 360 :
                        (instrument.tFrame == PERIOD_H8) ? 480 :
                        (instrument.tFrame == PERIOD_H12) ? 720 :
                        (instrument.tFrame == PERIOD_D1) ? 1440 :
                        (instrument.tFrame == PERIOD_W1) ? 10080 : 43200;
    
    // ------------ Определяем разницу серверного времени и локального: - //
    difference = fabs(TimeGMT() - TimeLocal());
    TimeToStruct(difference, mqlDateTimeStructureDiff);
    diff = mqlDateTimeStructureDiff.hour;
    diff = (TimeGMT() < TimeLocal()) ? diff : -diff;
    // ------------------------------------------------------------------ //
    
    while(true){
        int fout_List = FileOpen("Invizzz/List.txt", FILE_READ | FILE_WRITE | FILE_ANSI);
        if (fout_List != INVALID_HANDLE) {
            FileSeek(fout_List, 0, SEEK_END);
            string trow = "\n" + instrument.instrumentName + addDescript + "#" + instrument.tSize + "#" + IntegerToString(instrument.tFrame) + "\n";
            FileWriteString(fout_List, trow, StringLen(trow));
            FileClose(fout_List);
            break;
        }
        else{
            Sleep(100);
        }
    }
    
    // Создание файла ордерс:
    int fin_Orders = FileOpen("Invizzz/Orders.txt", FILE_READ | FILE_ANSI);
    if (fin_Orders != INVALID_HANDLE) {
        FileClose(fin_Orders); // Файл уже создан.
    }
    else {
        int fout_Orders = FileOpen("Invizzz/Orders.txt", FILE_WRITE | FILE_ANSI);
        if (fout_Orders != INVALID_HANDLE) {
            FileWrite(fout_Orders, "");
            FileClose(fout_Orders);
        }
    }

    // Загружаем историю по инструменту:
    string currentAsk = DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_ASK), _Digits);
    string currentBid = DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_BID), _Digits);

    int history = Bars(_Symbol,_Period);
    history = (history > historySize) ? historySize : history;

    string PushBack = "";
    for (int n = history - 1; n >= 0; --n) {

        // Определяем время бара:
        datetime tempTime = iTime(_Symbol,_Period, n);
        MqlDateTime mqlDateTimeStructure;
        TimeToStruct(tempTime, mqlDateTimeStructure);
        mqlDateTimeStructure.hour + diff;

        int HOURES = mqlDateTimeStructure.hour;
        int MINUTES = mqlDateTimeStructure.min;
        int DAY = mqlDateTimeStructure.day;
        int MONTH = mqlDateTimeStructure.mon;
        int YEAR = mqlDateTimeStructure.year;

        string pref = "0";
        string H = (HOURES < 10) ? pref + IntegerToString(HOURES) : IntegerToString(HOURES);
        string Min = (MINUTES < 10) ? pref + IntegerToString(MINUTES) : IntegerToString(MINUTES);
        string D = (DAY < 10) ? pref + IntegerToString(DAY) : IntegerToString(DAY);
        string Mon = (MONTH < 10) ? pref + IntegerToString(MONTH) : IntegerToString(MONTH);
        string Y = IntegerToString(YEAR);

        string barTime = H + ":" + Min + "&" + D + "/" + Mon + "/" + Y;

        int epcilon =  (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

        double tempOpen = iOpen(_Symbol, PERIOD_CURRENT, n);
        double tempHigh = iHigh(_Symbol, PERIOD_CURRENT, n);
        double tempLow = iLow(_Symbol, PERIOD_CURRENT, n);
        double tempClose = iClose(_Symbol, PERIOD_CURRENT, n);

        if (n > 0) {
            if ((tempOpen != 0.0) && (tempHigh != 0.0) && (tempLow != 0.0) && (tempClose != 0.0)) {
                if (n != 1) {
                    PushBack += DoubleToString(tempOpen, epcilon) + ";" +
                        DoubleToString(tempHigh, epcilon) + ";" +
                        DoubleToString(tempLow, epcilon) + ";" +
                        DoubleToString(tempClose, epcilon) + ";" +
                        barTime + "\n";
                }
                else {
                    PushBack +=  DoubleToString(tempOpen, epcilon) + ";" +
                                 DoubleToString(tempHigh, epcilon) + ";" +
                                 DoubleToString(tempLow, epcilon) + ";" +
                                 DoubleToString(tempClose, epcilon) + ";" +
                                 barTime + "\n";
                    instrument.lastTime = barTime;
                }
            }
        }
        else{ // == 0
            if ((tempOpen != 0.0) && (tempHigh != 0.0) && (tempLow != 0.0) && (tempClose != 0.0)) {

                  datetime tempTime1 = iTime(_Symbol,_Period, n+1);
                 MqlDateTime mqlDateTimeStructure1;
                 TimeToStruct(tempTime1, mqlDateTimeStructure1);
                 mqlDateTimeStructure1.hour + diff;
         
                 int HOURES1 = mqlDateTimeStructure1.hour;
                 int MINUTES1 = mqlDateTimeStructure1.min;
                 int DAY1 = mqlDateTimeStructure1.day;
                 int MONTH1 = mqlDateTimeStructure1.mon;
                 int YEAR1 = mqlDateTimeStructure1.year;
         
                 string H1 = (HOURES1 < 10) ? pref + IntegerToString(HOURES1) : IntegerToString(HOURES1);
                 string Min1 = (MINUTES1 < 10) ? pref + IntegerToString(MINUTES1) : IntegerToString(MINUTES1);
                 string D1 = (DAY1 < 10) ? pref + IntegerToString(DAY1) : IntegerToString(DAY1);
                 string Mon1 = (MONTH1 < 10) ? pref + IntegerToString(MONTH1) : IntegerToString(MONTH1);
                 string Y1 = IntegerToString(YEAR1);
         
                 string barTime1 = H1 + ":" + Min1 + "&" + D1 + "/" + Mon1 + "/" + Y1;
         
                 double tempOpen1 = iOpen(_Symbol, PERIOD_CURRENT, n+1);
                 double tempHigh1 = iHigh(_Symbol, PERIOD_CURRENT, n+1);
                 double tempLow1 = iLow(_Symbol, PERIOD_CURRENT, n+1);
                 double tempClose1 = iClose(_Symbol, PERIOD_CURRENT, n+1);
                    


                    string record = currentBid + ";" + currentAsk + ";" +
                          DoubleToString(tempOpen, epcilon) + ";" +
                          DoubleToString(tempHigh, epcilon) + ";" +
                          DoubleToString(tempLow, epcilon) + ";" +
                          DoubleToString(tempClose, epcilon) + ";" +
                          barTime + ";" + 
                          DoubleToString(tempOpen1, epcilon) + ";" +
                          DoubleToString(tempHigh1, epcilon) + ";" +
                          DoubleToString(tempLow1, epcilon) + ";" +
                          DoubleToString(tempClose1, epcilon) + ";" +
                          barTime1 + ";\n";

                int fout_current = FileOpen("Invizzz/current#" + instrument.instrumentName + addDescript + "#" + instrument.tSize + "#" + IntegerToString(instrument.tFrame) + ".txt", FILE_WRITE | FILE_ANSI);
                if (fout_current != INVALID_HANDLE) {
                    FileWriteString(fout_current, record, StringLen(record));
                    FileClose(fout_current);
                }
            }
        }
    }
    int fout_history = FileOpen("Invizzz/" + instrument.instrumentName + addDescript + "#" + instrument.tSize + "#" + IntegerToString(instrument.tFrame) + ".txt", FILE_WRITE | FILE_ANSI);
    if (fout_history != INVALID_HANDLE) {
        FileWriteString(fout_history, PushBack, StringLen(PushBack));
        FileClose(fout_history);
    }
    EventSetMillisecondTimer(50);
    return(INIT_SUCCEEDED);
}



void OnDeinit(const int reason) {
    // Удаление всех созданных ранее файлов:
    FileDelete("Invizzz/" + instrument.instrumentName + addDescript + "#" + instrument.tSize + "#" + IntegerToString(instrument.tFrame) + ".txt");
    FileDelete("Invizzz/current#" + instrument.instrumentName + addDescript + "#" + instrument.tSize + "#" + IntegerToString(instrument.tFrame) + ".txt");
    
    if(reason == REASON_CLOSE){ // Терминал был закрыт
         FileDelete("Invizzz/Orders.txt");
         FileDelete("Invizzz/List.txt");
    }
    else{ // reason == REASON_PROGRAM || reason == REASON_REMOVE || reason == REASON_CHARTCHANGE || reason == REASON_CHARTCLOSE
       int fin_File = FileOpen("Invizzz/List.txt", FILE_TXT | FILE_READ | FILE_ANSI);
       if(fin_File != INVALID_HANDLE){
            string tempRecord = "";
            int counter = 0;
            while(!(FileIsEnding(fin_File))){
               string tempText = FileReadString(fin_File);
               if(tempText != instrument.instrumentName + addDescript + "#" + instrument.tSize + "#" + IntegerToString(instrument.tFrame)){
                  if(tempRecord == ""){tempRecord += tempText + "\n";}
                  else{
                     tempRecord += "\n" + tempText + "\n";
                  }
                  
                  if(tempText != ""){
                     counter++;
                  }
               }
            }
            FileClose(fin_File);
            
            if(counter > 0){
               string newRecord = "";
               for(int i=0; i < StringLen(tempRecord)-1; ++i){
                     if(tempRecord[i] == '\n' && tempRecord[i+1] == '\n'){
                        newRecord += "\n";
                        ++i;
                     }
                     else{
                        newRecord += CharToString(char(tempRecord[i]));
                     }
               }
            
               int fout_List = FileOpen("Invizzz/List.txt", FILE_WRITE | FILE_ANSI);
               if(fout_List != INVALID_HANDLE){
                  FileWriteString(fout_List, newRecord, StringLen(newRecord));
                  FileClose(fout_List);
               }
            }
            else{ //== 0
               FileDelete("Invizzz/Orders.txt");
               FileDelete("Invizzz/List.txt");
            }
       }
    }
}

void OnTimer(){

   // Проверка файла Ордерс на наличие приказов:
    int fin_Orders = FileOpen("Invizzz/Orders.txt", FILE_TXT|FILE_READ|FILE_ANSI);
    if (fin_Orders != INVALID_HANDLE) {
        string __Order = "";
        while(!(FileIsEnding(fin_Orders))){
            string tempText = FileReadString(fin_Orders);
            __Order += tempText;
        }
        FileClose(fin_Orders);
        if(__Order != ""){
           string typeOrder = "";
           string IName = "";
           double lot = 0.0;
           string reWrite = "";
           
           int _counter_ = 0;
           string temp = "";
           for(int i=0; i < StringLen(__Order); ++i){
               if(StringSubstr(__Order, i, 1) != ";" && StringSubstr(__Order, i, 1) != "\r" && StringSubstr(__Order, i, 1) != "\n" && StringSubstr(__Order, i, 1) != "`"){
                  temp += StringSubstr(__Order, i, 1);
               }
               else if(StringSubstr(__Order, i, 1) == "`"){
                  for(int j = i+1; j < StringLen(__Order); ++j){
                     reWrite += StringSubstr(__Order, j, 1);
                  }
                  break;
               }
               else{
                  if(_counter_ == 0){
                     typeOrder = temp;
                     temp = "";
                     _counter_++;
                  }
                  else if(_counter_ == 1){
                     IName = temp;
                     temp = "";
                     _counter_++;
                  }
                  else if(_counter_ == 2){
                     lot = StringToDouble(temp);
                     temp = "";
                     _counter_++;
                  }
                  else{
                      break;
                  }
               }
            }
            
            string termN = "#";
            bool bbF = false;
            for(int k=0; k < StringLen(IName); ++k){
               if(StringSubstr(IName, k, 1) == "#"){
                  for(int kk=k+1; kk < StringLen(IName); ++kk){
                     if(StringSubstr(IName, kk, 1) != "#"){
                        termN += StringSubstr(IName, kk, 1);
                     }
                     else{
                        bbF = true;
                        break;
                     }
                  }
                  if(bbF) break;
               }
            } termN += "#";
            
            if(termN != terminalName){
               rewritingFileOrders(reWrite);
            }
            else{
               if(IName == instrument.instrumentName + addDescript + "#" + instrument.tSize + "#" + IntegerToString(instrument.tFrame)){
               
                        rewritingFileOrders(reWrite);
               
                        if(typeOrder == "BUY"){
                           trade.PositionOpen(Symbol(), ORDER_TYPE_BUY, lot, SYMBOL_ASK,0,0,NULL);
                           Sleep(200);
                        }
                        else if(typeOrder == "SELL"){
                           trade.PositionOpen(Symbol(), ORDER_TYPE_SELL, lot, SYMBOL_BID,0,0,NULL);
                           Sleep(200);
                        }
                        else if(typeOrder == "CLOSE_BUY" || typeOrder == "CLOSE_SELL"){
                           trade.PositionClose(Symbol(), 30);
                           Sleep(200);
                        }
                   }
               }
          }
    }
}

void OnTick() {
    string currentAsk = DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_ASK), _Digits);
    string currentBid = DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_BID), _Digits);

    int history = Bars(_Symbol,_Period);
    history = (history > historySize) ? historySize : history;
    string PushBack = "";

    int epcilon = _Digits;

    // Время текущего бара, то есть нулевого, несформированного:
    datetime tempTime0 = iTime(_Symbol,_Period, 0);
    MqlDateTime mqlDateTimeStructure0;
    TimeToStruct(tempTime0, mqlDateTimeStructure0);
    mqlDateTimeStructure0.hour + diff;

    int HOURES0 = mqlDateTimeStructure0.hour;
    int MINUTES0 = mqlDateTimeStructure0.min;
    int DAY0 = mqlDateTimeStructure0.day;
    int MONTH0 = mqlDateTimeStructure0.mon;
    int YEAR0 = mqlDateTimeStructure0.year;

    string pref = "0";
    string H0 = (HOURES0 < 10) ? pref + IntegerToString(HOURES0) : IntegerToString(HOURES0);
    string Min0 = (MINUTES0 < 10) ? pref + IntegerToString(MINUTES0) : IntegerToString(MINUTES0);
    string D0 = (DAY0 < 10) ? pref + IntegerToString(DAY0) : IntegerToString(DAY0);
    string Mon0 = (MONTH0 < 10) ? pref + IntegerToString(MONTH0) : IntegerToString(MONTH0);
    string Y0 = IntegerToString(YEAR0);

    string barTime0 = H0 + ":" + Min0 + "&" + D0 + "/" + Mon0 + "/" + Y0;

    double tempOpen0 = iOpen(_Symbol, PERIOD_CURRENT, 0);
    double tempHigh0 = iHigh(_Symbol, PERIOD_CURRENT, 0);
    double tempLow0 = iLow(_Symbol, PERIOD_CURRENT, 0);
    double tempClose0 = iClose(_Symbol, PERIOD_CURRENT, 0);

    // Время последнего полностью сформировавшегося бара на тек момент:
    datetime tempTime1 = iTime(_Symbol,_Period, 1);
    MqlDateTime mqlDateTimeStructure1;
    TimeToStruct(tempTime1, mqlDateTimeStructure1);
    mqlDateTimeStructure1.hour + diff;

    int HOURES1 = mqlDateTimeStructure1.hour;
    int MINUTES1 = mqlDateTimeStructure1.min;
    int DAY1 = mqlDateTimeStructure1.day;
    int MONTH1 = mqlDateTimeStructure1.mon;
    int YEAR1 = mqlDateTimeStructure1.year;

    string H1 = (HOURES1 < 10) ? pref + IntegerToString(HOURES1) : IntegerToString(HOURES1);
    string Min1 = (MINUTES1 < 10) ? pref + IntegerToString(MINUTES1) : IntegerToString(MINUTES1);
    string D1 = (DAY1 < 10) ? pref + IntegerToString(DAY1) : IntegerToString(DAY1);
    string Mon1 = (MONTH1 < 10) ? pref + IntegerToString(MONTH1) : IntegerToString(MONTH1);
    string Y1 = IntegerToString(YEAR1);

    string barTime1 = H1 + ":" + Min1 + "&" + D1 + "/" + Mon1 + "/" + Y1;

    double tempOpen1 = iOpen(_Symbol, PERIOD_CURRENT, 1);
    double tempHigh1 = iHigh(_Symbol, PERIOD_CURRENT, 1);
    double tempLow1 = iLow(_Symbol, PERIOD_CURRENT, 1);
    double tempClose1 = iClose(_Symbol, PERIOD_CURRENT, 1);

    string record = currentBid + ";" + currentAsk + ";" +
        DoubleToString(tempOpen0, epcilon) + ";" +
        DoubleToString(tempHigh0, epcilon) + ";" +
        DoubleToString(tempLow0, epcilon) + ";" +
        DoubleToString(tempClose0, epcilon) + ";" +
        barTime0 + ";" + 
        DoubleToString(tempOpen1, epcilon) + ";" +
        DoubleToString(tempHigh1, epcilon) + ";" +
        DoubleToString(tempLow1, epcilon) + ";" +
        DoubleToString(tempClose1, epcilon) + ";" +
        barTime1 + ";";

    string addRecord = DoubleToString(tempOpen1, epcilon) + ";" +
        DoubleToString(tempHigh1, epcilon) + ";" +
        DoubleToString(tempLow1, epcilon) + ";" +
        DoubleToString(tempClose1, epcilon) + ";" +
        barTime1 + "\n";

    if (barTime1 != instrument.lastTime) {
        instrument.lastTime = barTime1;
        // Добавляем данные в конец списка по бару с индексом 1
        int fout_addToHistory = FileOpen("Invizzz/" + instrument.instrumentName + addDescript + "#" + instrument.tSize + "#" + IntegerToString(instrument.tFrame) + ".txt", FILE_READ | FILE_WRITE | FILE_ANSI);
        if (fout_addToHistory != INVALID_HANDLE) {
            FileSeek(fout_addToHistory, 0, SEEK_END);
            FileWriteString(fout_addToHistory, addRecord, StringLen(addRecord));
            FileClose(fout_addToHistory);
        }
        
    }

    // И в любом случае обновляем данные по текущему бару:
    int fout_updateCurrent = FileOpen("Invizzz/current#" + instrument.instrumentName + addDescript + "#" + instrument.tSize + "#" + IntegerToString(instrument.tFrame) + ".txt", FILE_WRITE | FILE_ANSI);
    if (fout_updateCurrent != INVALID_HANDLE) {
        FileWriteString(fout_updateCurrent, record, StringLen(record));
        FileClose(fout_updateCurrent);
    }
}