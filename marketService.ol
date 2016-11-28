include "marketInterface.iol"
include "stockInterface.iol"
include "console.iol"
include "time.iol"
include "semaphore_utils.iol"
include "math.iol"

inputPort InputMarket {
	Location: "socket://localhost:8000"
	Protocol: sodep
	Interfaces: MarketInterface
}

outputPort OutputStock {
	Location: "socket://localhost:8001"
	Protocol: sodep
	Interfaces: StockInterface
}

execution{ concurrent }

init
{
  println@Console( "MARKET\n\n" )();
  global.oroRegistrato = false;
  global.granoRegistrato = false;
  global.petrolioRegistrato = false;
  global.i = 0;

  //SEMAFORO PER LE VARIABILI CONDIVISE SULLA REGISTRAZIONE DEL PLAYER
  semRegistraPlayer.name = "Registrazione Player";
  semRegistraPlayer.permits = 1;
  release@SemaphoreUtils( semRegistraPlayer )( res );

  //SEMAFORI PER LE VARIABILI CONDIVISE DI PREZZO TOTALE
  //DI --ORO-- --GRANO-- --PETROLIO--
  semPrezzoTotOro.name = "Registrazione Player";
  semPrezzoTotOro.permits = 1;
  release@SemaphoreUtils( semPrezzoTotOro )( res );

  semPrezzoTotGrano.name = "Registrazione Player";
  semPrezzoTotGrano.permits = 1;
  release@SemaphoreUtils( semPrezzoTotGrano )( res );

  semPrezzoTotPetrolio.name = "Registrazione Player";
  semPrezzoTotPetrolio.permits = 1;
  release@SemaphoreUtils( semPrezzoTotPetrolio )( res );

  semMutexGrano.name = "Mutex Lettura Info Grano";
  semMutexGrano.permits = 1;
  release@SemaphoreUtils( semMutexGrano )( res );
  global.numLettoriGrano = 0;

  semMutexOro.name = "Mutex Lettura Info Oro";
  semMutexOro.permits = 1;
  release@SemaphoreUtils( semMutexOro )( res );
  global.numLettoriOro = 0;

  semMutexPetrolio.name = "Mutex Lettura Info Petrolio";
  semMutexPetrolio.permits = 1;
  release@SemaphoreUtils( semMutexPetrolio )( res );
  global.numLettoriPetrolio = 0

}

//define per gestire i lettori sull'ottieni info grano
//INIZIO GESTIONE LETTORI
define inizioInfoGrano
{
  acquire@SemaphoreUtils( semMutexGrano )( res );
    global.numLettoriGrano++;
    if(global.numLettoriGrano == 1){
      acquire@SemaphoreUtils( semPrezzoTotGrano )( res )//prendo i lock sugli scrittori del prezzoTotGrano
    };
  release@SemaphoreUtils( semMutexGrano )( res)
  
}
//define per gestire i lettori sull'ottieni info grano
//FINE GESTIONE LETTORI
define fineInfoGrano
{
  acquire@SemaphoreUtils( semMutexGrano )( res);
    global.numLettoriGrano--;
    if(global.numLettoriGrano == 0){
      release@SemaphoreUtils( semPrezzoTotGrano )( res )//rilascio il lock sugli scrittori del prezzoTotGrano
    };
  release@SemaphoreUtils( semMutexGrano )( res )
}
//define per gestire i lettori sull'ottieni info oro
//INIZIO GESTIONE LETTORI
define inizioInfoOro
{
  acquire@SemaphoreUtils( semMutexOro )( res );
    global.numLettoriOro++;
    if(global.numLettoriOro == 1){
      acquire@SemaphoreUtils( semPrezzoTotOro )( res )//prendo il lock sugli scrittori del prezzoTotOro
    };
  release@SemaphoreUtils( semMutexOro )( res)
}
//define per gestire i lettori sull'ottieni info oro
//FINE GESTIONE LETTORI
define fineInfoOro
{
  acquire@SemaphoreUtils( semMutexOro )( res);
    global.numLettoriOro--;
    if(global.numLettoriOro == 0){
      release@SemaphoreUtils( semPrezzoTotOro )( res )//rilascio il lock sugli scrittori del prezzoTotOro
    };
  release@SemaphoreUtils( semMutexOro )( res )
}
//define per gestire i lettori sull'ottieni info petrolio
//INIZIO GESTIONE LETTORI
define inizioInfoPetrolio
{
  acquire@SemaphoreUtils( semMutexPetrolio )( res );
    global.numLettoriPetrolio++;
    if(global.numLettoriPetrolio == 1){
      acquire@SemaphoreUtils( semPrezzoTotPetrolio )( res )//prendo il lock sugli scrittoi del prezzoTotPetrolio
    };
  release@SemaphoreUtils( semMutexPetrolio )( res)
}
//define per gestire i lettori sull'ottieni info petrolio
//FINE GESTIONE LETTORI
define fineInfoPetrolio
{
  acquire@SemaphoreUtils( semMutexPetrolio )( res);
    global.numLettoriPetrolio--;
    if(global.numLettoriPetrolio == 0){
      release@SemaphoreUtils( semPrezzoTotPetrolio )( res )//rilascio il lock sugli scrittori del prezzoTotPetrolio
    };
  release@SemaphoreUtils( semMutexPetrolio )( res )
}

