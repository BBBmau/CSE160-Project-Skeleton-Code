#include "../../includes/am_types.h"
#include "../../includes/dv.h"

configuration RoutingC{
    provides interface Routing;
}

implementation{
    components RoutingP;
    Routing = RoutingP;

    components new TimerMilliC() as HomeTimer;
    RoutingP.HomeTimer -> HomeTimer;

    components new TimerMilliC() as DestTimer;
    RoutingP.DestTimer -> DestTimer;

    components new SimpleSendC(AM_PACK);
    RoutingP.Sender -> SimpleSendC;

    components new AMReceiverC(AM_PACK) as GeneralReceive;
    RoutingP.ReceiveRoute -> GeneralReceive;

    components Neighbor_DiscoveryC as Discovery;
    RoutingP.Discovery -> Discovery;

    // components new HashmapC(uint16_t, 20) as DV;
    // RoutingP.DV -> DV;

    // // Used for Routing Table, where Keys are Destinations and 
    // // Hop Cost contains both the Hop and Cost in a data type (HopCost)
    // components new HashmapC(HopCost, 20) as Table;
    // RoutingP.Table -> Table;

}