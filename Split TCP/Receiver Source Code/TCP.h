/* Project: TCP Implementation on Wireless Sensor Nodes (WSN) 
 * @Authors: Subramanian Aayakkad
 * 			 Pratik Jain  
 * 			 Jigar Parekh	
 * 			 Nikhil More
 * 
 * Date: 	15th April 2015
 * 
 * Header Source File of the Project
 */

#ifndef TCP_H
#define TCP_H
#define sz 100

enum
{
	SYN = 0,
	SYN_ACK = 1,
	ACKS = 2,
	DATA = 4,
	FIN = 5,
	ACK = 7,
	NAK = 8,
	ACKF = 9, 
	AM_TCP = 6
};

	uint16_t synFlag = 0;
	uint16_t synackFlag = 0;
	uint16_t acksFlag = 0;
	uint16_t dataFlag = 0;
	uint16_t nackFlag = 0;
	uint16_t ackFlag = 0;
	uint16_t finFlag = 0;
	uint16_t ackfFlag = 0;
	uint16_t connectedFlag = 0;
	
	//Header data related to Window Size
	uint16_t win_size = 1;
	uint16_t lastACKed = 0;
	uint16_t threshold = 8;
	
	//manipulated in receive
	uint16_t win_start = 0;
	uint16_t win_end = 0;		
	

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
