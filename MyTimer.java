import jolie.runtime.JavaService;
import jolie.net.CommMessage;
import jolie.runtime.Value;
import java.util.concurrent.Executors;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.TimeUnit;

public class MyTimer extends JavaService {

  final private ExecutorService executorService = Executors.newCachedThreadPool();

  private class MyTimerRunnable implements Runnable {
    MyTimer parent;
    String callbackOperation;
    Value callbackValue;
    long waitTime;

    public MyTimerRunnable( MyTimer parent, String callbackOperation, Value callbackValue, long waitTime ) {
      this.parent = parent;
      this.callbackOperation = callbackOperation;
      this.callbackValue = callbackValue;
      this.waitTime = waitTime;
    }

    public void run() {
      try {
        TimeUnit.MILLISECONDS.sleep( waitTime );
        parent.sendMessage( CommMessage.createRequest( callbackOperation, "/", callbackValue ) );
      } catch ( InterruptedException e ){ System.out.println( "InterruptedException" ); }
    }
  }

  public void setNextTimeout( Value request ){
    long waitTime = request.intValue();
    String callbackOperation = request.children().get( "operation" ).first().strValue();
    Value callbackValue = null;
    if ( ( request.children().get( "message" ) ) != null ) {
      callbackValue = request.children().get( "message" ).first();
    }
    executorService.submit( 
      new MyTimerRunnable( this, callbackOperation, callbackValue, waitTime ) );  
    }

}