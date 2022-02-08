#include <Timer.h>
#include "../../includes/command.h"
#include "../../includes/packet.h"
#include "../../includes/CommandMsg.h"
#include "../../includes/sendInfo.h"
#include "../../includes/channels.h"
#include "../../includes/neighbor.h"
#define MAX_TTL 13

module Neighbor_DiscoveryP{
    provides interface Neighbor_Discovery;

    uses{
    //Uses SimpleSend interface to forward recieved packet as broadcast
        interface SimpleSend as Send;
    //Uses the Receive interface to determine if received packet is meant for me.
	    interface Receive as Receiver;

        interface Timer<TMilli> as periodicTimer;
    }

}

implementation{

    pack sendPackage; 
    uint16_t SEQ_NUM=200;
    uint8_t *temp = &SEQ_NUM;
    uint8_t neighborCount = 0;
    neighbor neighborHolder;
    neighbor Neighborhood[20]; // Max Neighbors Possible (?)

    // creating structs
    void makePack(pack * Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t seq, uint16_t protocol, uint8_t * payload, uint8_t length);
    void makeNeighbor(neighbor* Neighbor, uint16_t home, uint16_t dest, uint16_t seq, uint16_t TTL);

    void addNeighbor(neighbor newNeighbor);
    void printNeighbors();
    void updateNeighborhood();
    
    
    // command that gets called by the commandHandler
    command void Neighbor_Discovery.run(){
        dbg(NEIGHBOR_CHANNEL, "Finding Neighbors for Node: %hhu\n", TOS_NODE_ID);
        call periodicTimer.startPeriodic(10000); // We'll want to constantly be sending packets to neighbors
	}

    event void periodicTimer.fired(){
        makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 1, SEQ_NUM , PROTOCOL_PING, temp , PACKET_MAX_PAYLOAD_SIZE);
        call Send.send(sendPackage, sendPackage.dest); // Broadcasting to all nodes waiting to receive a message

        updateNeighborhood();
    }

    void updateNeighborhood(){
        uint16_t i;

        // Go through all neighbors and decrement the Time-To-Live
        for(i = 0; i < neighborCount; i++){
            if(Neighborhood[i].TTL > 1)
                Neighborhood[i].TTL--;
        }

        // Remove an Neighbors that have reached the end of life
        for(i = 0; i < neighborCount; i++){
            if(Neighborhood[i].TTL == 1){
                uint16_t j;
                for(j = i; j < neighborCount; j++){
                    Neighborhood[j] = Neighborhood[i + 1];
                }
                Neighborhood[neighborCount - 1] = Neighborhood[19];
                neighborCount--;
            }
        }

        
    }

    void addNeighbor(neighbor newNeighbor){
        // checking for duplicates by using sequence
        uint8_t i;
        for(i = 0; i < neighborCount; i++){
            if(Neighborhood[i].seq == newNeighbor.seq){ // Duplicate! We can restart the TTL!
                Neighborhood[i].TTL = MAX_TTL;
                return;
            }
        }

        // If not duplicate, add to the Neighborhood list
        Neighborhood[neighborCount] = newNeighbor;
        neighborCount++;

        dbg(NEIGHBOR_CHANNEL, "Neighborhood Size is Now %hhu\n", neighborCount);
        call Neighbor_Discovery.printNeighbors();
    }
    

    event message_t *Receiver.receive(message_t * msg, void *payload, uint8_t len){
        pack* myMsg = (pack*) payload;
        
        // Since we are only wanting to check for replies from neighbors
        // we check for the dest of the payload to be AM_BROADCAST_ADDR
        
        if (myMsg->dest == AM_BROADCAST_ADDR){ // we are broadcasting to all nearby nodes
                                               // we therefore want to instantly send a reply back!
            dbg(NEIGHBOR_CHANNEL, "NeighborReciever Called \n");
            myMsg->dest = myMsg->src;
            myMsg->src = TOS_NODE_ID;
            myMsg->protocol = PROTOCOL_PINGREPLY;

            call Send.send(*myMsg, myMsg->dest); // Sending a reply back!

        }else if(myMsg->dest == TOS_NODE_ID){ // This tells us that Home Node is going to the receiving node
            makeNeighbor(&neighborHolder, myMsg->src, myMsg->dest, SEQ_NUM, 13);
            addNeighbor(neighborHolder);            // which means it's a neighbor!
        }

        return msg;
    }    

    command void Neighbor_Discovery.printNeighbors(){
        uint16_t i;
        dbg(NEIGHBOR_CHANNEL, "Printing Neighbors for Node %hhu: \n", TOS_NODE_ID);
        for(i = 0; i < neighborCount; i++){
            dbg(NEIGHBOR_CHANNEL, "Node %hhu, with a TTL of %hhu\n", Neighborhood[i].home, Neighborhood[i].TTL);
        }
    }

    void makeNeighbor(neighbor* Neighbor, uint16_t home, uint16_t dest, uint16_t seq, uint16_t TTL){
        Neighbor->home = home;
        Neighbor->dest = dest;
        Neighbor->seq = seq;
        Neighbor->TTL = TTL;
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