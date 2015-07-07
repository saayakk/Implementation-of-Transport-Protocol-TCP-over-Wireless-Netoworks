/*
 * Project: TCP Implementation over WSN
 * @Author: Subramanian Aayakkad
 * 			Pratik Jain
 * 			Jigar Parek
 * 			Nikhil More
 * 
 * File : Module File for TCP GO -Back-N Receiver(Complete Implementation code)
 * 
 * Date : 15th April 2015
 */

#include "TCP.h"
#include "TestSerial.h"
#include <Timer.h>

module TCPC
{
	//General Interfaces
	uses
	{
		interface Boot;
		interface Leds;
		interface Timer<TMilli> as timer0;
		interface Timer<TMilli> as timer1;
		interface Timer<TMilli> as timer2;
		interface Timer<TMilli> as timer3;
		interface Timer<TMilli> as timer4;
		interface Timer<TMilli> as timer5;
		interface Timer<TMilli> as timeout;
	}
	
	//Interfaces to send on Radio
	uses
	{
		interface AMSend as radioAMSend;
		interface Packet;
		interface AMPacket;
		interface SplitControl as AMControlRadio;
	}
	
	uses interface SplitControl as AMControlSerial;
	
	uses interface AMSend as serialAMSend;
	
	uses interface Receive as radioReceive;
	
	uses interface Receive as serialReceive;
		
	uses interface Random;
		
}

