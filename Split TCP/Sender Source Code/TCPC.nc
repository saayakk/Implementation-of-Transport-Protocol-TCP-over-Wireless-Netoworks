/*
 * Project: TCP Implementation over WSN
 * @Author: Subramanian Aayakkad
 * 			Pratik Jain
 * 			Jigar Parek
 * 			Nikhil More
 * 
 * File : Module File for TCP GO -Back-N (Complete Implementation code)
 * 
 * Date : 15th April 2015
 */

#include "TCP.h"
#include "TestSerial.h"

module TCPC{
	
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
		interface Timer<TMilli> as timerpc;
		interface Timer<TMilli> as timeout;
	}
	
	//Interfaces for Sending and receiving Packet over the radio
	uses
	{
		interface AMSend as radioAMSend;
		interface Receive as radioReceive;
		interface Packet;
		interface AMPacket;
		interface SplitControl as AMControlRadio;	// To start & stop components
		
	}
	
	//Interfaces for Sending and receiving Packet over the Serial
	uses 
	{
		interface Receive as serialReceive;
		interface SplitControl as AMControlSerial;
		interface AMSend as serialAMSend;	
	}
	
}

implementation
{	
	//Local variables to used
	message_t packet;
	bool radioBusy = FALSE;
	uint64_t counter = 1;
	uint16_t seqNo=0;
	uint16_t ackNo=0;
	uint16_t rackNo=0;
	uint16_t loopNo=0;
	uint16_t loopCount=1;
	uint16_t pctype=7;
	int delay=0;
	int i=0;
	int visit=0;
	int16_t input[sz];

	//To send data to PC over serial
	void sendToPC()
		{
			test_serial_msg_t* rcm = (test_serial_msg_t*)call Packet.getPayload(&packet, sizeof(test_serial_msg_t));
			rcm->counter=rackNo;
			rcm->type = pctype;
			if (call serialAMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(test_serial_msg_t)) == SUCCESS) 
			{
			 	
	      	}	
		}
	
	//To SYN Connection packet
	void sendSYN()
	{
		//Formation of packet headers and payload
		tcpMessage_t* tcpmsg = (tcpMessage_t*)(call Packet.getPayload(&packet, sizeof(tcpMessage_t)));
		
		tcpmsg->dip=10;
		tcpmsg->sip=20;
		tcpmsg->type=0;
		pctype=7;
		
		//Sending the packet
		if(call radioAMSend.send(10, &packet, sizeof(tcpMessage_t))==SUCCESS)
		{
			radioBusy=TRUE;		//To inform that radio is busy sending packet
		}

		call timerpc.startOneShot(200);
		
		//Checking timeout of SYNACK and retransmission if lost
		call timeout.startOneShot(5000);
	}
	
	//TO send acknowledgement for SYNACK received (called ACKS for convention)
	void sendACKS()
	{
		tcpMessage_t* tcpmsg = (tcpMessage_t*)(call Packet.getPayload(&packet, sizeof(tcpMessage_t)));
		
		tcpmsg->dip=10;
		tcpmsg->sip=20;
		tcpmsg->type=2;
		pctype=9;
		
		if(call radioAMSend.send(10, &packet, sizeof(tcpMessage_t))==SUCCESS)
		{
			radioBusy=TRUE;
		}
		
		call timerpc.startOneShot(200);
		
		// To start sending data on sending ACKS successfully
		call timer2.startOneShot(2000);
	}
	
	//Function to send data to the receiver
	void sendData()
	{	
		//To check if complete window is sent or check if packets in the window left to be sent
		if(loopNo<loopCount)
		{
			tcpMessage_t* tcpmsg = (tcpMessage_t*)(call Packet.getPayload(&packet, sizeof(tcpMessage_t)));
			
			// Assigning values to field of the packet
			tcpmsg->dip=10;
			tcpmsg->sip=20;
			tcpmsg->type=4;
			tcpmsg->data=input[seqNo];
			tcpmsg->seqNo=seqNo;
			
			ackFlag=0;		//Reset the ACK flag when sending the data inorder to check for next ACK
			
			seqNo += 1;
			loopNo += 1;
			
			call Leds.set(tcpmsg->data);
			
			if(call radioAMSend.send(10, &packet, sizeof(tcpMessage_t))==SUCCESS)
			{
				radioBusy=TRUE;
			}
		}
		
		else					//If complete window is sent
		{
			++visit;
			seqNo=win_start;	//Set the next seqNo to be sent as the start of Window
			
			if((win_start+win_size) > sz) 	//Change the window size if the last index exceeds max index
			{
				win_size = sz - win_start;
			}
			
			loopCount=win_size;
			loopNo=0;
			call Leds.set(win_size);
		}
		
		//Call to send data again in the window
		call timer2.startOneShot(2000);
		delay += 1500;
	}
	
	//Send FIn for connection termination
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
	
	//Event to Boot the system
	event void Boot.booted()
	{
		call AMControlSerial.start();
		call AMControlRadio.start();
		call Leds.led0On();
	}
	
	//Receive function to receive all packets
	event message_t * radioReceive.receive(message_t *msg, void *payload, uint8_t len)
	{
		tcpMessage_t* tcpmsg = (tcpMessage_t*)payload;
		
		if(tcpmsg->dip==20 && tcpmsg->sip==10)
		{			
			if(tcpmsg->type == 1) 		//SYNACK received
			{
				synackFlag=1;			//Set the synack flag
				call Leds.led0Off();
				pctype=8;
				sendToPC();
				
				//call to Send ACK when SYNACK is received
				call timer1.startOneShot(1000);
				
				delay += 1000;
				return msg;
			}
			
			//Check if received packet is ACK received
			if(tcpmsg->type == 7 )
			{
				call Leds.led0Off();
				call Leds.led1Off();
				call Leds.led2Off();
				
				ackFlag=1;
				pctype=1;
				rackNo=tcpmsg->ackNo;
				
				if(tcpmsg -> ackNo >lastACKed)		//Proper ACK received hence manipulate window
				{
					lastACKed=tcpmsg -> ackNo;		//Change the lastAcked as current ACK No
					win_start = lastACKed;			//Change the window start
					
					//Window manipulation according to Congestion control
					if(loopNo == loopCount)
					{							
						if(win_size*2 <= threshold)
						{
							win_size = win_size*2;		//Double the window size till threshold
						}
						else
						{
							win_size = win_size+1;		//Congestion Avoidance State
						}
					}
				}
				else			//Duplicate ACK indicating error
				{
					win_size=1;	 //By Congestion control, window size = 1
				}
				
				
				if(tcpmsg->ackNo < sz)
				{
					sendToPC();
					//call timer2.startOneShot(5000);
				}
				else
				{
					sendToPC();
					//Call to send FIN
					call timer0.startOneShot(2000);
				}
				return msg;
			}
			
			if(tcpmsg->type == 9)	//ACKF received
				{
					ackfFlag = 1;
					
					//When ACKF received terminate connection and stop the components
					call AMControlRadio.stop();
					return msg;
				}
			
			return msg;
		}
	}
	
	//Receive message over Serial
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
		
	//Timers to call various send functions
	
	event void timer0.fired()
	{
		//call Leds.led0Off();
		sendFIN();	
	}

	event void timer1.fired()
	{
		call Leds.led1Off();
		sendACKS();
	}

	event void timer2.fired()
	{
		call Leds.set(0);
		sendData();
	}
	
	event void timer3.fired()
	{

	}
	
	event void timer4.fired()
	{
		if (ackFlag==0)
		{
			sendData();
		}
	}
	
	event void timer5.fired()
	{

	}

	event void timerpc.fired()
	{
		sendToPC();	
	}
	
	event void timeout.fired()
	{
		if (synackFlag==0)
		{
			call Leds.led0Toggle();
			sendSYN();
		}
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
		if(error!=SUCCESS)
		{
			call AMControlRadio.start();	
		}
	}

	event void AMControlSerial.startDone(error_t error)
	{
		if(error!=SUCCESS)
		{
			call AMControlSerial.start();	
		}
	}
	
	event void AMControlRadio.stopDone(error_t error)
	{
		//Stop the components on connection termination
		call Leds.set(visit);
		
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
