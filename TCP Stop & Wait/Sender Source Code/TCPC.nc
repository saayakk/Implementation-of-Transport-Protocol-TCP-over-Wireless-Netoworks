/*
 * Project: TCP implementation over WSN
 * @Authors: Subramanian Aayakkad
 * 			 Pratik Jain
 * 			 Jigar Parekh	
 * 			 Nikhil More
 * 
 * File: Module file for TCP Stop and Wait (Complete implementation of Stop and Wait)
 * 
 * Date: 30th March 2015
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
		interface Random;
		interface Timer<TMilli> as timer0;
		interface Timer<TMilli> as timer1;
		interface Timer<TMilli> as timer2;
		interface Timer<TMilli> as timer3;
		interface Timer<TMilli> as timer4;
		interface Timer<TMilli> as timer5;
		interface Timer<TMilli> as timeout;
		interface Timer<TMilli> as timerpc;
	}
	
	//Interfaces for Sending and Receiving Packet over the Radio
	uses
	{
		interface AMSend as radioAMSend;
		interface SplitControl as AMControlRadio;
		interface Packet;
		interface AMPacket;
		interface Receive as serialReceive;
	}
	
	//Interfaces for Sending and Receiving packets over Serial
	uses
	{		
		interface AMSend as serialAMSend;
		interface SplitControl as AMControlSerial;
		interface Receive as radioReceive;
	}	
}

implementation
{
// local variables to be used
	message_t packet;
	bool radioBusy = FALSE;
	uint64_t counter = 1;
	uint16_t seqNo=0;
	uint16_t ackNo=0;
	uint16_t pctype=7;
	int i=0;
	uint16_t retransmit=0;
	int16_t input[sz];


// To send data to PC over serial 
	void sendToPC()
	{
		 test_serial_msg_t* rcm = (test_serial_msg_t*)call Packet.getPayload(&packet, sizeof(test_serial_msg_t));
		 rcm->counter = seqNo;
		 rcm->type = pctype;
		 if (call serialAMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(test_serial_msg_t)) == SUCCESS)
		 {

   		 }	
	}

// To send SYN connection packet
	void sendSYN()
	{
		// Formation of packet headers and payload
		tcpMessage_t* tcpmsg = (tcpMessage_t*)(call Packet.getPayload(&packet, sizeof(tcpMessage_t)));
		
		tcpmsg->dip = 10;
		tcpmsg->sip = 20;
		tcpmsg->type = 0;
		pctype = 7;
		
		// Sending the packet 
		if(call radioAMSend.send(10, &packet, sizeof(tcpMessage_t))==SUCCESS)
		{
			radioBusy = TRUE;		// To inform that the radio is busy sending packet
		}
		
		call timerpc.startOneShot(1000);
		
		//Checking timeout of SYNACK & retransmissioon if lost
		call timeout.startOneShot(6000);
	}
	
	// To send acknowledgement for SYNACK received (called ACKS for convention)
	void sendACKS()
	{
		tcpMessage_t* tcpmsg = (tcpMessage_t*)(call Packet.getPayload(&packet, sizeof(tcpMessage_t)));
		
		tcpmsg->dip = 10;
		tcpmsg->sip = 20;
		tcpmsg->type = 2;
		pctype=9;
		
		if(call radioAMSend.send(10, &packet, sizeof(tcpMessage_t))==SUCCESS)
		{
			radioBusy=TRUE;
		}
		
		call timerpc.startOneShot(1000);
		
		// To start sending data on sending ACKS successfully
		call timer2.startOneShot(2000);
		
	}
	
	// Function to send data to the receiver
	void sendData()
	{
		tcpMessage_t* tcpmsg = (tcpMessage_t*)(call Packet.getPayload(&packet, sizeof(tcpMessage_t)));
		
		//Assigning values to various fields of the packet 
		tcpmsg->dip=10;
		tcpmsg->sip=20;
		tcpmsg->type=4;
		
		tcpmsg->data=input[seqNo]; 
		tcpmsg->seqNo=seqNo;
		
		call Leds.set(input[seqNo]);
		
		ackFlag=0; // Reset the ACK flag for Sending the data in order to check for next ACK
		
		if(call radioAMSend.send(10, &packet, sizeof(tcpMessage_t))==SUCCESS)
		{
			radioBusy=TRUE;
		}
		
		pctype=0;
		
		call timerpc.startOneShot(1000);
		
		// To resend the data if ACK for the current packet is not received
		call timer4.startOneShot(6000);
	}
	
	// To send the FIN packet for connection termination
	void sendFIN()
	{
		tcpMessage_t* tcpmsg = (tcpMessage_t*)(call Packet.getPayload(&packet,sizeof(tcpMessage_t)));
		tcpmsg->dip = 10;
		tcpmsg->sip = 20;		
		tcpmsg->type = 5; 
		
		if(call radioAMSend.send(10, &packet, sizeof(tcpMessage_t))== SUCCESS)
		{
			radioBusy = TRUE;
		}
	}
	
	// Event to boot the system
	event void Boot.booted()
	{
		call AMControlSerial.start();
		call AMControlRadio.start();
		call Leds.led0On();
	}
	
	// Receive function to receive all type of packets
	event message_t * radioReceive.receive(message_t *msg, void *payload, uint8_t len)
	{
		tcpMessage_t* tcpmsg = (tcpMessage_t*)payload;
		
		if(tcpmsg->dip==20 && tcpmsg->sip==10)
		{
			
			if(tcpmsg->type == 1)			// SYNACK received
			{
				synackFlag = 1;			// Set the SYNACK flag
				call Leds.led0Off();
				pctype = 8;
				sendToPC();
				call timer1.startOneShot(1000);	    // Call to send ACKS when SYNACK received
				return msg;
			}
				
			if(tcpmsg->type == 7 )			// ACK received
			{
				call Leds.led0Off();
				call Leds.led1Off();
				call Leds.led2Off();
				ackFlag = 1;			// Set the ACK flag
				pctype = 1;
				if(tcpmsg->seqNo == (seqNo+1))  // If ACK is sequentially received
				{
					seqNo += 1;
				}
				if(seqNo <= sz-1)		// Keep sending data until size is not breached   
				{
					sendToPC();
					call timer2.startOneShot(1000);
				}
				else					// Call FIN after last Data packets' ACK is received
				{
					sendToPC();
					call timer0.startOneShot(2000);
				}
				return msg;
			}
			
			if(tcpmsg->type == 9)	//ACKF received
				{
					ackfFlag = 1;
					call AMControlRadio.stop();  // When ACKF received, stop the components
					return msg;
				}	
		return msg;
		}
	return msg;
	}

	event message_t * serialReceive.receive(message_t *msg, void *payload, uint8_t len) //Receive from PC
	{
		test_serial_msg_t* received = (test_serial_msg_t*)payload;
		input[i] = received->counter;
		call Leds.set(input[i]);
		i+=1;
		
		if(i==(sz))		
		{
			call Leds.set(0);
			sendSYN();
		}
		return msg;
	} 
		
	// Timers to call send functions
	event void timer0.fired()
	{
		sendFIN();
	}

	event void timer1.fired()
	{
		call Leds.led1Off();
		sendACKS();
	}

	event void timer2.fired()
	{
		call Leds.led0Off();
		call Leds.led1Off();
		sendData();
	}
	
	event void timer3.fired()
	{
		
	}
	
	event void timer4.fired()
	{
		if (ackFlag == 0)
		{
			++retransmit;
			sendData();
		}
	}

	event void timer5.fired()
	{
		
	}
	
	event void timeout.fired()
	{
		if (synackFlag == 0)
		{
			call Leds.led0Toggle();
			sendSYN();
		}
	} 

	event void timerpc.fired()
	{
		sendToPC();	
	}

	event void radioAMSend.sendDone(message_t *msg, error_t error)
	{
		if(msg == &packet)
		{
			radioBusy = FALSE;
		}
	}
	
	event void serialAMSend.sendDone(message_t *msg, error_t error)
	{
		if(msg == &packet)
		{
			radioBusy = FALSE;
		}
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
	
	// Stop the components on connection termination
	event void AMControlRadio.stopDone(error_t error)
	{
		call Leds.set(retransmit);
		if(error != SUCCESS && ackfFlag == 0)
		{
			call AMControlRadio.start();
		}
	}

	event void AMControlSerial.stopDone(error_t error)
	{
		// TODO Auto-generated method stub
	}
}
