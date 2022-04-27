#include "../../includes/socket.h"
#include "../../includes/packet.h"

module TransportP{
    provides interface Transport;
    uses interface Hashmap<socket_store_t> as socketList;
    uses interface Timer<TMilli> as serverTimer;
    uses interface Timer<TMilli> as clientTimer;
    uses interface Hashmap<socket_store_t> as acceptedSockets;
    uses interface Receive as Receiver;
    uses interface Routing;
}

implementation{
    // Used for empty TCP packets
    uint16_t SEQ_NUM=0;
    uint8_t *temp = &SEQ_NUM;

    socket_store_t socketListener;
    socket_t newFD;
    socket_store_t newStore;
    uint16_t* payloadData;
    pack* packet;
    TCPpack* TCPpacket;
    void makeTCPpack(TCPpack *Package, uint8_t srcPort, uint8_t destPort, uint8_t ACKNUM, uint8_t flag,uint8_t advertisedWindow, uint8_t* payload, uint8_t length);
    void makePack(pack *Package, uint8_t src, uint8_t dest, uint8_t TTL, uint8_t protocol, uint8_t seq, uint8_t* payload, uint8_t length);

    event void clientTimer.fired(){

    }

    command error_t Transport.connectDone(socket_t fd){
        dbg(TRANSPORT_CHANNEL, "Connection Established for Socket %d\n", fd);
        call acceptedSockets.insert(fd, newStore);
        // Sends back an ACK to server
        TCPpacket->ACKNUM = packet->seq++;
        packet->seq++;
        TCPpacket->flag = 4;
        packet->protocol = 6;
        dbg(TRANSPORT_CHANNEL, "SENDING ACK TO SERVER\n");
        packet->dest = packet->src;
        packet->src = TOS_NODE_ID;

        dbg(TRANSPORT_CHANNEL, "SENDING FROM %d TO %d\n", packet->src, packet->dest);
        call Routing.Forwarding(packet->src, packet->dest, packet);        
        return SUCCESS;
    }

 /**
    * Get a socket if there is one available.
    * @Side Client/Server
    * @return
    *    socket_t - return a socket file descriptor which is a number
    *    associated with a socket. If you are unable to allocated
    *    a socket then return a NULL socket_t.
    */
    command socket_t Transport.socket(){    // COMPLETED
        int i;
        
        for(i = 1; i <=  10; i++){ // Max is 10 - Global Socket_FD will always be 1
            if (!(call socketList.contains(i))){   // goes through Hashmap
                return (socket_t)i;
            }
        }

        return 0; // returns NULL if no space is found for socket
    }

    
   /**
    * Bind a socket with an address.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       you are binding.
    * @param
    *    socket_addr_t *addr: the source port and source address that
    *       you are biding to the socket, fd.
    * @Side Client/Server
    * @return error_t - SUCCESS if you were able to bind this socket, FAIL
    *       if you were unable to bind.
    */
   command error_t Transport.bind(socket_t fd, socket_addr_t *addr){ // COMPLETE
        socket_store_t newSocketStore;
        dbg(TRANSPORT_CHANNEL, "SRC ADDR: %d SRC PORT: %d\n",addr->addr, addr->port);
        if(call socketList.contains(fd)){
           dbg(TRANSPORT_CHANNEL, "Socket exists already\n");\
           return FAIL;
        }
        else if((call socketList.size()) > MAX_NUM_OF_SOCKETS){
           dbg(TRANSPORT_CHANNEL, "Max Sockets Reached\n");
           return FAIL;
        }

        
        newSocketStore.state = CLOSED; // Doesn't listen when binded
        if(fd != 1){
            newSocketStore.state = ESTABLISHED;
        }
        newSocketStore.srcPort = addr->port;
        newSocketStore.dest = *addr;
        call socketList.insert(fd, newSocketStore);


        return SUCCESS;
   }

   /**
    * Checks to see if there are socket connections to connect to and
    * if there is one, connect to it.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that is attempting an accept. remember, only do on listen. 
    * @side Server
    * @return socket_t - returns a new socket if the connection is
    *    accepted. this socket is a copy of the server socket but with
    *    a destination associated with the destination address and port.
    *    if not return a null socket.
    */
    command socket_t Transport.accept(socket_t fd){  // Called when server receives a SYN/ACK from a client
        socket_addr_t newAddr;
        newStore = socketListener;
        newAddr.port = TCPpacket->srcPort;
        newAddr.addr = packet->src;
        
        if((call Transport.bind(fd, &newAddr)) == SUCCESS){

            dbg(TRANSPORT_CHANNEL, "Socket %d has been Established!\n", fd);
            return fd;
        }
        
        // CONNECTION IS NOW ESTABLISHED BETWEEN SERVER AND CLIENT

        // Thoughts: Global Socket is ONLY listening. when a connection request
        // is made, it will return the socket information back into the receive method
       return 0;
    }

   /**
    * Write to the socket from a buffer. This data will eventually be
    * transmitted through your TCP implimentation.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that is attempting a write.
    * @param
    *    uint8_t *buff: the buffer data that you are going to wrte from.
    * @param
    *    uint16_t bufflen: The amount of data that you are trying to
    *       submit.
    * @Side For your project, only client side. This could be both though.
    * @return uint16_t - return the amount of data you are able to write
    *    from the pass buffer. This may be shorter then bufflen
    */
   command uint16_t Transport.write(socket_t fd, uint8_t *buff, uint16_t bufflen){}

   /**
    * This will pass the packet so you can handle it internally. 
    * @param
    *    pack *package: the TCP packet that you are handling.
    * @Side Client/Server 
    * @return uint16_t - return SUCCESS if you are able to handle this
    *    packet or FAIL if there are errors.
    */
   command error_t Transport.receive(pack* package){}

   /**
    * Read from the socket and write this data to the buffer. This data
    * is obtained from your TCP implimentation.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that is attempting a read.
    * @param
    *    uint8_t *buff: the buffer that is being written.
    * @param
    *    uint16_t bufflen: the amount of data that can be written to the
    *       buffer.
    * @Side For your project, only server side. This could be both though.
    * @return uint16_t - return the amount of data you are able to read
    *    from the pass buffer. This may be shorter then bufflen
    */
   command uint16_t Transport.read(socket_t fd, uint8_t *buff, uint16_t bufflen){}

   /**
    * Attempts a connection to an address.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that you are attempting a connection with. 
    * @param
    *    socket_addr_t *addr: the destination address and port where
    *       you will atempt a connection.
    * @side Client
    * @return socket_t - returns SUCCESS if you are able to attempt
    *    a connection with the fd passed, else return FAIL.
    */
   command error_t Transport.connect(socket_t fd, socket_addr_t *addr){    // SENDS SYN TO SERVER
        pack clientPack;
        TCPpack clientTCPpack;
        if(call socketList.contains(fd)){
            socket_store_t clientStore = call socketList.get(fd);
            newFD = fd;

            makeTCPpack(&clientTCPpack, clientStore.srcPort, addr->port, 1, 2, 2,temp, 6);
            //makeTCPpack(TCPpack *Package, uint16_t srcPort, uint16_t destPort, uint16_t ACKNUM, uint16_t flag,uint16_t advertisedWindow, uint8_t* payload)
            makePack(&clientPack, TOS_NODE_ID, addr->addr, 13, 6, 1, &clientTCPpack, PACKET_MAX_PAYLOAD_SIZE);
            // makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length, uint16_t srcPort, uint16_t destPort, uint16_t ACKNUM, uint16_t flag,uint16_t advertisedWindow){
            dbg(TRANSPORT_CHANNEL, "ATTEMPTING CONNECTION\n");  // error when attempting to create packet
            dbg(TRANSPORT_CHANNEL, "SENDING SYN TO SERVER\n");
            dbg(TRANSPORT_CHANNEL, "CONNECTION BETWEEN NODE %d PORT %d and NODE %d AND PORT %d\n", TOS_NODE_ID, clientStore.srcPort, addr->addr, addr->port);
            call Routing.Forwarding(TOS_NODE_ID, addr->addr, &clientPack);
            
            return SUCCESS; // was able to successfully ATTEMPT a connection
        }


        return FAIL;
   }

   /**
    * Closes the socket.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that you are closing. 
    * @side Client/Server
    * @return socket_t - returns SUCCESS if you are able to attempt
    *    a closure with the fd passed, else return FAIL.
    */
   command error_t Transport.close(socket_t fd){}

   /**
    * A hard close, which is not graceful. This portion is optional.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that you are hard closing. 
    * @side Client/Server
    * @return socket_t - returns SUCCESS if you are able to attempt
    *    a closure with the fd passed, else return FAIL.
    */
   command error_t Transport.release(socket_t fd){}

   /**
    * Listen to the socket and wait for a connection.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that you are hard closing. 
    * @side Server
    * @return error_t - returns SUCCESS if you are able change the state 
    *   to listen else FAIL.
    */
   command error_t Transport.listen(socket_t fd){   // global socket STAYS listening    - directs to available

       if(call socketList.contains(fd)){
           socketListener = call socketList.get(fd);
           socketListener.state = LISTEN;
           newFD = call Transport.socket(); // the new socket will be created for clients that want to connect
           dbg(TRANSPORT_CHANNEL, "New Server Socket FD: %d\n", newFD);
           call serverTimer.startPeriodic(1000);
           return SUCCESS;
       }

       return FAIL;
   }

    event void serverTimer.fired(){
        int i;
        for(i = 2; i <= call socketList.size(); i++){    // loops through 2-10 , we don't check 1 since that's server Socket
            // Read data and print
        }
    }

    event message_t *Receiver.receive(message_t * msg, void *payload, uint8_t len){
        packet = (pack*) payload;        
        TCPpacket = (TCPpack*) (packet->payload);
        // 6 -> coming from Client
        // 7 -> coming from Server

        
        if((TCPpacket->destPort != 0) && (TCPpacket->destPort == (call socketList.get(1)).srcPort)){
            dbg(TRANSPORT_CHANNEL, "\nCHECKING TRANSPORT RECEIVE\n");
            dbg(TRANSPORT_CHANNEL, "PROTOCOL IS: %d FLAG IS: %d\n", packet->protocol, TCPpacket->flag);
            if(packet->protocol == 6 || packet->protocol == 7){
                

                if(TCPpacket->flag == 0){ // Regular Data Transfering
                    if(packet->protocol == 6){

                    }
                    else{

                    }
                } 
                else if(TCPpacket->flag == 2){ // SYN for initiating connection
                    if(packet->protocol == 6){  // IN SERVER - RECEIVING AND SENDING A SYN
                        // check that destination addr/port match global FD and that state is LISTEN
                        // addr and port num in packet                        
                        dbg(TRANSPORT_CHANNEL, "SERVER RECEIVED SYN\n");
                        if((socketListener.state == LISTEN) & (TCPpacket->destPort== socketListener.srcPort)){
                            newStore.state = SYN_RCVD;
                            TCPpacket->ACKNUM = packet->seq++;
                            //acceptedPacket->seq = 1;
                            TCPpacket->flag = 2;
                            packet->protocol = 7;
                            //packet->payload = (uint8_t*)&TCPpacket;
                            dbg(TRANSPORT_CHANNEL, "SENDING SYN REPLY TO CLIENT\n");
                            packet->dest = packet->src;
                            packet->src = TOS_NODE_ID;

                            dbg(TRANSPORT_CHANNEL, "SENDING FROM %d TO %d\n", packet->src, packet->dest);
                            call Routing.Forwarding(packet->src, packet->dest, packet);
                            return msg;
                        }

                    }
                    else{   // IN CLIENT - RECEIVING A SYN
                        // Connection is Established
                        newStore = call socketList.get(newFD);
                        newStore.state = ESTABLISHED;
                        call acceptedSockets.insert(newFD, newStore);
                        if(newStore.state == ESTABLISHED){
                            call Transport.connectDone(newFD);
                        }
                        return msg;
                    }
                }
               else if(TCPpacket->flag == 4){ // ACK for confirmating packets and initiation requests
                    if(packet->protocol == 6){  // IN SERVER
                        if((socketListener.state == LISTEN) & (TCPpacket->destPort == socketListener.srcPort)){
                            call Transport.accept(newFD);
                        }
                    }
                    else{   // IN CLIENT
                        dbg(TRANSPORT_CHANNEL, "RECEIVED ACK FROM SERVER\n");
                        return msg;
                    }
                }
                else if(TCPpacket->flag == 6){ // Connection is being torn down
                    if(packet->protocol == 6){

                    }
                    else{

                    }
                }

            }
        }


        return msg;
    }

   void makePack(pack *Package, uint8_t src, uint8_t dest, uint8_t TTL, uint8_t protocol, uint8_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }


    void makeTCPpack(TCPpack *Package, uint8_t srcPort, uint8_t destPort, uint8_t ACKNUM, uint8_t flag,uint8_t advertisedWindow, uint8_t* payload, uint8_t length){
        // TCP Header Data
        Package->srcPort = srcPort;
        Package->destPort = destPort;
        Package->ACKNUM = ACKNUM;
        Package->flag = flag;
        Package->advertisedWindow = advertisedWindow;
        memcpy(Package->payload, payload, length);

    }
}