
#include "../../includes/am_types.h"
//#include "../../includes/neighbor.h"


configuration Neighbor_DiscoveryC{
    provides interface Neighbor_Discovery;
}

implementation{
    components Neighbor_DiscoveryP;

    Neighbor_Discovery = Neighbor_DiscoveryP;

    components new TimerMilliC() as periodicTimer;
    Neighbor_DiscoveryP.periodicTimer -> periodicTimer;    
    
    components new SimpleSendC(AM_PACK);
    Neighbor_DiscoveryP.Send -> SimpleSendC;
    
    components new AMReceiverC(AM_PACK) as GeneralReceive;

    Neighbor_DiscoveryP.Receiver -> GeneralReceive;

    components RandomC as Random;
    Neighbor_DiscoveryP.Random -> Random;

}