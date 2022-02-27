#ifndef DV_H
#define DV_H

typedef nx_struct DV{
    nx_uint16_t dest;
    nx_uint16_t hop; // sequence number to identify unique neighbors
    nx_uint16_t count; // Time to Live for a Node
}DV;

#endif