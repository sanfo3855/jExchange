include "marketInterface.iol"
include "stockInterface.iol"
include "console.iol"
include "time.iol"
include "math.iol"
include "semaphore_utils.iol"

outputPort OutputMarket {
	Location: "socket://localhost:8000"
	Protocol: sodep
	Interfaces: MarketInterface
}

inputPort InputStock {
	Location: "socket://localhost:8001"
	Protocol: sodep
	Interfaces: StockInterface
}

//input port per la gestione del timer
inputPort TimerPort {
  Location: "local"
  OneWay: 
   prodGrano( string ), 
   depGrano( string ), 
   prodOro( string ), 
   depPetrolio( string ), 
   prodPetrolio( string )
}
// mini struttura del timer
type TimerType: long {
  .operation: string
  .message: string
}
//outputport per la gestione del timer
outputPort Timer {
  OneWay: setNextTimeout( TimerType )
}

embedded {
  Java: "MyTimer" in Timer
}
//DEFINE generale per la stampa del grano
define stampaGrano
{
  println@Console( 
    global.StockGrano.name + 
    "\nQuantità disponibile: " + global.StockGrano.amount + "  " + variazioneGrano + 
    "\n------------------------------\n"
  )()
}
//DEFINE generale per la stampa del petrolio
define stampaPetrolio
{
  println@Console( 
    global.StockPetrolio.name + 
    "\nQuantità disponibile: " + global.StockPetrolio.amount + "  " + variazionePetrolio + 
    "\n------------------------------\n"
  )()
}
//DEFINE generale per la stampa dell'oro
define stampaOro
{
  println@Console( 
    global.StockOro.name + 
    "\nQuantità disponibile: " + global.StockOro.amount + "  " + variazioneOro + 
    "\n------------------------------\n"
  )()
}

execution{ concurrent }

