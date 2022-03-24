interface Routing{
    command void run();
    command void Forwarding(uint16_t src, uint16_t dest, pack *message);
}