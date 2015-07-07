/*
 * Project: TCP Implementation over WSN
 * @Author: Subramanian Aayakkad
 * 			Pratik Jain
 * 			Jigar Parek
 * 			Nikhil More
 * 
 * File : Configuration File for TCP GO -Back-N 
 * 
 * Date : 15th April 2015
 */

#include "TCP.h"
#include "TestSerial.h"

configuration TCPAppC
{
	
}

implementation
{
	//Component of Module file
	components TCPC as App;
	
	//General Components
	components MainC;
	components LedsC;
	
	components new TimerMilliC() as timer0;
	components new TimerMilliC() as timer1;
	components new TimerMilliC() as timer2;
	components new TimerMilliC() as timer3;
	components new TimerMilliC() as timer4;
	components new TimerMilliC() as timer5;
	components new TimerMilliC() as timerpc;
	components new TimerMilliC() as timeout;
	
	components RandomC;
	
	//Components to send and receive over radio
	components new AMSenderC(AM_TCP) as sender;
	components ActiveMessageC;	
	components new AMReceiverC(AM_TCP) as receiver;
	
	//Component for Serial Communication
	components SerialActiveMessageC as serial;
	
	//Wiring of Components
	App.Boot -> MainC.Boot;
	App.Leds -> LedsC.Leds;
	App.Random-> RandomC;
	App.timer0 -> timer0;
	App.timer1 -> timer1;
	App.timer2 -> timer2;
	App.timer3 -> timer3;
	App.timer4 -> timer4;
	App.timer5 -> timer5;
	App.timerpc -> timerpc;
	App.timeout -> timeout;
	
	//Wiring of Serial Components
	App.serialReceive -> serial.Receive[AM_TEST_SERIAL_MSG];
	App.serialAMSend -> serial.AMSend[AM_TEST_SERIAL_MSG];
	
	App.AMControlRadio -> ActiveMessageC.SplitControl;
	App.AMControlSerial -> serial.SplitControl;
	
	App.radioAMSend -> sender.AMSend;
	App.AMPacket -> sender.AMPacket;
	App.Packet -> sender.Packet;
	
	App.radioReceive -> receiver.Receive;
}
