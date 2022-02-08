#ifndef NEIGHBOR_H
#define NEIGHBOR_H

typedef nx_struct neighbor{
    nx_uint16_t home; // Node that we're focused on to find neighbors for
    // Just one variable for now to have NeighborDiscovery working
    nx_uint16_t dest;
}neighbor;

#endif