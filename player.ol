include "console.iol"
include "marketInterface.iol"
include "time.iol"
include "math.iol"

outputPort OutputMarket {
	Location: "socket://localhost:8000"
	Protocol: sodep
	Interfaces: MarketInterface
}

init
{
  registerForInput@Console()();
  print@Console( "Nome Player: " )();
  in( name );
  //name="Pietro";
  //name="Andrea";
  //name=args[0];
  //intelligenza=args[1];

  println@Console( "Intelligenze disponibili \n1)COMPRA-VENDI\n2)Compra-VENDIalGuadagno\nScegliere (1 o 2): " )();
  in( intelligenza );

  //invio al market il nome del player per poi ricevere la conferma della registrazione 
  //ricevendo la struttura player che contiene il nome, denaro, e stock 
  creaAccount@OutputMarket(name)(global.Player);
  stampaPlayer;

  //controllo registrazione stock
  // metto in attesa i player fin quando un palyer non si registra
  controlloStock@OutputMarket()(res);
  while(res!=true){
    controlloStock@OutputMarket()(res);
    print@Console( "Controllo disponibilità Stock" )();
    sleep@Time(250)();
    print@Console( "." )();
    sleep@Time(250)();
    print@Console( "." )();
    sleep@Time(250)();
    print@Console( ".\n" )();
    sleep@Time(1000)()
  };
  println@Console( "Stock DISPONIBILI!!!!!\n" )()
}

//DEFINE generale per richedere la stampa del player
define stampaPlayer
{
      println@Console( global.Player.name + "\nSoldi Disponibili: " + 
        global.Player.cash + "\nStock Acquistati: \n" + 
        global.Player.stockOro + " (Oro)\n" + 
        global.Player.stockPetrolio + " (Petrolio)\n" +
        global.Player.stockGrano + " (Grano)\n" +
        global.Player.index +
        "------------------------------\n" )()
}

//Define generale per inviare la richiesta d'acquisto al market
define acquista
{

  if( stockAcquista == "grano" ) {//controllo che permette di verificare che si vuole acquistare il grano
    acquistaGrano@OutputMarket( global.Player.index )( InfoAcquistoGrano );//inivo al market la richiesta di acquisto grano passandoli l'indice del palyer 
    //registrto ricevo dal market in risposta InfoAcquistoGrano che è una struttura che contiene l'incremento (se è riuscito ad acquistare) il cash aggiornato e 
    //il prezzo unitario del grano.
    //controllo se l'incremento è uguale a 1 significa che è riuscito ad acquistare
    if(InfoAcquistoGrano.incremento == 1) {
      global.Player.stockGrano++;//incremento lo stock grano in possesso del player
      global.Player.cash = InfoAcquistoGrano.cash;//aggiorno il cash del palyer dopo l'acquisto
      println@Console( "Acquisto Grano -- EFFETTUATO -- Prezzo Unitario: " + InfoAcquistoGrano.prezzoUnitario + "\n" )()
    } else {//se l'incremento è diverso da uno ovvero è ugaule a zero 
      global.Player.cash = InfoAcquistoGrano.cash;//salvo il cash che nel market non viene aggiorato perchè l'acquisto non è andato a buon fine.
      println@Console( "Acquisto Grano -- NEGATO\n" )()
    }
  } else if( stockAcquista == "oro" ) {//controllo che permette di verificare che si vuole acquistare l'oro
    acquistaOro@OutputMarket( global.Player.index )( InfoAcquistoOro );
    if( InfoAcquistoOro.incremento == 1){
      global.Player.stockOro++;//incremento lo stock oro in possesso del player
      global.Player.cash = InfoAcquistoOro.cash;//aggiorno il cash del palyer dopo l'acquisto
      println@Console( "Acquisto Oro -- EFFETTUATO -- Prezzo Unitario: " + InfoAcquistoOro.prezzoUnitario + "\n" )()
    } else {
      global.Player.cash = InfoAcquistoOro.cash;
      println@Console( "Acquisto Oro -- NEGATO\n" )()
    }
    
  } else if( stockAcquista == "petrolio" ){
    acquistaPetrolio@OutputMarket( global.Player.index )( InfoAcquistoPetrolio );
    //controllo se l'incremento è uguale a 1 significa che è riuscito ad acquistare
    if( InfoAcquistoPetrolio.incremento == 1 ){
      global.Player.stockPetrolio++;//incremento lo stock petrolio in possesso del player
      global.Player.cash = InfoAcquistoPetrolio.cash;//aggiorno il cash del palyer dopo l'acquisto
      println@Console( "Acquisto Petrolio -- EFFETTUATO -- Prezzo Unitario: " + InfoAcquistoPetrolio.prezzoUnitario + "\n" )()
    } else {//se l'incremento è diverso da uno ovvero è ugaule a zero 
      global.Player.cash = InfoAcquistoPetrolio.cash;
      println@Console( "Acquisto Petrolio -- NEGATO\n" )()
    }

  }
}
//Define generale per inviare la richiesta di vendita al market
define vendi
{
  //controllo che permette di verificare che si vuole vendere il grano  
  if( stockVendi == "grano" ) {
    if(global.Player.stockGrano > 0){//controllo se il player ha stock per poterli vendere
      vendiGrano@OutputMarket(global.Player.index)(InfoVenditaGrano);
      if(InfoVenditaGrano.decremento == 1){
        global.Player.stockGrano--;
        global.Player.cash = InfoVenditaGrano.cash;
        println@Console( "Vendita Grano -- EFFETTUATA -- Prezzo Unitario: " + InfoVenditaGrano.prezzoUnitario + "\n" )()
      } else {
        global.Player.cash = InfoVenditaGrano.cash;
        println@Console( "Vendita Grano -- NEGATA\n" )()
      }
    }
  }
  //controllo che permette di verificare che si vuole vendere l'oro
  else if( stockVendi == "oro" ) {
    if(global.Player.stockOro > 0){//controllo se il player ha stock per poterli vendere
      vendiOro@OutputMarket(global.Player.index)(InfoVenditaOro);
      if(InfoVenditaOro.decremento == 1){
        global.Player.stockOro--;
        global.Player.cash = InfoVenditaOro.cash;
        println@Console( "Vendita Oro -- EFFETTUATA -- Prezzo Unitario: " + InfoVenditaOro.prezzoUnitario + "\n" )()
      } else {
        global.Player.cash = InfoVenditaOro.cash;
        println@Console( "Vendita Oro -- NEGATA\n" )()
      }
    }  
  }
  //controllo che permette di verificare che si vuole vendere il petrolio
  else if( stockVendi == "petrolio" ) {
    if(global.Player.stockPetrolio > 0){//controllo se il player ha stock per poterli vendere
      vendiPetrolio@OutputMarket(global.Player.index)(InfoVenditaPetrolio);
      if(InfoVenditaPetrolio.decremento == 1){
        global.Player.stockPetrolio--;
        global.Player.cash = InfoVenditaPetrolio.cash;
        println@Console( "Vendita Petrolio -- EFFETTUATA -- Prezzo Unitario: " + InfoVenditaPetrolio.prezzoUnitario + "\n" )()
      } else {
        global.Player.cash = InfoVenditaPetrolio.cash;
        println@Console( "Vendita Petrolio -- NEGATA\n" )()
      }
    }  
  }
}
//DEFINE PER STAMPARE LE INFO RICHIESTE DAL PLAYER
define info
{
  ottieniInfo@OutputMarket( name )(Info);
  println@Console( "\n" + Info.prezzoTotaleOro + " (Prezzo oro)" )();
  println@Console( "\n" + Info.amountOro + " (Quantità oro)" )();
  println@Console( "\n" + Info.prezzoTotaleGrano + " (PrezzoGrano)" )();
  println@Console( Info.amountGrano + " (Quantità Grano)" )();
  println@Console( Info.prezzoTotalePetrolio + " (PrezzoPetrolio)\n" )();
  println@Console( Info.prezzoTotalePetrolio + " (QuantitàPetrolio)\n" )()
}

