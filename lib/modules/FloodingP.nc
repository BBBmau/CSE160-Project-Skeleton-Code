#include <Timer.h>
#include "../../includes/command.h"
#include "../../includes/packet.h"
#include "../../includes/CommandMsg.h"
#include "../../includes/sendInfo.h"
#include "../../includes/channels.h"
#include "../../includes/neighbor.h"


module FloodingP
{
	//Provides the SimpleSend interface in order to flood packets
	provides interface Flooding;
	//Uses the SimpleSend interface to forward recieved packet as broadcast
	uses interface SimpleSend as Sender;
	//Uses the Receive interface to determine if received packet is meant for me.
	uses interface Receive as Receiver;
	

	uses interface Neighbor_Discovery;
}

implementation
{
	pack sendPackage;
	uint16_t SEQ_NUM = 0;
	bool busy = FALSE;
	bool seenPacket = FALSE;
	
	// struct Link{
	// 	uint8_t src;
	// 	uint8_t dest;
	// }

	//Prototypes
	void makePack(pack* Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t seq, uint16_t protocol, uint8_t * payload, uint8_t length);
	// bool isInLinkList(pack packet);
	// void addToLinkList(pack packet);



	//Broadcast packet
	command error_t Flooding.send(pack msg, uint16_t dest){
		//We want Flooding to watch for 3 things:Src addr,increasing seqnum, and TTL field
		msg.src = TOS_NODE_ID;
		msg.dest = dest;
		msg.seq = SEQ_NUM++;
		msg.TTL = MAX_TTL;
		//Attempt to send the packet
		dbg(FLOODING_CHANNEL, "Sending from Flooding\n");

		if (call Sender.send(msg, AM_BROADCAST_ADDR) == SUCCESS)
		{
			return SUCCESS;
		}
		
		return FAIL;
	}

	//Event signaled when a node recieves a packet
	event message_t *Receiver.receive(message_t * msg, void *payload, uint8_t len){
		call Neighbor_Discovery.run();

		dbg(FLOODING_CHANNEL, "Packet Received in Flooding\n");
		if (len == sizeof(pack)){
			pack *contents = (pack *)payload;

			//If I am the original sender or have seen the packet before, drop it
			// We use the Link Layer to make sure that we only send ONE PACKET at each link!
			if ((contents->src == TOS_NODE_ID) || seenPacket){
				dbg(FLOODING_CHANNEL, "Dropping packet.\n");
				return msg;
			}

			//Kill the packet if TTL is 0
			if (contents->TTL <= 1){
           		//do nothing
            	dbg(FLOODING_CHANNEL, "TTL: %d\n", contents-> TTL);
           	 	return msg;
            }
			
			else{
				if (contents -> dest == TOS_NODE_ID){ // This is if we are in the desired node
					if(contents -> protocol == PROTOCOL_PING){
						uint16_t updateSrc = contents -> src;
						contents -> src = contents -> dest;
						contents -> dest = updateSrc;
						dbg(FLOODING_CHANNEL, "Reached Node %hhu from Source Node %hhu!", TOS_NODE_ID, contents->src);
						contents -> protocol = PROTOCOL_PINGREPLY;

						//call Sender.send(contents, contents->dest); // Sending the Reply back!
					}else{
						dbg(FLOODING_CHANNEL, "Packet has already reached Final Destination!\n");
						return msg;
					}
				}
				else{ 
					// Continue to Flood
					contents->TTL--;
					if(contents->TTL <= 1){
						
						return msg;
					}
						

					// We use Neighbor Discovery to Acquire List of Neighbors
					// neighborList = call Neighbor_Discovery.NeighborhoodList();
					
					// uint8_t i;
					// for(i = 0; i < call Neighbor_Discovery.NeighborhoodSize(); i++){
					// 	call Sender.send(msg, neighborList[i].dest);
					// }
				}
			}

			return msg;
		}

	}
}
