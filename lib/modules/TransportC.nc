#include "../../includes/socket.h"

configuration TransportC{
    provides interface Transport;
}

implementation{
    components TransportP;
    Transport = TransportP;

    components new HashmapC(socket_store_t, 11) as socketList;
    TransportP.socketList -> socketList;

    components new HashmapC(socket_store_t, 11) as acceptedSockets;
    TransportP.acceptedSockets -> acceptedSockets;

    components new TimerMilliC() as serverTimer;
    TransportP.serverTimer -> serverTimer;

    components new TimerMilliC() as clientTimer;
    TransportP.clientTimer -> clientTimer;

    components RoutingC;
    TransportP.Routing -> RoutingC;
    
    components new AMReceiverC(AM_PACK) as GeneralReceive;
    TransportP.Receiver -> GeneralReceive;

}