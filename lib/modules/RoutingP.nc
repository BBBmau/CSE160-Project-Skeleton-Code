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

        // Distance-Vector
        // interface Hashmap<uint16_t> as DV;

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
    DV table[20];
    uint8_t *temp = &SEQ_NUM;
    uint32_t *NodeList;
    neighbor *Neighborhood;
    void storeNeighbors();
    void makePack(pack * Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t seq, uint16_t protocol, uint8_t * payload, uint8_t length);
    void DVR(DV * Route, uint16_t dest, uint16_t hop, uint8_t count);

    command void Routing.run(){
        call Discovery.run();
        call HomeTimer.startPeriodic(5000);
        revision++;

        dbg(ROUTING_CHANNEL, "STARTED FROM NODE %hhu\n", TOS_NODE_ID);
        DVR(table, 0, 0, 1);
        makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 1, SEQ_NUM , PROTOCOL_PING, table, PACKET_MAX_PAYLOAD_SIZE);
        call Sender.send(sendPackage, AM_BROADCAST_ADDR);
    }

    void storeNeighbors(){
        Neighborhood = call Discovery.NeighborhoodList();
        i = 0;
        N = call Discovery.NeighborhoodSize();
        for(i = 0; i < N; i++){
            //call DV.insert((Neighborhood + i)->dest, 1);
            table[i].dest = (Neighborhood + i)->dest;
            table[i].hop = (Neighborhood + i)->dest;
            table[i].count = 1;
        }

        dbg(ROUTING_CHANNEL, "DV Size is: %d\n", N);
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
        // N = call DV.size(); // Size of the Distant-Vector
        for(i = 0; i < N; i++){

            dbg(ROUTING_CHANNEL, "%d     %d    %d\n", table[i].dest, table[i].hop , table[i].count);
        }
    }

    event message_t *ReceiveRoute.receive(message_t * msg, void *payload, uint8_t len){
        pack* myMsg = (pack*) payload;

        if (revision == 0){ // First Revision will be to store the neighbors of TOS_NODE_ID
            call Discovery.run();
            call DestTimer.startPeriodic(5000);
        }else{
            // memcpy(myMsg->payload, )
        }

        // uint8_t PayloadLength;
        // PayloadLength = call ReceiveRoute.payloadLength(msg);

        // dbg(ROUTING_CHANNEL, "Payload Length: %d\n", PayloadLength);

        revision++;

        return msg;
    }


    void DVR(DV * Route, uint16_t dest, uint16_t hop, uint8_t count){
        Route->dest = dest;
        Route->hop = hop;
        Route->count = count;
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