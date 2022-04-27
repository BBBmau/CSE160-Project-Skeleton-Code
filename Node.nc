/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include <Timer.h>
#include "includes/command.h"
#include "includes/socket.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"

module Node{
   uses interface Boot;

   uses interface SplitControl as AMControl;
   uses interface Receive;

   uses interface SimpleSend as Sender;

   // Project 1
   uses interface Flooding;
   uses interface Neighbor_Discovery;

   // Project 2
   uses interface Routing;

   // Project 3
   uses interface Transport;

   uses interface CommandHandler;
}

implementation{
   pack sendPackage;
   

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

   event void Boot.booted(){
      call AMControl.start();

      dbg(GENERAL_CHANNEL, "Booted\n");
   }

   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }

   event void AMControl.stopDone(error_t err){}

   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      dbg(GENERAL_CHANNEL, "Packet Received\n");
      if(len==sizeof(pack)){
         pack* myMsg=(pack*) payload;
         dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
         return msg;
      }
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      return msg;
   }


   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      dbg(GENERAL_CHANNEL, "PING EVENT \n");
      dbg(ROUTING_CHANNEL, "FORWARDING TO %d EVENT\n", destination);
      makePack(&sendPackage, TOS_NODE_ID, destination, 0, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
      call Routing.Forwarding(TOS_NODE_ID, destination, &sendPackage);
      //call Sender.send(sendPackage, destination);
      //call Flooding.send(sendPackage, destination);
   }

   event void CommandHandler.printNeighbors(uint16_t home){
      dbg(NEIGHBOR_CHANNEL, "NEIGHBOR EVENT\n");
      
      call Neighbor_Discovery.run();
      
      //call Neighbor_Discovery.printNeighbors();
   }

   event void CommandHandler.printRouteTable(){
      dbg(ROUTING_CHANNEL, "ROUTING EVENT\n");
      call Routing.run();
   }

   event void CommandHandler.printLinkState(){}

   event void CommandHandler.printDistanceVector(){}
   
   // Variables used
   
   
   event void CommandHandler.setTestServer(uint16_t address, uint16_t port){
      socket_t FD;
      socket_addr_t socketInfo;
      dbg(TRANSPORT_CHANNEL, "Setting Test Server\n");
      
      FD = call Transport.socket();
      if(FD == 0){
         dbg(TRANSPORT_CHANNEL, "Max Sockets Reached\n");
         return;
      }
      socketInfo.addr = address;
      socketInfo.port = port;
      
      dbg(TRANSPORT_CHANNEL, "File Descriptor of Socket for Server: %d\n", FD);
      
      if((call Transport.bind(FD, &socketInfo)) == FAIL){
         dbg(TRANSPORT_CHANNEL, "Failed to Bind File Descriptor\n");
         return;
      }
      dbg(TRANSPORT_CHANNEL, "**Successfully Binded File Descriptor**\n\n");
   
      call Transport.listen(FD);
   }

   event void CommandHandler.setTestClient(uint16_t dest, uint16_t srcPort, uint16_t destPort, uint16_t transfer){
      socket_t FD;
      socket_addr_t socketInfo;
      socket_addr_t serverAddress;
      
      dbg(TRANSPORT_CHANNEL, "Setting Test Client\n");
      
      FD = call Transport.socket();
      if(FD == 0){
         dbg(TRANSPORT_CHANNEL, "Max Sockets Reached\n");
         return;
      }

      dbg(TRANSPORT_CHANNEL, "CLIENT NODE: %d\n", TOS_NODE_ID);
      socketInfo.port = srcPort;  // Port on Client Side
      socketInfo.addr = TOS_NODE_ID;
      if((call Transport.bind(FD, &socketInfo)) == FAIL){
         dbg(TRANSPORT_CHANNEL, "Failed to Bind File Descriptor\n");
         return;
      }
      dbg(TRANSPORT_CHANNEL, "File Descriptor of Socket for Client: %d\n", FD);
      dbg(TRANSPORT_CHANNEL, "**Successfully Binded File Descriptor**\n\n");
      
      
      // Information to connect to server
      serverAddress.addr = dest;
      serverAddress.port = destPort;
      // We call connect method here to begin connection to server
      if((call Transport.connect(FD, &serverAddress)) == SUCCESS){
         dbg(TRANSPORT_CHANNEL, "Connected Successfully Attempted!\n");
      }
   
   }

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}

   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }
}
