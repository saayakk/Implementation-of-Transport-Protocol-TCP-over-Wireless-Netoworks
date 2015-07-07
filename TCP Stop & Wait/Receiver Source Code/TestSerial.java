/*
 * Project: TCP implementation over WSN
 * @Authors: Subramanian Aayakkad
 * 			 Pratik Jain
 * 			 Jigar Parekh	
 * 			 Nikhil More
 * 
 * File: TestSerial file for TCP Stop and Wait
 * 
 * Date: 30th March 2015
 * 
 * Reference: TestSerial.java inbuilt application of TinyOS is modified for serial communication
*/

import java.io.*;
import java.util.*;
import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

public class TestSerial implements MessageListener {

  static int size = 0;
  static int packetsize = 100;
  static int arr[] = new int[packetsize]; 
  private MoteIF moteIF;
  //public static File file;
  //public static BufferedWriter output;
  
  public TestSerial(MoteIF moteIF) {
    this.moteIF = moteIF;
    this.moteIF.registerListener(new TestSerialMsg(), this);
  }

  public void sendPackets() throws Exception {
    int counter = 0;
    int j=0;
    TestSerialMsg payload = new TestSerialMsg();
    Scanner scanner = new Scanner(new File("input.txt"));
		int [] countarr = new int [scanner.nextInt()];
		int i = 0;
		while(scanner.hasNextInt()){
		  countarr[i] = scanner.nextInt();
		  i+=1;
		}
		
    try {
      while (j<1){//countarr.length) {
	//while(k!=0){
	//System.out.println("Sending packet seq no. " + counter);
	//counter=countarr[j];
	counter = 1;
	payload.set_counter(counter);
	moteIF.send(10, payload);
	j++;
	try {Thread.sleep(1000);}
	catch (InterruptedException exception) {}
      }
    }
    catch (IOException exception) {
      System.err.println("Exception thrown when sending packets. Exiting.");
      System.err.println(exception);
    }
  }

  public void messageReceived(int to, Message message) {
    TestSerialMsg msg = (TestSerialMsg)message;
	int x = msg.get_counter();
    System.out.println("Received Data: " + x);
    
	if(size < packetsize)
	{
	   arr[size] = x;
	   System.out.println(arr[size]);
	}
	if(size == (packetsize - 1))
	{
	   System.out.println("Now writing file");
	   write();
	}
	++size;
  }

  public static void write()
  {
	try
	{
		File file = new File("example.txt");
		BufferedWriter output = new BufferedWriter(new FileWriter(file));
		int i = 0;
		while(i < packetsize)
		{
		System.out.println("Writing data : " + arr[i]);
		output.write((new Integer(arr[i])).toString() + '\n');
		++i;
		}
		output.close();
	}
	catch(Exception e){}
}
  
  private static void usage() {
    System.err.println("usage: TestSerial [-comm <source>]");
  }
  
  public static void main(String[] args) throws Exception {

    String source = null;
    if (args.length == 2) {
      if (!args[0].equals("-comm")) {
	usage();
	System.exit(1);
      }
      source = args[1];
    }
    else if (args.length != 0) {
      usage();
      System.exit(1);
    }
    
    PhoenixSource phoenix;
    
    if (source == null) {
      phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
    }
    else {
      phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
    }

    MoteIF mif = new MoteIF(phoenix);
    TestSerial serial = new TestSerial(mif);
    serial.sendPackets();
  }


}
