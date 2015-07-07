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

public class TestSerial implements MessageListener 
{

  private MoteIF moteIF;

  public double start = 0;
  public double stop = 0;
  public int length = 0;
  public int type = 0;
  
  public TestSerial(MoteIF moteIF) 
  {
    this.moteIF = moteIF;
    this.moteIF.registerListener(new TestSerialMsg(), this);
  }

 // Function to send packets to Base Station
  public void sendPackets() throws Exception 
  {
    int counter = 0;
    int j=0;
    TestSerialMsg payload = new TestSerialMsg();
    
    // Taking input from data file
    Scanner scanner = new Scanner(new File("input.txt"));
		int countarr[] = new int [scanner.nextInt()];
		length = countarr.length;
		int i = 0;
		while(scanner.hasNextInt())  // Reading into the array
		{
		  countarr[i] = scanner.nextInt();
		  ++i;
		}
	scanner.close();
		
    try 
    {
	    start = System.nanoTime(); 
	    while (j<length) 
	    {
			counter = countarr[j];
			payload.set_counter(counter);
			moteIF.send(20, payload);
			j++;
			try 
			{
				Thread.sleep(100);
			}
			catch (InterruptedException exception) {}
    	}
    }
    catch (IOException exception) 
    {
      System.err.println("Exception thrown when sending packets. Exiting.");
      System.err.println(exception);
    }
  }

  public void messageReceived(int to, Message message) 
  {
    TestSerialMsg msg = (TestSerialMsg)message;
    if(msg.get_type()==7)				//SYN sent
	{
		System.out.println("Sending SYN");
	}
    else if(msg.get_type()==8)				//SYNACK received
	{
		System.out.println("Received SYNACK");
	}
    else if(msg.get_type()==9)				//ACKS sent
	{
		System.out.println("Sending ACKS");
	}   
    else if(msg.get_type()==0 && msg.get_counter() != length)		//Data Sent
	{
		System.out.println("Sending packet Seq. Number " + (msg.get_counter()));
	}
    else if(msg.get_type()==1)						//ACK received
	{
		System.out.println("Received Ack number " + msg.get_counter());
	}	
    if(msg.get_counter() == length)					// Print time
	{
		stop = System.nanoTime(); 
		System.out.println("Time taken: " + (stop - start));
	}
  }
  
  private static void usage() 
  {
    System.err.println("usage: TestSerial [-comm <source>]");
  }
  
  public static void main(String[] args) throws Exception 
  {
    String source = null;
    if (args.length == 2)
    {
      if (!args[0].equals("-comm")) 
      {
		usage();
		System.exit(1);
      }
      source = args[1];
    }
    else if (args.length != 0) 
    {
      usage();
      System.exit(1);
    }
    
    PhoenixSource phoenix;
    
    if (source == null) 
    {
      phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
    }
    else 
    {
      phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
    }

    MoteIF mif = new MoteIF(phoenix);
    TestSerial serial = new TestSerial(mif);
    serial.sendPackets();
  }


}
