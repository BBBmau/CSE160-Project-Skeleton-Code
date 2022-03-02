#include "../includes/neighbor.h"
#include "../includes/dv.h"

module RoutingP{
    provides interface Routing;
    uses{
        interface SimpleSend as Sender;
        interface Receive as ReceiveRoute;

        interface Timer<TMilli> as HomeTimer;
        interface Timer<TMilli> as DestTimer;

        interface Neighbor_Discovery as Discovery;

        // Distance-Vector containing DVnodes struct
        interface Hashmap<DVnode> as DV;

        // Routing Table (keys == Node #) and (Values == (Hop , Cost))
        //interface Hashmap<HopCost> as Table;

    }
}

implementation{
    pack sendPackage;
    uint16_t SEQ_NUM = 0;
    uint16_t revision = 0;
    uint16_t i = 0;
    uint16_t N;

    uint32_t *DVkeys;
    DVnode DVpack;
    DVnode ROUTEpack;

    uint8_t *temp = &SEQ_NUM;

    neighbor *Neighborhood;
    void storeNeighbors();
    void makePack(pack * Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t seq, uint16_t protocol, uint8_t * payload, uint8_t length);
    void makeDVpack(DVnode * packet, uint16_t dest, uint16_t hop, uint8_t count);

    command void Routing.run(){
        call Discovery.run();
        call HomeTimer.startPeriodic(3000);
        revision++;
        
        dbg(ROUTING_CHANNEL, "Packet has %d %d %d\n", DVpack.dest, DVpack.hop, DVpack.count);

        dbg(ROUTING_CHANNEL, "STARTED FROM NODE %hhu\n", TOS_NODE_ID);
        makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 1, SEQ_NUM , PROTOCOL_DV,(uint8_t*) &DVpack, PACKET_MAX_PAYLOAD_SIZE);
        call Sender.send(sendPackage, AM_BROADCAST_ADDR);
    }

    // storing the neighbors of TOS_NODE_ID into Hashmap DV
    void storeNeighbors(){
        Neighborhood = call Discovery.NeighborhoodList();
        i = 0;
        N = call Discovery.NeighborhoodSize();
        for(i = 0; i < N; i++){
            makeDVpack(&DVpack, (Neighborhood + i)->dest, (Neighborhood + i)->dest, 1);
            dbg(ROUTING_CHANNEL, "KEY: %d\n", (Neighborhood + i)->dest);
            call DV.insert((Neighborhood + i)->dest, DVpack); // Key is the Dest with value being struct of dest, hop, and cost
        }

        //dbg(ROUTING_CHANNEL, "DV Size is: %d\n", N);
    }

    event void DestTimer.fired(){
        storeNeighbors();
    }

    event void HomeTimer.fired(){
        // Find the Neighbors and add into the Distant Vector, this should be happening periodic
        storeNeighbors();
        dbg(ROUTING_CHANNEL, "Routing Table:\n");
        dbg(ROUTING_CHANNEL, "Dest  Hop  Count\n");

        // NodeList = call DV.getKeys();
        N = call DV.size(); // Size of the Distant-Vector
        DVkeys = call DV.getKeys();
        for(i = 0; i < N; i++){
            ROUTEpack = call DV.get(DVkeys[i]);
            dbg(ROUTING_CHANNEL, "%d     %d    %d\n", ROUTEpack.dest, ROUTEpack.hop, ROUTEpack.count);
        }
    }


    event message_t *ReceiveRoute.receive(message_t * msg, void *payload, uint8_t len){
        DVnode* packet = (DVnode*) payload;

       dbg(ROUTING_CHANNEL, "Packet has %d %d %d\n", packet->dest, packet->hop, packet->count);


        if (revision == 0){ // First Revision will be to store the neighbors of TOS_NODE_ID
            call Discovery.run();
            call DestTimer.startPeriodic(5000);
        }else{
        }

        revision++;

        return msg;
    }


    void makeDVpack(DVnode * packet, uint16_t dest, uint16_t hop, uint8_t count){
        packet->dest = dest;
        packet->hop = hop;
        packet->count = count;
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