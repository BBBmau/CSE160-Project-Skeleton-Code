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

    command void Neighbor_Discovery.start(uint16_t source){
      dbg(NEIGHBOR_CHANNEL, "Neighbors for Node %d\n", source);
   }


}