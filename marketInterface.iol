//struttura stock
type Stock: void {
	.name: string
	.amount: int
    .totValue: double
}
//struttura player
type Player: void {
		.name: string
		.cash: double
		.stockOro: int
		.stockGrano: int
		.stockPetrolio: int
        .index: int
}
//struttura che serve per ricevere le informazioni dopo l'acquisto
type InfoAcquista: void {
    .cash: double
    .incremento: int
    .prezzoUnitario: double
}
//struttura che serve per ricevere le informazioni dopo la vendita
type InfoVendita: void {
    .cash: double
    .decremento: int
    .prezzoUnitario: double
}
//struttura che utilizza il player per ricevere informazzioni dal market
type Info: void {
  .prezzoTotaleGrano: double
  .prezzoTotaleOro: double
  .prezzoTotalePetrolio: double
  .amountGrano: int
  .amountPetrolio: int
  .amountOro: int
}

//Request Response che uso nel market
interface MarketInterface {
    RequestResponse: 
    creaAccount(string)(Player), 
    ottieniInfo(string)(Info),
    controlloStock(void)(bool),

    registraOro(Stock)(void), 
    registraPetrolio(Stock)(void), 
    registraGrano(Stock)(void),
    
    aggiornaPrezzoGranoProd(double)(void),
    aggiornaPrezzoGranoDeper(double)(void),
    aggiornaPrezzoOroProd(double)(void),
    aggiornaPrezzoPetrolioProd(double)(void),
    aggiornaPrezzoPetrolioDeper(double)(void),

    acquistaGrano(int)(InfoAcquista),
    acquistaOro(int)(InfoAcquista),
    acquistaPetrolio(int)(InfoAcquista),

    vendiGrano(int)(InfoVendita),
    vendiOro(int)(InfoVendita),
    vendiPetrolio(int)(InfoVendita),

    aggiornaPrezzoGranoBuy(double)(void),
    aggiornaPrezzoOroBuy(double)(void),
    aggiornaPrezzoPetrolioBuy(double)(void),

    aggiornaPrezzoGranoSell(double)(void),
    aggiornaPrezzoOroSell(double)(void),
    aggiornaPrezzoPetrolioSell(double)(void)
}