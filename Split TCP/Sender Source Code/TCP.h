/*
 * Project: TCP Implementation over WSN
 * @Author: Subramanian Aayakkad
 * 			Pratik Jain
 * 			Jigar Parek
 * 			Nikhil More
 * 
 * File : Header File
 * 
 * Date : 15th April 2015
 */

#ifndef TCP_H
#define TCP_H
#define sz 100

enum	//Data types to define type of packet
{
	SYN=0,
	SYN_ACK=1,
	ACKS=2,
	DATA=4,
	FIN=5,
	AM_TCP=6,
	ACK=7,
	NAK=8,
	ACKF=9
};

	//Flags
	uint16_t synFlag=0;
	uint16_t synackFlag=0;
	uint16_t acksFlag=0;
	uint16_t ackFlag=0;
	uint16_t dataFlag=0;
	uint16_t ackfFlag=0;
	uint16_t finFlag=0;
	
	//Window manipulation variables
	uint16_t win_size=1;
	uint16_t threshold=8;
	uint16_t lastACKed=0;
	uint16_t win_start=0;
	uint16_t win_end=0;

//Packet format
typedef nx_struct TCPMessage
{
	nx_uint16_t type;
	nx_uint16_t sip;
	nx_uint16_t dip;
	nx_uint16_t seqNo;
	nx_uint16_t ackNo;
	nx_uint64_t data;
}tcpMessage_t;

#endif /* TCP_H */

