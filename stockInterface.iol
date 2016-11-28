//request response che utilizzo nel service stock.ol
interface StockInterface {
  OneWay: 
  RequestResponse: 
  	ottieniAmountGrano(void)(int),
  	ottieniAmountOro(void)(int),
  	ottieniAmountPetrolio(void)(int),

  	riduciStockGrano(string)(void),
  	riduciStockOro(string)(void),
  	riduciStockPetrolio(string)(void),

    aumentoStockGrano(string)(void),
    aumentoStockOro(string)(void),
    aumentoStockPetrolio(string)(void)
}