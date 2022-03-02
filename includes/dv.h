#ifndef DV_H
#define DV_H

typedef nx_struct DVnode{
    nx_uint16_t dest;
    nx_uint16_t hop; // sequence number to identify unique neighbors
    nx_uint16_t count; // Time to Live for a Node
}DVnode;

typedef nx_struct DVnew{
    nx_uint16_t dest;
    nx_uint16_t hop; // sequence number to identify unique neighbors
    nx_uint16_t count;
}

#endif