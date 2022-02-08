#include <Timer.h>
#include "../../includes/command.h"
#include "../../includes/packet.h"
#include "../../includes/CommandMsg.h"
#include "../../includes/sendInfo.h"
#include "../../includes/channels.h"
#include "../../includes/neighbor.h"

module Neighbor_DiscoveryP{
    provides interface Neighbor_Discovery;

    uses{
    //Uses SimpleSend interface to forward recieved packet as broadcast
        interface SimpleSend as Send;
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
    void makeNeighbor(neighbor *Neighbor, uint16_t home, uint16_t dest);

    void printNeighbors();
    void addNeighbor(neighbor newNeighbor);
    bool isNeighbor(uint8_t nodeid);

    // command that gets called by the commandHandler
    command void Neighbor_Discovery.run(){
        makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 1, SEQ_NUM , PROTOCOL_PING, temp , PACKET_MAX_PAYLOAD_SIZE);
        SEQ_NUM++;
        dbg(NEIGHBOR_CHANNEL, "Finding Neighbors for Node: %hhu\n", TOS_NODE_ID);
        call Send.send(sendPackage, AM_BROADCAST_ADDR); // Sends Package to add nearby nodes
        
        
        //call periodicTimer.startPeriodic(100000);
        //call Neighbor_Discovery.printNeighbors();
	}

    event void periodicTimer.fired(){

        makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 1, SEQ_NUM , PROTOCOL_PING, temp , PACKET_MAX_PAYLOAD_SIZE);
		call Send.send(sendPackage, AM_BROADCAST_ADDR);
    }


    event message_t *Receiver.receive(message_t * msg, void *payload, uint8_t len)
    {
        dbg(NEIGHBOR_CHANNEL, "NeighborReciver Called \n");
        
        
        if (len == sizeof(pack)) //check if there's an actual packet
        {
            pack* contents = (pack*) payload;
            
            dbg(NEIGHBOR_CHANNEL, "Neighbor: %hhu \n", TOS_NODE_ID);
            makeNeighbor(&neighborHolder, contents->src, TOS_NODE_ID);
            call Neighbor_Discovery.addNeighbor(neighborHolder);
        }

        call Neighbor_Discovery.printNeighbors();
        //dbg(NEIGHBOR_CHANNEL, "Neighborhood size: %d\n", call Neighborhood.size());
        return msg;
    }    

    command void Neighbor_Discovery.addNeighbor(neighbor newNeighbor){
        
        //dbg(NEIGHBOR_CHANNEL, "Adding Neighbor\n");
        //call Neighborhood.pushback(newNeighbor);
        neighbor addedNeighbor = call Neighborhood.get(0);
        dbg(NEIGHBOR_CHANNEL, "Just added Node %hhu\n", addedNeighbor.home);
    }

    command void Neighbor_Discovery.printNeighbors(){
        uint16_t i;
        dbg(NEIGHBOR_CHANNEL, "Neighborhood size: %d\n", call Neighborhood.size());
        for(i = 0; i < call Neighborhood.size(); i++){
            neighbor current = call Neighborhood.get(i);
            dbg(NEIGHBOR_CHANNEL, "Neighbor %d: %hhu\n", i, current.dest );
        };
    }

    void makeNeighbor(neighbor* Neighbor, uint16_t home, uint16_t dest){
        Neighbor->home = home;
        Neighbor->dest = dest;
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