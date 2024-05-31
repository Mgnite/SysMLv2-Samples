package VehicleIndividuals {
    import VehicleDefinitions::*;

    individual a:VehicleRoadContext_1{
        timeslice t0_t2_a{
            snapshot t0_a {             
                attribute t0 redefines time=0 [s];
                snapshot t0_r:Road_1{
                    :>>Road::incline =0;
                    :>>Road::friction=.1;
                }
                snapshot t0_v:Vehicle_1{
                    :>>Vehicle::position=0 [m];
                    :>>Vehicle::velocity=0 [m];
                    :>>Vehicle::acceleration=1.96 [m/s**2];
                    // .2 g where 1 g = 9.8 meters/sec^2
                    snapshot t0_fa:FrontAxleAssembly_1{
                        snapshot t0_leftFront:Wheel_1;
                        snapshot t0_rightFront:Wheel_2;
                    }
                }
            }
            snapshot t1_a{
                attribute t1 redefines time=1 [s];
                snapshot t1_r:Road_1{
                    :>>Road::incline =0;
                    :>>Road::friction=.1;
                }
                snapshot t1_v:Vehicle_1{
                    :>>Vehicle::position=.98 [m];
                    :>>Vehicle::velocity=1.96 [m/s];
                    :>>Vehicle::acceleration=1.96 [m/s**2];
                    // .2 g where 1 g = 9.8 meters/sec^2
                    snapshot t1_fa:FrontAxleAssembly_1{
                        snapshot t1_leftFront:Wheel_1;
                        snapshot t1_rightFront:Wheel_2;
                    }
                }
            }
            snapshot t2_a{
                attribute t2 redefines time=2 [s];
                snapshot t2_r:Road_1{
                    :>>Road::incline =0;
                    :>>Road::friction=.1;
                }
                snapshot t2_v:Vehicle_1{
                    :>>Vehicle::position=3.92 [m];
                    :>>Vehicle::velocity=3.92 [m/s];
                    :>>Vehicle::acceleration=1.96 [m/s**2];
                    // .2 g where 1 g = 9.8 meters/sec^2
                    snapshot t2_fa:FrontAxleAssembly_1{
                        snapshot t2_leftFront:Wheel_1;
                        snapshot t2_rightFront:Wheel_2;
                    }
                }
            }
        }
    }
}
