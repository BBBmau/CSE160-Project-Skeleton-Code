#include "../../includes/neighbor.h"

interface Neighbor_Discovery{
    command void run();
    command void printNeighbors();
    // make functions to get neighborList
    command uint16_t NeighborhoodSize();

    command neighbor* NeighborhoodList();
}