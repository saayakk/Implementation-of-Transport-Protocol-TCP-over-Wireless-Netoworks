/*
 * Project: TCP implementation over WSN
 * @Authors: Subramanian Aayakkad
 * 			 Pratik Jain
 * 			 Jigar Parekh	
 * 			 Nikhil More
 * 
 * File: Configuration file for TCP Stop and Wait
 * 
 * Date: 30th March 2015
*/

#include "TCP.h"
#include "TestSerial.h"

configuration TCPAppC
{
	
}

implementation
{
	
	components TCPC as App;		// Component of our module file
	
	// Component for Boot and LEDs
	components MainC;
	components LedsC;
	
	// Components for Timers
	components new TimerMilliC() as timer0;
	components new TimerMilliC() as timer1;
	components new TimerMilliC() as timer2;
	components new TimerMilliC() as timer3;
	components new TimerMilliC() as timer4;
	components new TimerMilliC() as timer5;
	components new TimerMilliC() as timeout;
	
	components RandomC;
	
	// Components for Radio Sender
	components new AMSenderC(AM_TCP) as sender;
	components ActiveMessageC;
	
	// Components for Radio Receiver
	components new AMReceiverC(AM_TCP) as receiver;
	
	// Component for Serial communication
	components SerialActiveMessageC as serial;
	
	// Wiring of components
	App.Boot -> MainC.Boot;
	App.Leds -> LedsC.Leds;
	
	App.timer0 -> timer0;
	App.timer1 -> timer1;
	App.timer2 -> timer2;
	App.timer3 -> timer3;
	App.timer4 -> timer4;
	App.timer5 -> timer5;
	App.timeout -> timeout;
	
	App.Random-> RandomC;
	
	App.radioAMSend -> sender.AMSend;
	App.AMPacket -> sender.AMPacket;
	App.Packet -> sender.Packet;
	App.AMControlRadio -> ActiveMessageC.SplitControl;
	
	App.radioReceive -> receiver.Receive;
	
	App.serialReceive -> serial.Receive[AM_TEST_SERIAL_MSG];
	App.serialAMSend -> serial.AMSend[AM_TEST_SERIAL_MSG];
	App.AMControlSerial -> serial.SplitControl;
	
	
	
	
}