implementation
{
	message_t packet;
	bool radioBusy = FALSE;
	uint64_t counter = 0;
	uint16_t seqNo = 0;	
	uint16_t ackNo = 0;
	uint16_t loopCount = 1;
	uint16_t loopNo = 0;
	uint16_t delay = 0;
	
	int i = 0;
	int16_t input[sz]; 		//To receive data from PC	
	
	//Function to send SYNACK
	void sendSYNACK()
	{
		//Fomration of packet
		tcpMessage_t* tcpmsg = (tcpMessage_t*)(call Packet.getPayload(&packet,
									sizeof(tcpMessage_t)));
		tcpmsg->dip = 20;
		tcpmsg->sip = 10;		
		tcpmsg->type = 1;
		
		//Sending the packet
		if(call radioAMSend.send(20, &packet, sizeof(tcpMessage_t))
						 == SUCCESS)
		{
			radioBusy = TRUE; //To check if radio is busy or not
		}
	}
	
	//Function to send ACK for data
	void sendACK()
	{
		tcpMessage_t* tcpmsg = (tcpMessage_t*)(call Packet.getPayload(&packet,
									sizeof(tcpMessage_t)));
		
		//Assigning values to the field of the packet
		tcpmsg->dip = 20;
		tcpmsg->sip = 10;		
		tcpmsg->type = 7;
		//tcpmsg->data = counter + 1; 
		tcpmsg->ackNo = ackNo;
		
		if(call radioAMSend.send(20, &packet, sizeof(tcpMessage_t))
						 == SUCCESS)
		{
			radioBusy = TRUE;
		}
	}

	//Send function for ACK of FIN
	void sendACKF()
	{
		tcpMessage_t* tcpmsg = (tcpMessage_t*)(call Packet.getPayload(&packet,
									sizeof(tcpMessage_t)));
		tcpmsg->dip = 20;
		tcpmsg->sip = 10;		
		tcpmsg->type = 9;

		if(call radioAMSend.send(20, &packet, sizeof(tcpMessage_t))
						 == SUCCESS)
		{
			ackfFlag = 1;
			radioBusy = TRUE;
		}
	}
	
	//Send data over Serial to PC
	void sendToPC()
	{
		test_serial_msg_t* rcm = (test_serial_msg_t*)call Packet.getPayload(&packet,
												 sizeof(test_serial_msg_t));
												 
		rcm->counter = counter;	//== seqNo if ack received and called
		if (call serialAMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(test_serial_msg_t)) == SUCCESS)
		{
			radioBusy = TRUE;
		}		
	}
	
	//Event to Boot the system
	event void Boot.booted()
	{
		call AMControlRadio.start();
		call AMControlSerial.start();
		call Leds.led2On();
		//sendSYN();
	}
	
	//Timer events
	event void timer0.fired()		//Sending SYNACK
	{
		call Leds.led0Off();
		sendSYNACK();
	}
	
	event void timer1.fired()		//Sending ACK
	{
		
	}
	
	event void timer2.fired()		//Sending Data
	{
		
	}
	
	event void timer3.fired()		//Sending ACK for Data
	{
		call Leds.led1Off();
		call Leds.led0Off();
		call Leds.led2Off();
		sendACK();
		
	}
	
	event void timer4.fired()	//timeout for Data or ACK loss
	{
		
	}
	
	event void timer5.fired()		//Sending ACK for FIN received
	{
		call Leds.led1Off();
		sendACKF();
	}
	
	
	event void timeout.fired()		//Check Timeout for SYNACK n
	{
		if(acksFlag == 0)
		{
			sendSYNACK();
		}
	}
	
	//Receive function for receiving all types of data
	event message_t * radioReceive.receive(message_t *msg, void *payload, uint8_t len)
	{
		tcpMessage_t* tcpmsg =(tcpMessage_t*)payload;
		
		if(tcpmsg->sip == 20 && tcpmsg->dip == 10)
		{
			
			if(tcpmsg->type == 0)	//SYN received
			{
				synFlag = 1;
				call Leds.led2Off();
				//call Leds.led0On();
				call timer0.startOneShot(1000);
				return msg;
			}
			
			
			if(tcpmsg->type == 2)	//ACKS received
			{
				connectedFlag = 1;
				acksFlag = 1;
				return msg;
			}
			
			if(tcpmsg->type == 4 && connectedFlag == 1)	//DATA received only when connection 
			{
				dataFlag = 1;
				call Leds.led1Off();
				call Leds.led0Off();
				call Leds.led2Off();
				
				//Artificial Packet loss or check if out of order packet
				if((((call Random.rand16()) % 2) == 2) || (ackNo != tcpmsg->seqNo))
				{
					call Leds.led1On();
					call timer3.startOneShot(200);	//Call to send NAK
				}
				else
				{
					counter = tcpmsg->data;
					
					//Increase ackNo and send to sender if proper data received
					ackNo = tcpmsg->seqNo + 1;
					call Leds.set(counter);
					sendToPC();
					call timer3.startOneShot(200);	//Call to send ACK
				}
				return msg;
			}
			
			if(tcpmsg->type == 5)   //FIN received
			{
				finFlag = 1;
				call Leds.set(0);
				call Leds.led0On();
				call timer5.startOneShot(5000);
				return msg;
			}
		}
		return msg;
	}
	
	
	event message_t * serialReceive.receive(message_t *msg, void *payload, uint8_t len) //Receive from PC
	{
		test_serial_msg_t* received = (test_serial_msg_t*)payload;
		input[i] = received->counter;
		call Leds.set(input[i]);
		++i;
		return msg;
	}
	
	//Send function over Radio
	event void radioAMSend.sendDone(message_t *msg, error_t error)
	{
		if(msg == &packet)
		{
			radioBusy = FALSE;
		}
		if(ackfFlag == 1)
		{
			call AMControlRadio.stop();
		}
	}
	
	event void serialAMSend.sendDone(message_t *msg, error_t error)
	{
		
	}		

	event void AMControlRadio.startDone(error_t error)
	{
		if(error != SUCCESS)
		{
			call AMControlRadio.start();
		}
	}

	event void AMControlSerial.startDone(error_t error)
	{
		if(error != SUCCESS)
		{
			call AMControlSerial.start();
		}
	}
	
	event void AMControlRadio.stopDone(error_t error)
	{
		call Leds.set(7);
		if(error != SUCCESS && ackfFlag == 0)
		{
			call AMControlRadio.start();
		}
	}

	event void AMControlSerial.stopDone(error_t error)
	{
		
	}
}
