
#include "../../includes/am_types.h"

configuration Neighbor_DiscoveryC{
    provides interface Neighbor_Discovery;
}

implementation{
    components Neighbor_DiscoveryP;

    //Neighbor_Discovery = Neighbor_DiscoveryP;

    components new TimerMilliC() as periodicTimer;
    components new ListC(neighbor, 20);
    
    Neighbor_DiscoveryP -> ListC;
    Neighbor_DiscoveryP.periodicTimer -> periodicTimer;

    //Neighbor_DiscoveryP.run -> Neighbor_Discovery.run;
    
    
    components new SimpleSendC(AM_PACK);
    Neighbor_DiscoveryP.Sender -> SimpleSendC;

    
    components new AMReceiverC(AM_PACK) as GeneralReceive;

    Neighbor_DiscoveryP.Receiver -> GeneralReceive;

    // From MainC
    components new AMSenderC(channel);
    Neighbor_DiscoveryP.Packet -> AMSenderC;
    Neighbor_DiscoveryP.AMPacket -> AMSenderC;


}