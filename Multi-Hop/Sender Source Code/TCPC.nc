
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
		interface Timer<TMilli> as timeout;
		interface Timer<TMilli> as timerpc;
	}
	
	//Interfaces for Sending Packet
	uses
	{
		interface AMSend as radioAMSend;
		interface AMSend as serialAMSend;
		interface Packet;
		interface AMPacket;
		interface SplitControl as AMControlRadio;	// To start & stop components
		interface SplitControl as AMControlSerial;
	}
	
	//Interface for receiving
	uses interface Receive as radioReceive;
	uses interface Receive as serialReceive;
	
}
implementation{
	
	message_t packet;
	bool radioBusy = FALSE;
	uint64_t counter = 1;
	uint16_t seqNo=0;
	uint16_t ackNo=0;
	uint16_t pctype=7;
	int i=0;
	uint16_t retransmit=0;
	int16_t input[sz];

	void sendToPC()
	{
		 test_serial_msg_t* rcm = (test_serial_msg_t*)call Packet.getPayload(&packet, sizeof(test_serial_msg_t));
		 rcm->counter=seqNo;
		 rcm->type=pctype;
		 if (call serialAMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(test_serial_msg_t)) == SUCCESS) {

     		 }	
	}

	void sendSYN()
	{
		tcpMessage_t* tcpmsg = (tcpMessage_t*)(call Packet.getPayload(&packet, sizeof(tcpMessage_t)));
		
		tcpmsg->dip=10;
		tcpmsg->sip=20;
		tcpmsg->type=0;
		pctype=7;
		if(call radioAMSend.send(15, &packet, sizeof(tcpMessage_t))==SUCCESS)
		{
			radioBusy=TRUE;
		}
		call timerpc.startOneShot(1000);
		call timeout.startOneShot(6000);
	}
	
	
	void sendACKS()
	{
		tcpMessage_t* tcpmsg = (tcpMessage_t*)(call Packet.getPayload(&packet, sizeof(tcpMessage_t)));
		
		tcpmsg->dip=10;
		tcpmsg->sip=20;
		tcpmsg->type=2;
		pctype=9;
		if(call radioAMSend.send(15, &packet, sizeof(tcpMessage_t))==SUCCESS)
		{
			radioBusy=TRUE;
		}
		call timerpc.startOneShot(1000);
		call timer2.startOneShot(2000);
		
	}
	
	void sendData()
	{
		tcpMessage_t* tcpmsg = (tcpMessage_t*)(call Packet.getPayload(&packet, sizeof(tcpMessage_t)));
		
		tcpmsg->dip=10;
		tcpmsg->sip=20;
		tcpmsg->type=4;
		tcpmsg->data=input[seqNo];
		tcpmsg->seqNo=seqNo;
		call Leds.set(input[seqNo]);
		ackFlag=0;
		if(call radioAMSend.send(15, &packet, sizeof(tcpMessage_t))==SUCCESS)
		{
			radioBusy=TRUE;
		}
		pctype=0;
		call timerpc.startOneShot(1000);
		call timer4.startOneShot(6000);
	}
	
	
	void sendFIN()
	{
		tcpMessage_t* tcpmsg = (tcpMessage_t*)(call Packet.getPayload(&packet,sizeof(tcpMessage_t)));
		tcpmsg->dip = 10;
		tcpmsg->sip = 20;		
		tcpmsg->type = 5; 
		
		if(call radioAMSend.send(15, &packet, sizeof(tcpMessage_t))== SUCCESS)
		{
			radioBusy = TRUE;
		}

	}
		
	
	event void Boot.booted(){
		call AMControlSerial.start();
		call AMControlRadio.start();
		call Leds.led0On();
		
	}
	
	event message_t * radioReceive.receive(message_t *msg, void *payload, uint8_t len)
	{
		tcpMessage_t* tcpmsg = (tcpMessage_t*)payload;
		
		if(tcpmsg->dip==20 && tcpmsg->sip==10)
		{
		
		if(tcpmsg->type == 1)				// SYNACK received
		{
			synackFlag=1;
			call Leds.led0Off();
			pctype=8;
			sendToPC();
			call timer1.startOneShot(1000);
			return msg;
		}		
			
		if(tcpmsg->type == 7 )			//ACK received
		{
			call Leds.led0Off();
			call Leds.led1Off();
			call Leds.led2Off();
			ackFlag=1;
			pctype=1;
			if(tcpmsg->seqNo==(seqNo+1))
			{
			seqNo+=1;
			counter+=1;
			}
			if(seqNo<=sz-1)
			{
				sendToPC();
				call timer2.startOneShot(1000);
			}
			else
			{
				sendToPC();
				call timer0.startOneShot(2000);
			}
			return msg;
		}
		
		if(tcpmsg->type == 9)	//ACKF received
			{
				ackfFlag = 1;
				call AMControlRadio.stop();
				return msg;
			}
		
		return msg;
		}
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
		

	event void timer0.fired(){
		sendFIN()	
	}

	event void timer1.fired(){
		call Leds.led1Off();
		sendACKS();
	}

	event void timer2.fired(){
		call Leds.led0Off();
		call Leds.led1Off();
		sendData();
	}
	
	event void timer3.fired(){
	}
	

	event void timer4.fired(){
		if (ackFlag==0)
		{
			++retransmit;
			sendData();
		}
	}
	event void timer5.fired(){
	}
	
	event void timeout.fired(){
		if (synackFlag==0)
		{
			call Leds.led0Toggle();
			sendSYN();
		}
	} 

	event void timerpc.fired(){
		sendToPC();	
	}
	event void radioAMSend.sendDone(message_t *msg, error_t error){
		if(msg == &packet)
		{
			radioBusy = FALSE;
		}
	}
	
	event void serialAMSend.sendDone(message_t *msg, error_t error){
		if(msg == &packet)
		{
			radioBusy = FALSE;
		}
	}

	event void AMControlRadio.startDone(error_t error){
		if(error!=SUCCESS)
		{
			call AMControlRadio.start();	
		}
	}

	event void AMControlSerial.startDone(error_t error){
		if(error!=SUCCESS)
		{
			call AMControlSerial.start();	
		}
	}
	
	event void AMControlRadio.stopDone(error_t error){
		call Leds.set(retransmit);
		if(error!=SUCCESS && ackfFlag==0)
		{
				call AMControlRadio.start();
		}
	}

	

	

	

	

	

	event void AMControlSerial.stopDone(error_t error){
		// TODO Auto-generated method stub
	}
}
