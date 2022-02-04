

configuration Neighbor_DiscoveryC{
    provides interface Neighbor_Discovery;
}

implementation{
    components Neighbor_DiscoveryP;

    Neighbor_Discovery = Neighbor_DiscoveryP;

    

}