main
{

  //CreaAccount assegna un account al player e lo registra nel market 
  [creaAccount( nomePlayer )( PlayerTemp ){
    acquire@SemaphoreUtils( semRegistraPlayer )( res );//prendo il lock sul registraPlayer
      //NOME
    	global.PlayerStructure.Item[global.i].name = nomePlayer;
      PlayerTemp.name = nomePlayer;
      //SOLDI DISPONIBILI
    	global.PlayerStructure.Item[global.i].cash = double(100);
      PlayerTemp.cash = double(100);
      //STOCK DISPONIBILI
    	global.PlayerStructure.Item[global.i].stockPetrolio = 0;
      global.PlayerStructure.Item[global.i].stockGrano = 0;
      global.PlayerStructure.Item[global.i].stockOro = 0;
      PlayerTemp.stockPetrolio = 0;
      PlayerTemp.stockGrano = 0;
      PlayerTemp.stockOro = 0;
      //INDICE PLAYER
      global.PlayerStructure.Item[global.i].index = global.i;
      PlayerTemp.index = global.i;
      println@Console( nomePlayer + " salvato nel Market\n" +
        global.PlayerStructure.Item[global.i].name + "\nSoldi Disponibili: " + 
        global.PlayerStructure.Item[global.i].cash + "\nStock Acquistati: \n" + 
        global.PlayerStructure.Item[global.i].stockOro + " (Oro)\n" + 
        global.PlayerStructure.Item[global.i].stockPetrolio + " (Petrolio)\n" +
        global.PlayerStructure.Item[global.i].stockGrano + " (Grano)\n" +
        global.PlayerStructure.Item[global.i].index +
        "------------------------------\n" )();
      global.i++;
    release@SemaphoreUtils( semRegistraPlayer )( res );//rilascio il lock sul registraPlayer
    sleep@Time( 500 )()
  }]
  //Controllo per gestire il lancio di player prima degli stock
  [controlloStock()(res){
    if(global.oroRegistrato&&global.granoRegistrato&&global.petrolioRegistrato){
      res = true
    } else {
      res=false
    }
  }]
  // orrieniInfo riceve i prezzi aggiornati e le quantità aggiornate dallo stock 
  // per poi inviarle al player
  [ottieniInfo( nomePlayer )( Info ){
    inizioInfoGrano;
      Info.prezzoTotaleGrano = global.prezzoTotaleGrano; 
      ottieniAmountGrano@OutputStock()( amountGrano );//ricevo la quntità di stock aggiornati dallo stock
      Info.amountGrano = amountGrano;
    fineInfoGrano;
    inizioInfoOro;
      Info.prezzoTotaleOro = global.prezzoTotaleOro;
      ottieniAmountOro@OutputStock()( amountOro );//ricevo la quntità di stock aggiornati dallo stock
      Info.amountOro = amountOro;
    fineInfoOro;
    inizioInfoPetrolio;
      Info.prezzoTotalePetrolio = global.prezzoTotalePetrolio;
      ottieniAmountPetrolio@OutputStock()( amountPetrolio );//ricevo la quntità di stock aggiornati dallo stock
      Info.amountPetrolio = amountPetrolio;
    fineInfoPetrolio
  }]

  //REGISTRAZIONE STOCK
  //  --ORO--
  [registraOro( StockOro )(){
    global.oroRegistrato=true;

    acquire@SemaphoreUtils( semPrezzoTotOro )( res );
      global.prezzoTotaleOro=StockOro.totValue;
      stampaRegistraOro = global.prezzoTotaleOro;
    release@SemaphoreUtils( semPrezzoTotOro )( res );
    //STAMPA PREZZO TOTALE ORO
    println@Console( 
      "Oro" +
      "\nPrezzo Totale: " + stampaRegistraOro +
      "\n-------------------------------")()
  }]

  //  --GRANO--
  [registraGrano( StockGrano )(){
    global.granoRegistrato=true;

    acquire@SemaphoreUtils( semPrezzoTotGrano )( res );
      global.prezzoTotaleGrano=StockGrano.totValue;
      stampaRegistraGrano = global.prezzoTotaleGrano;
    release@SemaphoreUtils( semPrezzoTotGrano )( res );   
    //STAMPA PREZZO TOTALE GRANO
    println@Console( 
      "Grano" +
      "\nPrezzo Totale: " + stampaRegistraGrano +
      "\n-------------------------------")()
  }]

  //  --PETROLIO--
  [registraPetrolio( StockPetrolio )(){
    global.petrolioRegistrato=true;

    acquire@SemaphoreUtils( semPrezzoTotPetrolio )( res );
      global.prezzoTotalePetrolio=StockPetrolio.totValue;
      stampaRegistraPetrolio = global.prezzoTotalePetrolio;
    release@SemaphoreUtils( semPrezzoTotPetrolio )( res );
    //STAMPA PREZZO TOTALE PETROLIO
    println@Console( 
      "Petrolio" +
      "\nPrezzo Totale: " + stampaRegistraPetrolio +
      "\n-------------------------------")()
  }]


  // aggiornaPrezzoOroProd riduco il prezzo totale in base alla produzione d'oro
  // controllo che il prezzoTotale del oro in base alla produzione non scendi al di sotto di 10
  [aggiornaPrezzoOroProd(percOroProd)(){
    acquire@SemaphoreUtils( semPrezzoTotOro )( res );
      prezzoControllo10Oro = global.prezzoTotaleOro - ( global.prezzoTotaleOro*percOroProd );
      if( prezzoControllo10Oro > 10 ) {
        global.prezzoTotaleOro = prezzoControllo10Oro;
        stampaAggiornaOroProd = global.prezzoTotaleOro
      } else if ( prezzoControllo10Oro <= 10 ) {
        global.prezzoTotaleOro = double(10);
        stampaAggiornaOroProd = global.prezzoTotaleOro
      };
    release@SemaphoreUtils( semPrezzoTotOro )( res );
    //STAMPA PREZZO --ORO-- AGGIORNATO
    println@Console( 
      "Oro   \nTasso ↓ " + percOroProd +
      "\nPrezzo Totale: " + stampaAggiornaOroProd +
      "\n-------------------------------\n")()
  }]

  // aggiornaPrezzoGranoProd riduco il prezzo totale in base alla produzione di grano
  // controllo che il prezzoTotale del grano non scendi al di sotto di 10
  [aggiornaPrezzoGranoProd(percGranoProd)(){
    acquire@SemaphoreUtils( semPrezzoTotGrano )( res );
    prezzoControllo10Grano = global.prezzoTotaleGrano - ( global.prezzoTotaleGrano*percGranoProd );
      if( prezzoControllo10Grano > 10 ) {
        global.prezzoTotaleGrano = prezzoControllo10Grano;
        stampaAggiornaGranoProd = global.prezzoTotaleGrano
      } else if ( prezzoControllo10Grano <= 10 ) {
        global.prezzoTotaleGrano = double(10);
        stampaAggiornaGranoProd = global.prezzoTotaleGrano
      };
    release@SemaphoreUtils( semPrezzoTotGrano )( res );
    println@Console( 
      "Grano   \nTasso ↓ " + percGranoProd +
      "\nPrezzo Totale: " + stampaAggiornaGranoProd +
      "\n-------------------------------\n")()
  }]
  // aggiornaPrezzoGranoDeper incremento il prezzo totale in base al deperimento di grano
  [aggiornaPrezzoGranoDeper(percGranoDeper)(){
    acquire@SemaphoreUtils( semPrezzoTotGrano )( res );
      global.prezzoTotaleGrano=global.prezzoTotaleGrano + (global.prezzoTotaleGrano*percGranoDeper);
      stampaAggiornaGranoDeper = global.prezzoTotaleGrano;
    release@SemaphoreUtils( semPrezzoTotGrano )( res );  
    println@Console( 
      "Grano   \nTasso ↑ " + percGranoDeper +
      "\nPrezzo Totale: " + stampaAggiornaGranoDeper  +
      "\n-------------------------------\n")()
  }]

  // aggiornaPrezzoPetrolioProd riduco il prezzo totale in base alla produzione di Petrolio
  // controllo che il prezzoTotale del petrolio non scendi al di sotto di 10
  [aggiornaPrezzoPetrolioProd( percPetrolioProd )(){
    acquire@SemaphoreUtils( semPrezzoTotPetrolio )( res );
    prezzoControllo10Petrolio = global.prezzoTotalePetrolio - ( global.prezzoTotalePetrolio * percPetrolioProd );
    if( prezzoControllo10Petrolio > 10 ) {
      global.prezzoTotalePetrolio = prezzoControllo10Petrolio;
      stampaAggiornaPetrolioProd = global.prezzoTotalePetrolio
    } else if ( prezzoControllo10Petrolio <= 10 ) {
      global.prezzoTotalePetrolio = double(10);
      stampaAggiornaPetrolioProd = global.prezzoTotalePetrolio
    };
    release@SemaphoreUtils( semPrezzoTotPetrolio )( res );

    println@Console( 
      "Petrolio   \nTasso ↓ " + percPetrolioProd +
      "\nPrezzo Totale: " + stampaAggiornaPetrolioProd +
      "\n-------------------------------\n")()
  }]

  // aggiornaPrezzoGranoDeper incremento il prezzo totale in base al deperimento di petrolio
  [aggiornaPrezzoPetrolioDeper(percPetrolioDeper)(){
    acquire@SemaphoreUtils( semPrezzoTotPetrolio )( res );
      global.prezzoTotalePetrolio=global.prezzoTotalePetrolio + (global.prezzoTotalePetrolio*percPetrolioDeper);
      stampaAggiornaPetrolioDeper = global.prezzoTotalePetrolio;
    release@SemaphoreUtils( semPrezzoTotPetrolio )( res );

    println@Console( 
      "Petrolio   \nTasso ↑ " + percPetrolioDeper +
      "\nPrezzo Totale: " + stampaAggiornaPetrolioDeper +
      "\n-------------------------------\n")()
  }]

  //acquistaGrano gestisce l'acquisto del grano 
  [acquistaGrano( index )( InfoAcquistoGrano ){
    acquire@SemaphoreUtils( semPrezzoTotGrano )( res );
    ottieniAmountGrano@OutputStock()(amountGrano);//ricevo la quantità disponibile di grano dallo stock
    nomePlayer = global.PlayerStructure.Item[index].name;
    //Controllo che la quantità di grano non vada mai sotto a zero
    if(amountGrano > 0 ){
      println@Console( amountGrano )();
      prezzoUnitarioGrano = global.prezzoTotaleGrano / double(amountGrano);
      //Controllo che l'acquisto venga fatto solo se il player ha la disponibilità economica
      if(global.PlayerStructure.Item[index].cash >= prezzoUnitarioGrano ){
        riduciStockGrano@OutputStock(nomePlayer)();//invio allo stock che deve ridurre la quantità di grano per via dell'acquisto
        println@Console( "← Aquisto Grano EFFETTUATO da " + nomePlayer + " -- Prezzo Unitario: "+ prezzoUnitarioGrano + "\n" )();
        InfoAcquistoGrano.cash = global.PlayerStructure.Item[index].cash - prezzoUnitarioGrano;
        InfoAcquistoGrano.incremento = 1;
        InfoAcquistoGrano.prezzoUnitario = prezzoUnitarioGrano;
        global.PlayerStructure.Item[index].cash = global.PlayerStructure.Item[index].cash - prezzoUnitarioGrano
        // Caso in cui il player non riesce ad acquistare il grano per mancanza di denaro
      } else if(global.PlayerStructure.Item[index].cash < prezzoUnitarioGrano ) {
        InfoAcquistoGrano.cash = global.PlayerStructure.Item[index].cash;
        InfoAcquistoGrano.incremento = 0;
        InfoAcquistoGrano.prezzoUnitario = double(0);
        println@Console( "Acquisto NEGATO -- soldi INSUFFICENTI per " + nomePlayer + "\n" )()
      }
      // controllo se la quantità di grano scende sotto lo zero
    } else {
      InfoAcquistoGrano.cash = global.PlayerStructure.Item[index].cash;
      InfoAcquistoGrano.incremento = 0;
      InfoAcquistoGrano.prezzoUnitario = double(0);
      println@Console( "Stock Grano ESAURITO " )()
    };
    release@SemaphoreUtils( semPrezzoTotGrano )( res )
  }]

  //acquistaOro gestisce l'acquisto dell'oro
  [acquistaOro( index )( InfoAcquistoOro ){
    acquire@SemaphoreUtils( semPrezzoTotOro )( res );
    ottieniAmountOro@OutputStock()( amountOro );//ottengo dallo stock la quantità disponibile di oro per calcolare il prezzo unitario
    nomePlayer = global.PlayerStructure.Item[index].name;    
    //Controllo che la quantità di grano non vada mai sotto a zero
    if(amountOro > 0 ){
      println@Console( amountOro )();
      prezzoUnitarioOro = global.prezzoTotaleOro / double(amountOro);
      //Controllo che l'acquisto venga fatto solo se il player ha la disponibilità economica      
      if(global.PlayerStructure.Item[index].cash >= prezzoUnitarioOro ){
        riduciStockOro@OutputStock( nomePlayer )();//invio allo stock che deve ridurre la quantità d'oro per via dell'acquisto
        println@Console( "← Aquisto Oro EFFETTUATO da " + nomePlayer + " -- Prezzo Unitario: "+ prezzoUnitarioOro + "\n" )();
        InfoAcquistoOro.cash = global.PlayerStructure.Item[index].cash - prezzoUnitarioOro;
        InfoAcquistoOro.incremento = 1;
        InfoAcquistoOro.prezzoUnitario = prezzoUnitarioOro;
        global.PlayerStructure.Item[index].cash = global.PlayerStructure.Item[index].cash - prezzoUnitarioOro
        // Caso in cui il player non riesce ad acquistare il grano per mancanza di denaro
      } else if(global.PlayerStructure.Item[index].cash < prezzoUnitarioOro ) {
        InfoAcquistoOro.cash = global.PlayerStructure.Item[index].cash;
        InfoAcquistoOro.incremento = 0;
        InfoAcquistoOro.prezzoUnitario = double(0);
        println@Console( "Acquisto NEGATO -- soldi INSUFFICENTI per " + nomePlayer + "\n" )()
      }
    // controllo se la quantità di oro scende sotto lo zero
    } else {
      InfoAcquistoOro.cash = global.PlayerStructure.Item[index].cash;
      InfoAcquistoOro.incremento = 0;
      InfoAcquistoOro.prezzoUnitario = double(0);
      println@Console( "Stock Oro ESAURITO " )()
    };
    release@SemaphoreUtils( semPrezzoTotOro )( res )
  }]
  //acquistaPetrolio gestisce l'acquisto del petrolio
  [acquistaPetrolio( index )( InfoAcquistoPetrolio ){
    acquire@SemaphoreUtils( semPrezzoTotPetrolio )( res );
    ottieniAmountPetrolio@OutputStock()( amountPetrolio );//ottengo dallo stock la quantità disponibile di petrolio per calcolare il prezzo unitario
    nomePlayer = global.PlayerStructure.Item[index].name;
    //controllo che la quantità di perolio non vada sotto lo zero
    if(amountPetrolio > 0 ){
      println@Console( amountPetrolio )();
      prezzoUnitarioPetrolio = global.prezzoTotalePetrolio / double(amountPetrolio);
      //Controllo che l'acquisto venga fatto solo se il player ha la disponibilità economica      
      if(global.PlayerStructure.Item[index].cash >= prezzoUnitarioPetrolio ){
        riduciStockPetrolio@OutputStock( nomePlayer )();//invio allo stock che deve ridurre la quantità di petrolio per via dell'acquisto
        println@Console( "← Aquisto Petrolio EFFETTUATO da " + nomePlayer + " -- Prezzo Unitario: "+ prezzoUnitarioPetrolio + "\n" )();
        InfoAcquistoPetrolio.cash = global.PlayerStructure.Item[index].cash - prezzoUnitarioPetrolio;
        InfoAcquistoPetrolio.incremento = 1;
        InfoAcquistoPetrolio.prezzoUnitario = prezzoUnitarioPetrolio;
        global.PlayerStructure.Item[index].cash = global.PlayerStructure.Item[index].cash - prezzoUnitarioPetrolio
        // Caso in cui il player non riesce ad acquistare il grano per mancanza di denaro
      } else if(global.PlayerStructure.Item[index].cash < prezzoUnitarioPetrolio ) {
        InfoAcquistoPetrolio.cash = global.PlayerStructure.Item[index].cash;
        InfoAcquistoPetrolio.incremento = 0;
        InfoAcquistoPetrolio.prezzoUnitario = double(0);
        println@Console( "Acquisto NEGATO -- soldi INSUFFICENTI per " + nomePlayer + "\n" )()
      } 
    // controllo se la quantità di petrolio scende sotto lo zero
    } else {
      InfoAcquistoPetrolio.cash = global.PlayerStructure.Item[index].cash;
      InfoAcquistoPetrolio.incremento = 0;
      InfoAcquistoPetrolio.prezzoUnitario = double(0);
      println@Console( "Stock Petrolio ESAURITO " )()
    };
    release@SemaphoreUtils( semPrezzoTotPetrolio )( res )
  }]
  //VendoGrano gestisce la vendita di grano
  [vendiGrano( index )( InfoVenditaGrano ){
    acquire@SemaphoreUtils( semPrezzoTotGrano )( res );
    nomePlayer = global.PlayerStructure.Item[index].name;
    aumentoStockGrano@OutputStock( nomePlayer )();//invio allo stock che deve aumentare la quantità di grano per via della vendita
    ottieniAmountGrano@OutputStock()( amountGrano );//ottengo dallo stock la quantità disponibile di grano per calcolare il prezzo unitario
    println@Console( amountGrano )();
    if(amountGrano == 0){
      prezzoUnitarioGrano = global.prezzoTotaleGrano / double(1)
    } else {
      prezzoUnitarioGrano = global.prezzoTotaleGrano / double(amountGrano)
    };
    println@Console( "→ Vendita Grano EFFETTUATA da " + nomePlayer + " -- Prezzo Unitario: " + prezzoUnitarioGrano + "\n" )();
    InfoVenditaGrano.cash = global.PlayerStructure.Item[index].cash + prezzoUnitarioGrano;
    InfoVenditaGrano.decremento = 1;
    InfoVenditaGrano.prezzoUnitario = prezzoUnitarioGrano;
    global.PlayerStructure.Item[index].cash = global.PlayerStructure.Item[index].cash + prezzoUnitarioGrano;
    release@SemaphoreUtils( semPrezzoTotGrano )( res )
  }]

  //vendiOro gestisce la vendita di oro
  [vendiOro( index )( InfoVenditaOro ){
    acquire@SemaphoreUtils( semPrezzoTotOro )( res );
    nomePlayer = global.PlayerStructure.Item[index].name;
    aumentoStockOro@OutputStock( nomePlayer )();//invio allo stock che deve aumentare la quantità di oro per via della vendita
    ottieniAmountOro@OutputStock()( amountOro );//ottengo dallo stock la quantità disponibile di oro per calcolare il prezzo unitario
    println@Console( amountOro )();
    if(amountOro == 0){
      prezzoUnitarioOro = global.prezzoTotaleOro / double(1)
    } else {
      prezzoUnitarioOro = global.prezzoTotaleOro / double(amountOro)
    };
    println@Console( "→ Vendita Oro EFFETTUATA da " + nomePlayer + " -- Prezzo Unitario: " + prezzoUnitarioOro + "\n" )();
    InfoVenditaOro.cash = global.PlayerStructure.Item[index].cash + prezzoUnitarioOro;
    InfoVenditaOro.decremento = 1;
    InfoVenditaOro.prezzoUnitario = prezzoUnitarioOro;
    global.PlayerStructure.Item[index].cash = global.PlayerStructure.Item[index].cash + prezzoUnitarioOro;
    release@SemaphoreUtils( semPrezzoTotOro )( res )
  }]

  //vendiPetrolio gestisce la vendita di petrolio
  [vendiPetrolio( index )( InfoVenditaPetrolio ){
    acquire@SemaphoreUtils( semPrezzoTotPetrolio )( res );
    nomePlayer = global.PlayerStructure.Item[index].name;
    aumentoStockPetrolio@OutputStock( nomePlayer )();//invio allo stock che deve aumentare la quantità di oro per via della vendita
    ottieniAmountPetrolio@OutputStock()( amountPetrolio );//ottengo dallo stock la quantità disponibile di oro per calcolare il prezzo unitario
    println@Console( amountPetrolio )();
    if(amountPetrolio == 0){
      prezzoUnitarioPetrolio = global.prezzoTotalePetrolio / double(1)
    } else {
      prezzoUnitarioPetrolio = global.prezzoTotalePetrolio / double(amountPetrolio)
    };
    println@Console( "→ Vendita Petrolio EFFETTUATA da " + nomePlayer + " -- Prezzo Unitario: " + prezzoUnitarioPetrolio + "\n" )();
    InfoVenditaPetrolio.cash = global.PlayerStructure.Item[index].cash + prezzoUnitarioPetrolio;
    InfoVenditaPetrolio.decremento = 1;
    InfoVenditaPetrolio.prezzoUnitario = prezzoUnitarioPetrolio;
    global.PlayerStructure.Item[index].cash = global.PlayerStructure.Item[index].cash + prezzoUnitarioPetrolio;
    release@SemaphoreUtils( semPrezzoTotPetrolio )( res )
  }]

  //aggiornaPrezzoGranoBuy aggiorna il prezzo dopo aver decrementato la quntità di grano dopo l'acquisto
  [aggiornaPrezzoGranoBuy(percGranoBuy)(){
    getCurrentTimeMillis@Time()( timeGranoBuy );//ottiene il time corrente della cpu in millisecondi
    acquire@SemaphoreUtils( semPrezzoTotGrano )( res );
    valPreAbsGrano = int(global.timeGranoBuyTemp-timeGranoBuy);//salvo la differenza tra due operazioni successive di tipo aggiornaPrezzoGranoBuy
    abs@Math( valPreAbsGrano )( valPostAbsGrano );//dato che la differenza puo essere negativa applico il valore assoluto
    global.timeGranoBuyTemp = valPostAbsGrano; 
    //controllo per la spaculazione
    if(timeGranoBuyTemp <= 1000){
      global.prezzoTotaleGrano = global.prezzoTotaleGrano + (global.prezzoTotaleGrano*percGranoBuy);
      global.prezzoTotaleGrano = global.prezzoTotaleGrano + (global.prezzoTotaleGrano*0.0001)
    } 
    else if(timeGranoBuyTemp> 1000 && timeGranoBuyTemp <= 2000) {
      global.prezzoTotaleGrano = global.prezzoTotaleGrano + (global.prezzoTotaleGrano*percGranoBuy);
      global.prezzoTotaleGrano = global.prezzoTotaleGrano + (global.prezzoTotaleGrano*0.001)
    }
    else if(timeGranoBuyTemp > 2000){
      global.prezzoTotaleGrano = global.prezzoTotaleGrano + (global.prezzoTotaleGrano*percGranoBuy);
      global.prezzoTotaleGrano = global.prezzoTotaleGrano + (global.prezzoTotaleGrano*0.01)
    };
    release@SemaphoreUtils( semPrezzoTotGrano )( res )
  }]

  //aggiornaPrezzoOroBuy aggiorna il prezzo dopo aver decrementato la quantità di oro dopo l'acquisto
  [aggiornaPrezzoOroBuy(percOroBuy)(){
    getCurrentTimeMillis@Time()( timeOroBuy );//ottiene il time corrente della cpu in millisecondi
    acquire@SemaphoreUtils( semPrezzoTotOro )( res );
    valPreAbsOro = int(global.timeOroBuyTemp-timeOroBuy);//salvo la differenza tra due operazioni succesive di tipo aggiornaPrezzoOroBuy
    abs@Math( valPreAbsOro )( valPostAbsOro );//dato che la differenza puo essere negativa applico il valore assoluto
    global.timeOroBuyTemp = valPostAbsOro; 
    //controllo per la speculazione
    if(timeOroBuyTemp <= 1000){
      global.prezzoTotaleOro = global.prezzoTotaleOro + (global.prezzoTotaleOro*percOroBuy);
      global.prezzoTotaleOro = global.prezzoTotaleOro + (global.prezzoTotaleOro*0.0001)
    } 
    else if(timeOroBuyTemp> 1000 && timeOroBuyTemp <= 2000) {
      global.prezzoTotaleOro = global.prezzoTotaleOro + (global.prezzoTotaleOro*percOroBuy);
      global.prezzoTotaleOro = global.prezzoTotaleOro + (global.prezzoTotaleOro*0.001)
    }
    else if(timeOroBuyTemp > 2000){
      global.prezzoTotaleOro = global.prezzoTotaleOro + (global.prezzoTotaleOro*percOroBuy);
      global.prezzoTotaleOro = global.prezzoTotaleOro + (global.prezzoTotaleOro*0.01)
    };
    release@SemaphoreUtils( semPrezzoTotOro )( res )
  }]
  //aggiornaPrezzoPetrolioBuy aggiorna il pezzo dopo aver decrementato la quantità di petrolio dopo l'acquisto
  [aggiornaPrezzoPetrolioBuy(percPetrolioBuy)(){
    getCurrentTimeMillis@Time()( timePetrolioBuy );//ottiene il time corrente dalla cpu in millisecondi
    acquire@SemaphoreUtils( semPrezzoTotPetrolio )( res );
    valPreAbsPetrolio = int(global.timePetrolioBuyTemp-timePetrolioBuy);//salvo la differenza tra due operazioni successive di tipo aggiornaPrezzoPetrolioBuy
    abs@Math( valPreAbsPetrolio )( valPostAbsPetrolio );//dato che la differenza può essere negativa applico il valore assoluto
    global.timePetrolioBuyTemp = valPostAbsPetrolio; 
    //controllo sulla speculazione
    if(timePetrolioBuyTemp <= 1000){
      global.prezzoTotalePetrolio = global.prezzoTotalePetrolio + (global.prezzoTotalePetrolio*percPetrolioBuy);
      global.prezzoTotalePetrolio = global.prezzoTotalePetrolio + (global.prezzoTotalePetrolio*0.0001)
    } 
    else if(timePetrolioBuyTemp> 1000 && timePetrolioBuyTemp <= 2000) {
      global.prezzoTotalePetrolio = global.prezzoTotalePetrolio + (global.prezzoTotalePetrolio*percPetrolioBuy);
      global.prezzoTotalePetrolio = global.prezzoTotalePetrolio + (global.prezzoTotalePetrolio*0.001)
    }
    else if(timePetrolioBuyTemp > 2000){
      global.prezzoTotalePetrolio = global.prezzoTotalePetrolio + (global.prezzoTotalePetrolio*percPetrolioBuy);
      global.prezzoTotalePetrolio = global.prezzoTotalePetrolio + (global.prezzoTotalePetrolio*0.01)
    };
    release@SemaphoreUtils( semPrezzoTotPetrolio )( res )
  }]
  //aggiornaPrezzoGranoSell aggiorna il prezzo dopo avere incrementato la quantità di grano dopo la vendita
  [aggiornaPrezzoGranoSell(percGranoSell)(){
    getCurrentTimeMillis@Time()( timeGranoSell );//ottiene il time corrente della cpu in millisecondi
    acquire@SemaphoreUtils( semPrezzoTotGrano )( res );
    valPreAbsGranoSell = int(global.timeGranoSellTemp-timeGranoSell);//salvo la differenza tra due operazioni successive di tipo aggiornaPrezzoGranoSell
    abs@Math( valPreAbsGranoSell )( valPostAbsGranoSell );//dato che la differenza può essere negativa applico il valore assoluto
    global.timeGranoSellTemp = valPostAbsGranoSell; 
    //controllo sulla speculazione
    if(timeGranoSellTemp <= 1000){
      global.prezzoTotaleGrano = global.prezzoTotaleGrano - (global.prezzoTotaleGrano*percGranoSell);
      prezzoControllo10GranoSell = global.prezzoTotaleGrano - (prezzoControllo10GranoSell*0.0001);
      //controllo per evitare che il valore totale del grano vada sotto il 10
      if( prezzoControllo10GranoSell > 10){
        global.prezzoTotaleGrano = prezzoControllo10GranoSell
      } else {
        global.prezzoTotaleGrano = double(10)
      }
    } 
    else if(timeGranoSellTemp> 1000 && timeGranoSellTemp <= 2000) {
      prezzoControllo10GranoSell = global.prezzoTotaleGrano - (global.prezzoTotaleGrano*percGranoSell);
      prezzoControllo10GranoSell = prezzoControllo10GranoSell - (prezzoControllo10GranoSell*0.001);
      //controllo per evitare che il valore totale del grano vada sotto il 10
      if( prezzoControllo10GranoSell > 10){
        global.prezzoTotaleGrano = prezzoControllo10GranoSell
      } else {
        global.prezzoTotaleGrano = double(10)
      }
    }
    else if(timeGranoSellTemp > 2000){
      prezzoControllo10GranoSell = global.prezzoTotaleGrano - (global.prezzoTotaleGrano*percGranoSell);
      prezzoControllo10GranoSell = prezzoControllo10GranoSell - (prezzoControllo10GranoSell*0.01);
      //controllo per evitare che il valore totale del grano vada sotto il 10
      if( prezzoControllo10GranoSell > 10){
        global.prezzoTotaleGrano = prezzoControllo10GranoSell
      } else {
        global.prezzoTotaleGrano = double(10)
      }
    };
    release@SemaphoreUtils( semPrezzoTotGrano )( res )
  }]
  //aggiornaPrezzoOroSell aggiorna il prezzo dopo aver incrementato la quantità d'oro dopo la vendita
  [aggiornaPrezzoOroSell(percOroSell)(){
    getCurrentTimeMillis@Time()( timeOroSell );//ottiene il time corrente della cpu in millisecondi
    acquire@SemaphoreUtils( semPrezzoTotOro )( res );
    valPreAbsOroSell = int(global.timeOroSellTemp-timeOroSell);//salvo la differenza tra due operazioni successive del tipo aggiornaPrezzoOroSell
    abs@Math( valPreAbsOroSell )( valPostAbsOroSell );//dato che la differenza tra le due operazioni può essere negativa applico il valore assoluto
    global.timeOroSellTemp = valPostAbsOroSell; 
    //controllo sulla speculazione
    if(timeOroSellTemp <= 1000){
      prezzoControllo10OroSell = global.prezzoTotaleOro - (global.prezzoTotaleOro*percOroSell);
      prezzoControllo10OroSell = prezzoControllo10OroSell - (prezzoControllo10OroSell*0.0001);
      //controllo che il valore totale dell'oro non vada al di sotto di 10
      if( prezzoControllo10OroSell > 10){
        global.prezzoTotaleOro = prezzoControllo10OroSell
      } else {
        global.prezzoTotaleOro = double(10)
      }
    } 
    else if(timeOroSellTemp> 1000 && timeOroSellTemp <= 2000) {
      prezzoControllo10OroSell = global.prezzoTotaleOro - (global.prezzoTotaleOro*percOroSell);
      prezzoControllo10OroSell = prezzoControllo10OroSell - (prezzoControllo10OroSell*0.001);
      //controllo che il valore totale dell'oro non vada al di sotto di 10
      if( prezzoControllo10OroSell > 10){
        global.prezzoTotaleOro = prezzoControllo10OroSell
      } else {
        global.prezzoTotaleOro = double(10)
      }
    }
    else if(timeOroSellTemp > 2000){
      prezzoControllo10OroSell = global.prezzoTotaleOro - (global.prezzoTotaleOro*percOroSell);
      prezzoControllo10OroSell = prezzoControllo10OroSell - (prezzoControllo10OroSell*0.01);
      //controllo che il valore totale dell'oro non vada al di sotto di 10
      if( prezzoControllo10OroSell > 10){
        global.prezzoTotaleOro = prezzoControllo10OroSell
      } else {
        global.prezzoTotaleOro = double(10)
      }
    };
    release@SemaphoreUtils( semPrezzoTotOro )( res )
  }]
  //aggiornaPrezzoPetrolioSell aggiorna il prezzo dopo avere incrementato la quantità di petrolio
  [aggiornaPrezzoPetrolioSell(percPetrolioSell)(){
    getCurrentTimeMillis@Time()( timePetrolioSell );//ottiene il time corrente della cpu in millisecondi
    acquire@SemaphoreUtils( semPrezzoTotPetrolio )( res );
    valPreAbsPetrolioSell = int(global.timePetrolioSellTemp-timePetrolioSell);//salvo la differenza di due operazioni successive di tipo aggiornaPrezzoPetrolioSell
    abs@Math( valPreAbsPetrolioSell )( valPostAbsPetrolioSell );//dato che la differenza di tali operazioni può essere negativa applico il valore assoluto
    global.timePetrolioSellTemp = valPostAbsPetrolioSell; 
    //controllo sulla speculazione
    if(timePetrolioSellTemp <= 1000){
      prezzoControllo10PetrolioSell = global.prezzoTotalePetrolio - (global.prezzoTotalePetrolio*percPetrolioSell);
      prezzoControllo10PetrolioSell = prezzoControllo10PetrolioSell - (prezzoControllo10PetrolioSell*0.0001);
      //controllo che il valore totale del pretrolio non vada sotto al 10
      if( prezzoControllo10PetrolioSell > 10){
        global.prezzoTotalePetrolio = prezzoControllo10PetrolioSell
      } else {
        global.prezzoTotalePetrolio = double(10)
      }
    } 
    else if(timePetrolioSellTemp> 1000 && timePetrolioSellTemp <= 2000) {
      prezzoControllo10PetrolioSell = global.prezzoTotalePetrolio - (global.prezzoTotalePetrolio*percPetrolioSell);
      prezzoControllo10PetrolioSell = prezzoControllo10PetrolioSell - (prezzoControllo10PetrolioSell*0.001);
      //controllo che il valore totale del pretrolio non vada sotto al 10
      if( prezzoControllo10PetrolioSell > 10){
        global.prezzoTotalePetrolio = prezzoControllo10PetrolioSell
      } else {
        global.prezzoTotalePetrolio = double(10)
      }
    }
    else if(timePetrolioSellTemp > 2000){
      prezzoControllo10PetrolioSell = global.prezzoTotalePetrolio - (global.prezzoTotalePetrolio*percPetrolioSell);
      prezzoControllo10PetrolioSell = prezzoControllo10PetrolioSell - (prezzoControllo10PetrolioSell*0.01);
      //controllo che il valore totale del pretrolio non vada sotto al 10
      if( prezzoControllo10PetrolioSell > 10){
        global.prezzoTotalePetrolio = prezzoControllo10PetrolioSell
      } else {
        global.prezzoTotalePetrolio = double(10)
      }
    };
    release@SemaphoreUtils( semPrezzoTotPetrolio )( res )
  }]
}