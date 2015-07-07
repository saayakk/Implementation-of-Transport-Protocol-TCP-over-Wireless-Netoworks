/* Project: TCP Implementation on Wireless Sensor Nodes (WSN) 
 * @Authors: Subramanian Aayakkad
 * 			 Pratik Jain  
 * 			 Jigar Parekh	
 * 			 Nikhil More
 * 
 * Date: 	11th April 2015
 * 
 *  
 */

#include "TCP.h"
#include "TestSerial.h"
#include <Timer.h>

module TCPC
{
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
	
	int i = 0;
	int16_t input[sz]; 		//To receive data from PC	
	
	void sendSYNACK()
	{
		
		tcpMessage_t* tcpmsg = (tcpMessage_t*)(call Packet.getPayload(&packet,
									sizeof(tcpMessage_t)));
		tcpmsg->dip = 20;
		tcpmsg->sip = 10;		
		tcpmsg->type = 1;
		
		if(call radioAMSend.send(15, &packet, sizeof(tcpMessage_t))
						 == SUCCESS)
		{
			radioBusy = TRUE;
			call Leds.set(7);
		}
	}
	
	
	void sendACK()
	{
		tcpMessage_t* tcpmsg = (tcpMessage_t*)(call Packet.getPayload(&packet,
									sizeof(tcpMessage_t)));
		tcpmsg->dip = 20;
		tcpmsg->sip = 10;		
		tcpmsg->type = 7; 
		tcpmsg->seqNo = ackNo;
		
		if(call radioAMSend.send(15, &packet, sizeof(tcpMessage_t))
						 == SUCCESS)
		{
			radioBusy = TRUE;
		}
	}
	
	void sendACKF()
	{
		tcpMessage_t* tcpmsg = (tcpMessage_t*)(call Packet.getPayload(&packet,
									sizeof(tcpMessage_t)));
		tcpmsg->dip = 20;
		tcpmsg->sip = 10;		
		tcpmsg->type = 9;

		if(call radioAMSend.send(15, &packet, sizeof(tcpMessage_t))
						 == SUCCESS)
		{
			ackfFlag = 1;
			radioBusy = TRUE;
		}
	}
	
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
	
	event void timer0.fired()		//Sending SYNACK
	{
		call Leds.led0Off();
		sendSYNACK();
	}
	
	event void timer1.fired()		
	{
		
	}
	
	event void timer2.fired()		
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
	
	
	event void timeout.fired()		//Check Timeout for SYNACK 
	{
		if(acksFlag == 0)
		{
			sendSYNACK();
		}
	}
	
	event message_t * radioReceive.receive(message_t *msg, void *payload, uint8_t len)
	{
		tcpMessage_t* tcpmsg =(tcpMessage_t*)payload;
		

		if(tcpmsg->dip == 10)  // If I am the intended destination, run TCP
		{
		
			if(tcpmsg->type == 0)	//SYN received
			{
				synFlag = 1;
				call Leds.led2Off();
				call timer0.startOneShot(100);
				return msg;
			}
			
			if(tcpmsg->type == 2)	//ACKS received
			{
				acksFlag = 1;
				//call Leds.led1On();
				//call Leds.led0On();
				//call timer2.startOneShot(1000);
				return msg;
			}
			
			if(tcpmsg->type == 4)	//DATA received
			{
				dataFlag = 1;
				call Leds.led1Off();
				call Leds.led0Off();
				call Leds.led2Off();
				if(((call Random.rand16()) % 7) == 0)
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
				call timer5.startOneShot(1000);
				return msg;
			}
		}
		else		// If I am not the intended destination(I am a hop), forward to the destination(assumed that destination is the next hop)
		{
			if(call radioAMSend.send(tcpmsg->dip, msg, sizeof(tcpMessage_t))
						 == SUCCESS)
			{
				radioBusy = TRUE;
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

