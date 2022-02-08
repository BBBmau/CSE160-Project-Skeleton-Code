#include "../../includes/neighbor.h"

interface Neighbor_Discovery{
    command void run();
    command void printNeighbors();
    command void addNeighbor(neighbor newNeighbor);
}