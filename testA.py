from TestSim import TestSim

def main():
    # Get simulation ready to run.
    s = TestSim();

    # Before we do anything, lets simulate the network off.
    s.runTime(1);

    # Load the the layout of the network.
    s.loadTopo("example.topo");

    # Add a noise model to all of the motes.
    s.loadNoise("no_noise.txt");

    # Turn on all of the sensors.
    s.bootAll();

    # Add the main channels. These channels are declared in includes/channels.h
    s.addChannel(s.COMMAND_CHANNEL);
    #s.addChannel(s.GENERAL_CHANNEL);
    s.addChannel(s.ROUTING_CHANNEL)
    s.addChannel(s.TRANSPORT_CHANNEL);

    # After sending a ping, simulate a little to prevent collision.
    s.runTime(300);
    s.routeDMP(1)
    s.runTime(200);
    #s.ping(1, 6, "TESTING")
    s.testServer(1, 1);    #    def testServer(self, address, port):
    s.runTime(100);
    s.testClient(4, 1, 1, 1);    #    def testClient(self, dest, srcPort, destPort, transfer):
    s.runTime(100);




if __name__ == '__main__':
    main()
