#include "../../includes/am_types.h"
#include "../../includes/packet.h"

configuration FloodingC{
    provides interface Flooding;
}

implementation{
    components FloodingP;
    Flooding = FloodingP;

    components new SimpleSendC(AM_FLOODING) as Sender;
    FloodingP.Sender -> Sender;
    
    components new AMReceiverC(AM_FLOODING) as Receiver;
    FloodingP.Receiver -> Receiver;

    // components new ListC(pack, 20) as neighborList;
    // FloodingP.neighborList -> neighborList;

    components Neighbor_DiscoveryC;
    FloodingP.Neighbor_Discovery -> Neighbor_DiscoveryC;

}