init
{
  global.i=0;
  println@Console( "STOCK\n\n" )();
  global.control=false;
  //Creo la struttura principale dello stock oro
  global.StockOro.amount  = int("5");
  global.StockOro.name = "Oro";
  global.StockOro.totValue = double("25");
  registraOro@OutputMarket(global.StockOro)();//invio lo stock oro al market per la registrazione
  stampaOro;
   //Creo la struttura principale dello stock petrolio
  global.StockPetrolio.amount  = int("50");
  global.StockPetrolio.name = "Petrolio";
  global.StockPetrolio.totValue = double("75");
  registraPetrolio@OutputMarket(global.StockPetrolio)();//invio lo stock petrolio al market per la registrazione
  stampaPetrolio;
    //Creo la struttura principale dello stock grano
  global.StockGrano.amount  = int("100");
  global.StockGrano.name = "Grano";
  global.StockGrano.totValue = double("100");
  registraGrano@OutputMarket(global.StockGrano)();//invio lo stock grano al market per la registrazione
  stampaGrano;

//SEMAFORI PER LE VARIABILI CONDIVISE DI AMOUNT ORO ,AMOUNT GRANO, AMOUNT PETROLIO
  semAmountOro.name = "Aggiorno Amount Oro";
  semAmountOro.permits = 1;
  release@SemaphoreUtils( semAmountOro )( res );

  semAmountGrano.name = "Aggiorno Amount Grano";
  semAmountGrano.permits = 1;
  release@SemaphoreUtils( semAmountGrano )( res );

  semAmountPetrolio.name = "Aggiorno Amount Petrolio";
  semAmountPetrolio.permits = 1;
  release@SemaphoreUtils( semAmountPetrolio )( res );

//SEMAFORI PER LA GESTIONE DEI LETTORI E SCRITTORI
  semMutexGrano.name = "Mutex Lettura Amount Grano";
  semMutexGrano.permits = 1;
  release@SemaphoreUtils( semMutexGrano )( res );
  global.numLettoriGrano = 0;

  semMutexOro.name = "Mutex Lettura Amount Oro";
  semMutexOro.permits = 1;
  release@SemaphoreUtils( semMutexOro )( res );
  global.numLettoriOro = 0;

  semMutexPetrolio.name = "Mutex Lettura Amount Petrolio";
  semMutexPetrolio.permits = 1;
  release@SemaphoreUtils( semMutexPetrolio )( res );
  global.numLettoriPetrolio = 0;



  //Setto i Timer
  {
    prodGrano = 3000;
    with( prodGrano ){
      .operation = "prodGrano";
      .message = "----Produco Grano----"
    };

    depGrano = 5000;
    with( depGrano ){
      .operation = "depGrano";
      .message = "----Deperisco Grano----"
    };

    prodPetrolio = 10000;
    with( prodPetrolio ){
      .operation = "prodPetrolio";
      .message = "----Produco Petrolio----"
    };

    depPetrolio = 8000;
    with( depPetrolio ){
      .operation = "depPetrolio";
      .message = "----Deperisco Petrolio----"
    };

    prodOro = 10000;
    with( prodOro ){
      .operation = "prodOro";
      .message = "----Produco Oro----"
    }
  };

  //Metto in parallelo i setNextTimeout nel caso di timeout contemporanei
  {
    setNextTimeout@Timer( prodGrano ) |
    setNextTimeout@Timer( depGrano ) |
    setNextTimeout@Timer( prodPetrolio ) |
    setNextTimeout@Timer( depPetrolio ) |
    setNextTimeout@Timer( prodOro )
  }
}
//define per gestire i lettori sull'ottieni amount grano
//INIZIO GESTIONE LETTORI
define inizioLetturaAmountGrano
{
  acquire@SemaphoreUtils( semMutexGrano )( res );
    global.numLettoriGrano++;
    if(global.numLettoriGrano == 1){
      acquire@SemaphoreUtils( semAmountGrano )( res )
    };
  release@SemaphoreUtils( semMutexGrano )( res)
  
}
//define per gestire i lettori sull'ottieni amount grano
//FINE GESTIONE LETTORI
define fineLetturaAmountGrano
{
  acquire@SemaphoreUtils( semMutexGrano )( res);
    global.numLettoriGrano--;
    if(global.numLettoriGrano == 0){
      release@SemaphoreUtils( semAmountGrano )( res )
    };
  release@SemaphoreUtils( semMutexGrano )( res )
}
//define per gestire i lettori sull'ottieni amount oro
//INIZIO GESTIONE LETTORI
define inizioLetturaAmountOro
{
  acquire@SemaphoreUtils( semMutexOro )( res );
    global.numLettoriOro++;
    //println@Console( global.numLettoriOro )();
    if(global.numLettoriOro == 1){
      acquire@SemaphoreUtils( semAmountOro )( res )
    };
  release@SemaphoreUtils( semMutexOro )( res)

}
//define per gestire i lettori sull'ottieni amount oro
//FINE GESTIONE LETTORI
define fineLetturaAmountOro
{
  acquire@SemaphoreUtils( semMutexOro )( res);
    global.numLettoriOro--;
    if(global.numLettoriOro == 0){
      release@SemaphoreUtils( semAmountOro )( res )
    };
  release@SemaphoreUtils( semMutexOro )( res )
}
//define per gestire i lettori sull'ottieni amount petrolio
//INIZIO GESTIONE LETTORI
define inizioLetturaAmountPetrolio
{
  acquire@SemaphoreUtils( semMutexPetrolio )( res );
    global.numLettoriPetrolio++;
    if(global.numLettoriPetrolio == 1){
      acquire@SemaphoreUtils( semAmountPetrolio )( res )
    };
  release@SemaphoreUtils( semMutexPetrolio )( res)
  
}
//define per gestire i lettori sull'ottieni amount petrolio
//FINE GESTIONE LETTORI
define fineLetturaAmountPetrolio
{
  acquire@SemaphoreUtils( semMutexPetrolio )( res);
    global.numLettoriPetrolio--;
    if(global.numLettoriPetrolio == 0){
      release@SemaphoreUtils( semAmountPetrolio )( res )
    };
  release@SemaphoreUtils( semMutexPetrolio )( res )
}


