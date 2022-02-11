


module RoutingP{
    provides interface Routing
    uses{
        interface SimpleSend as SendForward;
        interface Receiver as ReceiveRoute;
        interface Receiver as ReceivePack;

        interface Timer<TMilli> as periodicTimer;
    }
}

implementation{
    pack sendPackage;
    uint16_t SEQ_NUM = 0;
    uint8_t *temp = &SEQ_NUM;

    void makePack(pack * Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t seq, uint16_t protocol, uint8_t * payload, uint8_t length);


    command void Routing.run(){
        
    }

}