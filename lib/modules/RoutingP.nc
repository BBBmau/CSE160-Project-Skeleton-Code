#include "../includes/neighbor.h"
#include "../includes/dv.h"

module RoutingP{
    provides interface Routing;
    uses{
        interface SimpleSend as Sender;
        interface Receive as ReceiveRoute;

        interface Timer<TMilli> as PrintTimer;

        interface Timer<TMilli> as advertiseTimer;

        interface Timer<TMilli> as NeighborTimer;

        interface Neighbor_Discovery as Discovery;

        // Distance-Vector containing Entry struct
        interface List<Route> as DV;

        // Routing Table (keys == Node #) and (Values == (Hop , Cost))
        //interface Hashmap<HopCost> as Table;

    }
}

implementation{
    pack sendRoutePackage;
    uint16_t revision = 0;
    uint16_t i = 0;
    uint16_t N;
    uint16_t DVsize;
    uint16_t SEQ_NUM = 0;
    bool neighborsRecorded = FALSE;


    Route neighborRoute;
    Route RouteSend;
    Route * incomingRoute;
    neighbor * neighborhood;

    // uint8_t *temp = &SEQ_NUM;

    void makePack(pack * Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint8_t * payload, uint8_t length);
    void makeRoute(Route * packet, uint16_t dest, uint16_t hop, uint8_t cost, uint16_t src);
    void mergeRoute(pack *incomingPacket, Route *newRoute);
    void printRoutingTable();
    void InitalizeRoutingTable();

    command void Routing.run(){
        call Discovery.run();
        neighborsRecorded = TRUE;
        call NeighborTimer.startOneShot(50000);
        call PrintTimer.startOneShot(1000000);
    }

    event void NeighborTimer.fired(){
        InitalizeRoutingTable();
    }

    event void PrintTimer.fired(){
        printRoutingTable();
    }

    void printRoutingTable(){

        uint16_t tableSize = call DV.size(); //pointerArrayCounter(neighbors);
        dbg(ROUTING_CHANNEL, "Routing Table\n");
        dbg(ROUTING_CHANNEL, "Dest  Hop  Cost\n");
        for (i = 0; i < tableSize; i++){
            Route checkRoute = call DV.get(i);
            dbg(ROUTING_CHANNEL, "%d     %d    %d\n", checkRoute.dest, checkRoute.hop, checkRoute.cost);
        }
    }

    void InitalizeRoutingTable(){
        neighborhood = call Discovery.NeighborhoodList();
        N = call Discovery.NeighborhoodSize(); //pointerArrayCounter(neighbors);
        
        //neighbor node = {TOS_NODE_ID, 0};
        makeRoute(&neighborRoute, 0, 0, 0, 0);
        //dbg(ROUTING_CHANNEL, "Starting Routing Table\n");
        for (i = 0; i < N; i++){
            //use a Temporary route to insert neighbor info into routing table
            neighborRoute.dest = (neighborhood + i)->dest;
            neighborRoute.hop = (neighborhood + i)->dest;
            neighborRoute.cost = 1; /* distance metric */ //temprarily for NumOfHops
            //dbg(ROUTING_CHANNEL, "%d %d %d\n", neighborRoute.dest, neighborRoute.hop, neighborRoute.cost);
            call DV.pushback(neighborRoute);
        }
        //dbg(ROUTING_CHANNEL, "Routing Table Size: %d\n", call DV.size());
        neighborsRecorded = TRUE;
        call advertiseTimer.startOneShot(1000); //30 Seconds
    }

    // Timer used to send out the different Node Packs to neighbors
    event void advertiseTimer.fired(){
        DVsize = call DV.size();
        //dbg(ROUTING_CHANNEL, "DV Size: %d\n", DVsize);
        //dbg(ROUTING_CHANNEL, "IN advertiseTimer\n");
        for(i = 0; i < DVsize; i++){
            RouteSend = call DV.get(i);
            //dbg(ROUTING_CHANNEL, "Route being sent has Dest: %d Hop: %d Cost: %d\n", RouteSend.dest, RouteSend.hop, RouteSend.cost);
            makePack(&sendRoutePackage, TOS_NODE_ID, RouteSend.dest, 1 , 5, (uint16_t*)&RouteSend , PACKET_MAX_PAYLOAD_SIZE);
            call Sender.send(sendRoutePackage, AM_BROADCAST_ADDR);
        }
    }


    void mergeRoute(pack *incomingPack, Route *newRoute){
        uint16_t NumRoutes = call DV.size();
        //dbg(ROUTING_CHANNEL, "newRoute; Dest: %d\n", newRoute->dest);
        for (i = 0; i < NumRoutes; i++){
            Route checkRoute = call DV.get(i);
            if(newRoute->dest == checkRoute.dest){
                if(newRoute->cost + 1 < checkRoute.cost){
                    // Better Route Found
                    // (call DV.get(i)).cost = newRoute->cost + 1;
                    // (call DV.get(i)).hop = incomingPack->src;
                    break;
                }
                else{
                    // Route adds no value to the list
                    return;
                }
            }
        }

        if(i == NumRoutes && newRoute->dest != TOS_NODE_ID){ // Completely New Route
            //dbg(ROUTING_CHANNEL, "NEW ROUTE ADDED. DEST: %d\n", newRoute->dest);
            newRoute->hop = incomingPack->src;
            newRoute->cost++;
            call DV.pushback(*newRoute);
            // (call DV.get(i)).cost++; causes an error

        }
    }

    event message_t *ReceiveRoute.receive(message_t * msg, void *payload, uint8_t len){
        if(neighborsRecorded == TRUE){
            // dbg(ROUTING_CHANNEL, "Neighbors have been recorded with a size of %d\n", DVsize);
        }
        if(neighborsRecorded == FALSE){
            call Discovery.run();
            neighborsRecorded = TRUE;
            //dbg(ROUTING_CHANNEL, "Discovering neighbors for %d\n", TOS_NODE_ID);
            call NeighborTimer.startOneShot(10000);
        }
        else{
            pack* incomingPacket = (pack*) payload;
            incomingRoute = incomingPacket->payload;

            // In order to insure we're working with packets that have to do
            // with Routing we check if the packet has PROTOCOL_ROUTE (5)
            if(incomingPacket->protocol == 5 && incomingRoute->dest < 100){
                //dbg(ROUTING_CHANNEL, "Packet Info Dest: %d Src: %d\n", incomingPacket->dest, incomingPacket->src);
                //dbg(ROUTING_CHANNEL, "Packet has %d %d %d\n", incomingRoute->dest, incomingRoute->hop, incomingRoute->cost);
                mergeRoute(incomingPacket, incomingRoute);
                call advertiseTimer.startOneShot(100000);
            }
        }

        return msg;
    }


    void makeRoute(Route * packet, uint16_t dest, uint16_t hop, uint8_t cost, uint16_t src){
        packet->dest = dest;
        packet->hop = hop;
        packet->cost = cost;
        packet->src = src;
    }

    // void makeEntry(DVnew * node, uint16_t dest, uint16_t hop, uint8_t cost){
    //     node->dest = dest;
    //     node->hop = hop;
    //     node->cost = cost;
    //     }

    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL; // Time-To-Live, to limit lifespan of data so that it's removed after a certain period of time
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }
}