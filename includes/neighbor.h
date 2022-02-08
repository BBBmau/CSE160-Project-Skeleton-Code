#ifndef NEIGHBOR_H
#define NEIGHBOR_H

typedef nx_struct neighbor{
    nx_uint16_t home; // Node that we're focused on to find neighbors for
    // Just one variable for now to have NeighborDiscovery working
    nx_uint16_t dest;
    nx_uint16_t seq; // sequence number to identify unique neighbors
    nx_uint16_t TTL; // Time to Live for a Node
}neighbor;

#endif