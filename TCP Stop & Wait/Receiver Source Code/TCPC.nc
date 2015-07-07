/* Project: TCP Implementation on Wireless Sensor Nodes (WSN) 
 * @Authors: Subramanian Aayakkad
 * 			 Pratik Jain  
 * 			 Jigar Parekh	
 * 			 Nikhil More
 *
 * File : Module File for Receiver Stop & Wait (COmplete implementation of code) 
 *
 * Date: 	30th March 2015
 *  
 */

#include "TCP.h"
#include "TestSerial.h"
#include <Timer.h>

module TCPC
{
	//General interfaces
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
	
	// Radio interfaces
	uses
	{
		interface AMSend as radioAMSend;
		interface Packet;
		interface AMPacket;
		interface Receive as radioReceive;
		interface SplitControl as AMControlRadio;
	}
	
	// Serial interfaces
	uses
	{
		interface SplitControl as AMControlSerial;
		interface AMSend as serialAMSend;
		interface Receive as serialReceive;
	}
		
	uses interface Random;
		
}

implementation
{
	message_t packet;
	bool radioBusy = FALSE;
	uint64_t counter = 0;
	uint16_t seqNo = 0;	
	uint16_t ackNo = 0;
	
	int16_t input[sz];
	int i = 0;
	
	// To send SYNACK for the SYN received
	void sendSYNACK()
	{
		
		tcpMessage_t* tcpmsg = (tcpMessage_t*)(call Packet.getPayload(&packet,
									sizeof(tcpMessage_t)));
		tcpmsg->dip = 20;
		tcpmsg->sip = 10;		
		tcpmsg->type = 1;
		
		if(call radioAMSend.send(20, &packet, sizeof(tcpMessage_t))
						 == SUCCESS)
		{
			radioBusy = TRUE;
		}
	}
	
	// To send ACK for the Data packet received
	void sendACK()
	{
		tcpMessage_t* tcpmsg = (tcpMessage_t*)(call Packet.getPayload(&packet,
									sizeof(tcpMessage_t)));
		tcpmsg->dip = 20;
		tcpmsg->sip = 10;		
		tcpmsg->type = 7; 
		tcpmsg->seqNo = ackNo;
		
		if(call radioAMSend.send(20, &packet, sizeof(tcpMessage_t))
						 == SUCCESS)
		{
			radioBusy = TRUE;
		}
	}

	// To send ACK for the for the FIN received, connection termination
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
	
	// To display data to PC
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

	event void Boot.booted()
	{
		call AMControlRadio.start();
		call AMControlSerial.start();
		call Leds.led2On();
	}
	
	event void timer0.fired()		
	{
		call Leds.led0Off();
		sendSYNACK();
	}
	
	event void timer1.fired()		
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
	
	event void timer4.fired()	
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
	
	event message_t * radioReceive.receive(message_t *msg, void *payload, uint8_t len)
	{
		tcpMessage_t* tcpmsg =(tcpMessage_t*)payload;
		
		if(tcpmsg->sip == 20 && tcpmsg->dip == 10)
		{
		
			if(tcpmsg->type == 0)	//SYN received
			{
				synFlag = 1;
				call Leds.led2Off();
				
				call timer0.startOneShot(1000); //Sending SYNACK
				return msg;
			}
			
			
			if(tcpmsg->type == 2)	//ACKS received
			{
				connectedFlag == 1;
				acksFlag = 1;
				return msg;
			}
			
			
			if(tcpmsg->type == 4 && connectedFlag == 1)	//DATA received
			{
				dataFlag = 1;
				call Leds.led1Off();
				call Leds.led0Off();
				call Leds.led2Off();

				//Artificaial packet loss or check for out of order packets
				if((((call Random.rand16()) % 7) == 0) || (ackNo != tcpmsg->seqNo))
				{
					call Leds.led1On();
					ackNo = tcpmsg->seqNo;
					call timer3.startOneShot(1000);	//Call to send NAK
				}
				else
				{
					counter = tcpmsg->data;
					ackNo = tcpmsg->seqNo + 1;
					call Leds.set(counter);
					sendToPC();
					call timer3.startOneShot(1000);	//Call to send ACK
				}
				return msg;
			}
			
			if(tcpmsg->type == 5)   //FIN received
			{
				finFlag = 1;
				call Leds.set(0);
				call Leds.led0On();
				call timer5.startOneShot(1000);  // Call to Send ACKF
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

