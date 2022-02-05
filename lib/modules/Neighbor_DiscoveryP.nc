#include <Timer.h>
#include "../../includes/command.h"
#include "../../includes/packet.h"
#include "../../includes/CommandMsg.h"
#include "../../includes/sendInfo.h"
#include "../../includes/channels.h"

module Neighbor_DiscoveryP{
    provides interface Neighbor_Discovery;

    uses{
    //Uses SimpleSend interface to forward recieved packet as broadcast
        interface SimpleSend as Sender;
    //Uses the Receive interface to determine if received packet is meant for me.
	    interface Receive as Receiver;

        interface Packet;
        interface AMPacket;
	//Uses the Queue interface to determine if packet recieved has been seen before
	    interface List<neighbor> as Neighborhood;
        interface Timer<TMilli> as periodicTimer;
    }

}

implementation{

    pack sendPackage; 
    neighbor neighborHolder;
    uint16_t SEQ_NUM=200;
    uint8_t *temp = &SEQ_NUM;

    void makePack(pack * Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t seq, uint16_t protocol, uint8_t * payload, uint8_t length);

	bool isNeighbor(uint8_t nodeid);
    error_t addNeighbor(uint8_t nodeid);
    void updateNeighbors();
    void printNeighbors();

    uint8_t neighbors[19]; //Maximum of 20 neighbors?

    // command that gets called by the commandHandler
    command void Neighbor_Discovery.run(){
        makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 1, SEQ_NUM , PROTOCOL_PING, temp , PACKET_MAX_PAYLOAD_SIZE);
        SEQ_NUM++;
        call Sender.send(sendPackage, AM_BROADCAST_ADDR);
        
        call periodicTimer.startPeriodic(100000);
	}

    event void periodicTimer.fired(){
        dbg(NEIGHBOR_CHANNEL, "Sending from NeighborDiscovery\n");
        updateNeighbors();

        //optional - call a funsion to organize the list
        makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 1, SEQ_NUM , PROTOCOL_PING, temp , PACKET_MAX_PAYLOAD_SIZE);
		call Sender.send(sendPackage, AM_BROADCAST_ADDR);
    }


    event message_t *Receiver.receive(message_t * msg, void *payload, uint8_t len)
    {
        if (len == sizeof(pack)) //check if there's an actual packet
        {
            pack *contents = (pack*) payload;
           dbg(NEIGHBOR_CHANNEL, "NeighborReciver Called \n");

            if (PROTOCOL_PING == contents-> protocol) //got a message, not a reply aka acknowledgement
            { // since no reply we could try and send it again perhaps?

                if (contents->TTL == 1) // This means the packet will be discarded
                {
                    dbg(NEIGHBOR_CHANNEL, "Node Neighbors for %s\n", contents->dest);
                    //signal Neighbor_Discovery.Neighborhood();
                    return msg;
                }

                dbg(NEIGHBOR_CHANNEL, "No Acknowledgement received");
                return msg;
            }

            dbg(NEIGHBOR_CHANNEL, "Reply was Received");
            return msg;
        }
        dbg(NEIGHBOR_CHANNEL, "No Actual Packet");
        return msg;
    }    


    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL; // Time-To-Live, to limit lifespan of data so that it's removed after a certain period of time
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }

}