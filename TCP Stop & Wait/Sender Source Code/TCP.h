/*
 * Project: TCP implementation over WSN
 * @Authors: Subramanian Aayakkad
 * 			 Pratik Jain
 * 			 Jigar Parekh	
 * 			 Nikhil More
 * 
 * File: Header file for TCP Stop and Wait
 * 
 * Date: 30th March 2015
*/


#ifndef TCP_H
#define TCP_H
#define sz 100
enum					// Datatypes defining type of the packet
{
	SYN=0,
	SYN_ACK=1,
	ACKS=2,
	NAKS=3,
	DATA=4,
	FIN=5,
	AM_TCP=6,
	ACK=7,
	NAK=8
};


	 //Flags to be checked
	uint16_t synFlag=0;
	uint16_t synackFlag=0;
	uint16_t acksFlag=0;
	uint16_t ackFlag=0;
	uint16_t dataFlag=0;
	uint16_t ackfFlag=0;
	uint16_t finFlag=0;


typedef nx_struct TCPMessage		// Packet format
{
	nx_uint16_t type;
	nx_uint16_t sip;
	nx_uint16_t dip;
	nx_uint16_t seqNo;
	nx_uint64_t data;
}tcpMessage_t;

#endif /* TCP_H */

