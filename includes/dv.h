#ifndef DV_H
#define DV_H

typedef struct Route{
    uint16_t dest;
    uint16_t hop;
    uint16_t cost;
    uint16_t src;
}Route;

// typedef struct Entry{
//     uint16_t dest;
//     uint16_t hop;
//     uint16_t cost;
// }DVnew;

#endif