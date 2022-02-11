

configuration{
    provides interface Routing;
}

implementation{
    components RoutingP;
    Routing = RoutingP;

    components new TimerMilliC() as periodicTimer;
    RoutingP.periodicTimer -> periodicTimer

    components new SimpleSendC(AM_FLOODING) as Sender;
    RoutingP.Send -> Sender;

    components new AMReceiverC(AM_FLOODING) as Receiver;
    RoutingP.Receiver -> GeneralReceive;
}