main
{
  //PRODUZIONE RANDOM GRANO
  [prodGrano( prodMsgG )] {
    acquire@SemaphoreUtils( semAmountGrano )( res ); 
    min=3;
    max=6;
    random@Math( )( a );
    a = int(a*(max-min+1)+min);
    granoI=global.StockGrano.amount;//Grano prima dell'Incremento
    //controllo se la quantità di grano è ugauale a zero 
    if( granoI == 0 ){
      global.StockGrano.amount = global.StockGrano.amount + a;//incremento lo stock cn il valore generato dal rnd
      aggiornaPrezzoGranoProd@OutputMarket( double(0) )()//passiamo il tasso al market per far diminure il prezzo dopo la produzione di a stock di grano
    //controllo se la quantità di grano è maggiore di zero 
    } else if( granoI > 0 ){
      global.StockGrano.amount = global.StockGrano.amount + a;//incremento lo stock cn il valore generato dal rnd
      aggiornaPrezzoGranoProd@OutputMarket( double(a)/double(granoI) )()//passiamo il tasso al market per far diminure il prezzo dopo la produzione di a stock di grano
    //controllo se la quantità di grano è minore di zero (per evitare che la quantita di grano vada sotto lo zero) 
    } else if ( granoI < 0 ){
      global.StockGrano.amount = a;//non incremento ma uguaglio la quantità di stock grano al valore generato dal rnd
      aggiornaPrezzoGranoProd@OutputMarket( double(0) )()
    };
    variazioneGrano = "↑ "+a;
    //STAMPEk++
    println@Console( prodMsgG )();
    stampaGrano;
    release@SemaphoreUtils( semAmountGrano )( res );
    setNextTimeout@Timer( prodGrano )
  }
  //DEPERIMENTO RANDOM GRANO
  [depGrano( depMsgG )] {
    acquire@SemaphoreUtils( semAmountGrano )( res ); 
    //controllo che ci sia quantità disponibile per deperire
    if( global.StockGrano.amount > 0 ){
      min=1;
      max=5;
      random@Math( )( a );
      a = int(a*(max-min+1)+min);
      granoI=global.StockGrano.amount;//Grano prima dell'Incremento
      //controllo se la quantità di grano è maggiore di zero
      if( granoI > a ) {
        global.StockGrano.amount = global.StockGrano.amount - a;//decremento lo stock cn il valore generato dal rnd
        aggiornaPrezzoGranoDeper@OutputMarket( double(a)/double(granoI) )();//passiamo il tasso al market per far aumentare il prezzo dopo il deperimento di a stock di grano
        variazioneGrano = "↓ "+a
        //controllo se la quantità di grano è uguale al numero scelto randomicamente da decrementare
      } else if( granoI == a ) {
        global.StockGrano.amount = global.StockGrano.amount - a;//decremento lo stock cn il valore generato dal rnd
        aggiornaPrezzoGranoDeper@OutputMarket( double(0) )();
        variazioneGrano = "↓ "+a
      } else if(granoI < a ) {
        global.StockGrano.amount = 0;
        aggiornaPrezzoGranoDeper@OutputMarket( double(0) )();
        variazioneGrano = "↓ " + a
      }     
    //non riesco a deperire poichè non c'è la quntita di stock grano disponibile
    } else if( global.StockGrano.amount == 0) {
      variazioneGrano = "* Esaurito - Non Deperisco"
    };
    println@Console( depMsgG )();
    stampaGrano;
    release@SemaphoreUtils( semAmountGrano )( res );
    setNextTimeout@Timer( depGrano )
  }
  //PRODUZIONE RANDOM ORO
  [prodOro( prodMsgO )] {
    min=0;
    max=2;
    random@Math( )( a );
    a = int(a*(max-min+1)+min);
    acquire@SemaphoreUtils( semAmountOro )( res ); 
    oroI=global.StockOro.amount;
    if( oroI == 0 ) {
      global.StockOro.amount = global.StockOro.amount + a;
      aggiornaPrezzoOroProd@OutputMarket(double(0))()
    } else if ( oroI > a ) {
      global.StockOro.amount = global.StockOro.amount + a;  
      aggiornaPrezzoOroProd@OutputMarket(double(a)/double(oroI))()
    }else if ( oroI < 0 ) {
      global.StockOro.amount = a;
      aggiornaPrezzoOroProd@OutputMarket(double(0))()
    };
    variazioneOro = "↑ "+a;
    println@Console( prodMsgO )();
    stampaOro;
    release@SemaphoreUtils( semAmountOro )( res );
    setNextTimeout@Timer( prodOro )
  }
  //DEPERIMENTO RANDOM PETROLIO
  [depPetrolio( depMsgP )]{
    acquire@SemaphoreUtils( semAmountPetrolio )( res ); 
    if( global.StockPetrolio.amount > 0 ) {
      min=1;
      max=2;
      random@Math( )( a );
      a = int(a*(max-min+1)+min);
      petrolioI = global.StockPetrolio.amount;
      if(petrolioI > a ){
        global.StockPetrolio.amount = global.StockPetrolio.amount - a;
        aggiornaPrezzoPetrolioDeper@OutputMarket( double(a)/double(petrolioI) )();
        variazionePetrolio = "↓ "+a
      } else if( petrolioI == a ){
        global.StockPetrolio.amount = global.StockPetrolio.amount - a;
        aggiornaPrezzoPetrolioDeper@OutputMarket( double(0) )();
        variazionePetrolio = "↓ "+a
      } else if ( petrolioI < a ) {
        global.StockPetrolio.amount = 0;
        aggiornaPrezzoPetrolioDeper@OutputMarket( double(0) )();
        variazionePetrolio = "↓ "+a
      }
    } else if( global.StockPetrolio.amount == 0 ){
      variazionePetrolio = "* Esaurito - Non deperisco"
    };
    println@Console( depMsgP )();
    stampaPetrolio;
    release@SemaphoreUtils( semAmountPetrolio )( res );
    setNextTimeout@Timer( depPetrolio )
  }
  //PRODUZIONE RANDOM PETROLIO
  [prodPetrolio( prodMsgP )]{
    acquire@SemaphoreUtils( semAmountPetrolio )( res ); 
    min=1;
    max=3;
    random@Math( )( a );
    a = int(a*(max-min+1)+min);
    petrolioI = global.StockPetrolio.amount;
    if( petrolioI == 0 ) {
      global.StockPetrolio.amount = global.StockPetrolio.amount + a;
      aggiornaPrezzoPetrolioProd@OutputMarket( double(0) )()
    } else if ( petrolioI > 0 ) {
      global.StockPetrolio.amount = global.StockPetrolio.amount + a;
      aggiornaPrezzoPetrolioProd@OutputMarket( double(a)/double( petrolioI ) )()
    } else if ( petrolioI < 0 ) {
      global.StockPetrolio.amount = a;
      aggiornaPrezzoPetrolioProd@OutputMarket( double(0) )()
    };
    variazionePetrolio = "↑ "+a;
    println@Console( prodMsgP )();
    stampaPetrolio;
    release@SemaphoreUtils( semAmountPetrolio )( res );
    setNextTimeout@Timer( prodPetrolio )
  }

  //ottieniAmountGrano risponde al market mandando in risposta la quantità di grano aggiornata
  [ottieniAmountGrano( )( amountGrano ){
    inizioLetturaAmountGrano;
      amountGrano = global.StockGrano.amount;
    fineLetturaAmountGrano
  }]
  //ottieniAmountOro risponde al market mandando in risposta la quantità di oro aggiornata
  [ottieniAmountOro( )( amountOro ){
    inizioLetturaAmountOro;
      amountOro = global.StockOro.amount;
    fineLetturaAmountOro
  }] 
  //ottieniAmountPetrolio risponde al market mandando in risposta la quantità di petrolio aggiornata
  [ottieniAmountPetrolio( )( amountPetrolio ){
    inizioLetturaAmountPetrolio;
      amountPetrolio = global.StockPetrolio.amount;
    fineLetturaAmountPetrolio
  }]
  //input-choice per la richiesta della riduzione di quantità di grano da parte del market per l'azione d'acquisto
  [riduciStockGrano(nomePlayer)(){
    acquire@SemaphoreUtils( semAmountGrano )( res );
    amountRiduciGrano = global.StockGrano.amount;
    //riduco la quantità di stockGrano se è maggiore di 0
    if(amountRiduciGrano > 0){
      global.StockGrano.amount--;//riduco lo stock grano
      aggiornaPrezzoGranoBuy@OutputMarket( double(1) / double(amountRiduciGrano) )();//invio al marketo il tasso d'icremento dopo l'acquisto
      variazioneGrano = "← Acquisto Grano EFFETTUATO -- " + nomePlayer  + "\n"
      //non permetto l'acquisto
    } else {
      variazioneGrano = "* Acquisto Grano STOCK ESAURITO -- " + nomePlayer + "\n"
    };
    stampaGrano;
    release@SemaphoreUtils( semAmountGrano )( res )
  }]
  //input-choice per la richiesta della riduzione di quantità di oro da parte del market per l'azione d'acquisto
  [riduciStockOro(nomePlayer)(){
    acquire@SemaphoreUtils( semAmountOro )( res );
    amountRiduciOro = global.StockOro.amount;
    if(amountRiduciOro > 0){
      global.StockOro.amount--;
      aggiornaPrezzoOroBuy@OutputMarket( double(1) / double(amountRiduciOro) )();
      variazioneOro = "← Acquisto Oro EFFETTUATO -- " + nomePlayer  + "\n"
    } else {
      variazioneOro = "* Acquisto Oro STOCK ESAURITO -- " + nomePlayer + "\n"
    };
    stampaOro;
    release@SemaphoreUtils( semAmountOro )( res )
  }]
  //input-choice per la richiesta della riduzione di quantità di petrolio da parte del market per l'azione d'acquisto
  [riduciStockPetrolio(nomePlayer)(){
    acquire@SemaphoreUtils( semAmountPetrolio )( res );
    amountRiduciPetrolio = global.StockPetrolio.amount;
    if(amountRiduciPetrolio > 0){
      global.StockPetrolio.amount--;
      aggiornaPrezzoPetrolioBuy@OutputMarket( double(1) / double(amountRiduciPetrolio) )();
      variazionePetrolio = "← Acquisto Petrolio EFFETTUATO -- " + nomePlayer  + "\n"
    } else {
      variazionePetrolio = "* Acquisto Petrolio STOCK ESAURITO -- " + nomePlayer + "\n"
    };
    stampaPetrolio;
    release@SemaphoreUtils( semAmountPetrolio )( res )
  }]
  //input-choice per la richiesta di incremento di quantità di grano da parte del market per l'azione di vendita
  [aumentoStockGrano( nomePlayer )(){
    acquire@SemaphoreUtils( semAmountGrano )( res );
    amountAumentoGrano = global.StockGrano.amount;
    global.StockGrano.amount++;
    aggiornaPrezzoGranoSell@OutputMarket( double(1) / double(amountAumentoGrano) )();//invio al marketo il tasso di decremento dopo la vendita
    variazioneGrano = "→ Vendita Grano EFETTUATA -- " + nomePlayer + "\n";
    stampaGrano;
    release@SemaphoreUtils( semAmountGrano )( res )
  }]
  //input-choice per la richiesta di incremento di quantità di oro da parte del market per l'azione di vendita
  [aumentoStockOro( nomePlayer )(){
    acquire@SemaphoreUtils( semAmountOro )( res );
    amountAumentoOro = global.StockOro.amount;
    global.StockOro.amount++;
    aggiornaPrezzoOroSell@OutputMarket( double(1) / double(amountAumentoOro) )();
    variazioneOro = "→ Vendita Oro EFETTUATA -- " + nomePlayer + "\n";
    release@SemaphoreUtils( semAmountOro )( res );
    stampaOro
  }]
  //input-choice per la richiesta di incremento di quantità di petrolio da parte del market per l'azione di vendita
  [aumentoStockPetrolio( nomePlayer )(){
    acquire@SemaphoreUtils( semAmountPetrolio )( res );
    amountAumentoPetrolio = global.StockPetrolio.amount;
    global.StockPetrolio.amount++;
    aggiornaPrezzoPetrolioSell@OutputMarket( double(1) / double(amountAumentoPetrolio) )();
    variazionePetrolio = "→ Vendita Petrolio EFETTUATA -- " + nomePlayer + "\n";
    stampaPetrolio;
    release@SemaphoreUtils( semAmountPetrolio )( res )
  }]
}
  