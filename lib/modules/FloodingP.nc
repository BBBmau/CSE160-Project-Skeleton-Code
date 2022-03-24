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
	
	uses interface Timer<TMilli> as Timer;

	uses interface Neighbor_Discovery;
}

implementation
{
	pack msgTravel;
	uint16_t finalDest;

	pack sendPackage;
	uint16_t SEQ_NUM = 0;
	bool busy = FALSE;
	bool seenPacket = FALSE;
	neighbor *neighborList;
	uint16_t i;
	uint16_t N;

	// struct Link{
	// 	uint8_t src;
	// 	uint8_t dest;
	// }

	//Prototypes
	void makePack(pack* Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t seq, uint16_t protocol, uint8_t * payload, uint8_t length);
	void FLOOD();
	// bool isInLinkList(pack packet);
	// void addToLinkList(pack packet);



	//Broadcast packet
	command error_t Flooding.send(pack msg, uint16_t dest){
		// We want to start NeighborDiscovery Right Away
		msgTravel = msg;
		finalDest = dest;

		call Neighbor_Discovery.run();
		call Timer.startOneShot(10000);
	}


	event void Timer.fired(){
		FLOOD();
	}

	void FLOOD(){
		//We want Flooding to watch for 3 things:Src addr,increasing seqnum, and TTL field
		msgTravel.src = TOS_NODE_ID;
		msgTravel.dest = finalDest;
		msgTravel.seq = SEQ_NUM++;
		msgTravel.TTL = MAX_TTL;
		//Attempt to send the packet
		dbg(FLOODING_CHANNEL, "Sending from Flooding\n");
		neighborList = call Neighbor_Discovery.NeighborhoodList();
		N = call Neighbor_Discovery.NeighborhoodSize();
		dbg(FLOODING_CHANNEL, "NeighborList Size: %d\n", N);

		for(i = 0; i < N; i++){
			call Sender.send(msgTravel, neighborList[i].dest);
		}
	}

	//Event signaled when a node recieves a packet
	event message_t *Receiver.receive(message_t * msg, void *payload, uint8_t len){
		pack* myMsg = (pack*) payload;

		if(myMsg->protocol == PROTOCOL_PINGREPLY){
			dbg(FLOODING_CHANNEL, "Packet Received in Flooding\n");
			if (len == sizeof(pack)){
			pack *contents = (pack *)payload;
			//dbg(FLOODING_CHANNEL, "Checking Packet\n");
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
						dbg(FLOODING_CHANNEL, "Reached Node %hhu from Source Node %hhu!\n", TOS_NODE_ID, contents->dest);
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
					// if(contents->TTL <= 1){
						
					// 	return msg;
					// }
					//dbg(FLOODING_CHANNEL, "seenPacket\n");
					seenPacket = TRUE;
					// We use Neighbor Discovery to Acquire List of Neighbors
					neighborList = call Neighbor_Discovery.NeighborhoodList();
					N = call Neighbor_Discovery.NeighborhoodSize();

					//dbg(FLOODING_CHANNEL, "NeighborList Size: %d\n", N);
					
						
						call Flooding.send(*contents, contents->dest);
				}
			}
			return msg;
			}
		}

	}
}