define intelligenza1
{
  while(true) {
    ottieniInfo@OutputMarket( name )( Info );
    prezzoGrano = Info.prezzoTotaleGrano;
    prezzoOro = Info.prezzoTotaleOro;
    prezzoPetrolio = Info.prezzoTotalePetrolio;
    if(global.Player.cash > 5){
      stockAcquista = "grano";
      acquista;
      stampaPlayer;
      sleep@Time(3000)();
      ottieniInfo@OutputMarket( name )( Info );
      if(Info.prezzoTotaleGrano > prezzoGrano ){
        stockVendi = "grano";
        vendi;
        stampaPlayer;
        sleep@Time(3000)()
      };
      stockAcquista = "oro";
      acquista;
      stampaPlayer;
      sleep@Time(3000)();
      ottieniInfo@OutputMarket( name )( Info );
      if(Info.prezzoTotaleGrano > prezzoGrano ){
        stockVendi = "oro";
        vendi;
        stampaPlayer;
        sleep@Time(3000)()
      };
      stockAcquista = "petrolio";
      acquista;
      stampaPlayer;
      sleep@Time(3000)();
      ottieniInfo@OutputMarket( name )( Info );
      if(Info.prezzoTotaleGrano > prezzoGrano ){
        stockVendi = "petrolio";
        vendi;
        stampaPlayer;
        sleep@Time(3000)()
      }  
    } else {
      while( global.Player.stockGrano > 0 || global.Player.stockOro > 0 || global.Player.stockPetrolio > 0){
        stockVendi = "grano";
        vendi;
        stampaPlayer;
        sleep@Time(100)();
        stockVendi = "oro";
        vendi;
        stampaPlayer;
        sleep@Time(100)();
        stockVendi = "petrolio";
        vendi;
        stampaPlayer;
        sleep@Time(100)()
      }
    }
  }
}

define compraVendi
{
    while(true) {
      ottieniInfo@OutputMarket( name )( Info );
      stockAcquista = "grano";
      acquista;
      stampaPlayer;
      sleep@Time(1500)();
      
      ottieniInfo@OutputMarket( name )( Info );
      stockVendi = "grano";
      vendi;
      stampaPlayer;
      sleep@Time(1500)();
      
      ottieniInfo@OutputMarket( name )( Info );
      stockAcquista = "oro";
      acquista;
      stampaPlayer;
      sleep@Time(1500)();
      
      ottieniInfo@OutputMarket( name )( Info );
      stockVendi = "oro";
      vendi;
      stampaPlayer;
      sleep@Time(1500)();
      
      ottieniInfo@OutputMarket( name )( Info );
      stockAcquista = "petrolio";
      acquista;
      stampaPlayer;
      sleep@Time(1500)();
      
      ottieniInfo@OutputMarket( name )( Info );
      stockVendi = "petrolio";
      vendi;
      stampaPlayer;
      sleep@Time(1500)()
    }
}


main
{   
	if(intelligenza == 1){
    compraVendi
  } else if (intelligenza == 2) {
    intelligenza1
  }
  //compraVendi
}