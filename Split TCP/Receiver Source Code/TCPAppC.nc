/* Project: TCP Implementation on Wireless Sensor Nodes (WSN) 
 * @Authors: Subramanian Aayakkad
 * 			 Pratik Jain  
 * 			 Jigar Parekh	
 * 			 Nikhil More
 * 
 * Date: 	12th April 2015
 * 
 * Configuration Source File of the Project
 */

#include "TCP.h"
#include "TestSerial.h"


configuration TCPAppC
{
	
}

implementation
{
	
	components TCPC as App;
	
	components MainC;
	components LedsC;
	
	components new TimerMilliC() as timer0;
	components new TimerMilliC() as timer1;
	components new TimerMilliC() as timer2;
	components new TimerMilliC() as timer3;
	components new TimerMilliC() as timer4;
	components new TimerMilliC() as timer5;
	components new TimerMilliC() as timeout;
	
	components RandomC;	 
	
	components new AMSenderC(AM_TCP) as sender;
	components ActiveMessageC;
	
	components new AMReceiverC(AM_TCP) as receiver;
	
	components SerialActiveMessageC as serial;
	
	App.Boot -> MainC.Boot;
	App.Leds -> LedsC.Leds;
	
	App.timer0 -> timer0;
	App.timer1 -> timer1;
	App.timer2 -> timer2;
	App.timer3 -> timer3;
	App.timer4 -> timer4;
	App.timer5 -> timer5;
	App.timeout -> timeout;
	
	App.Random -> RandomC;
	
	App.AMControlRadio -> ActiveMessageC.SplitControl;
	
	App.AMControlSerial -> serial.SplitControl;
	
	App.radioAMSend -> sender.AMSend;
	App.AMPacket -> sender.AMPacket;
	App.Packet -> sender.Packet;
	
	App.serialAMSend -> serial.AMSend[AM_TEST_SERIAL_MSG];
	
	App.radioReceive -> receiver.Receive;
	
	App.serialReceive -> serial.Receive[AM_TEST_SERIAL_MSG];
}
