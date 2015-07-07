#ifndef TEST_SERIAL_H
#define TEST_SERIAL_H

typedef nx_struct test_serial_msg
{
	nx_uint16_t counter;
	nx_uint16_t type;
}test_serial_msg_t;

enum
{
	SYN_S = 7,
	SYNACK_S = 8,
	ACKS_S = 9,
	DATA_S = 0,
	ACK_S = 1,
	AM_TEST_SERIAL_MSG = 0X89,
};

#endif /* TEST_SERIAL_H */

