package VehicleMissionContext {
    import VehicleDefinitions::*;
    /* Define mission context with mission use cases for vehicle_b */
    import VehicleConfigurations::VehicleConfiguration_b::**;
    import ParametersOfInterestMetadata::moe;
    import TransportPassengerScenario::*;
    package ContextDefinitions{
        part def MissionContext:>GenericContext::Context;
        part def Road;
        part def Driver{
            port handPort:HandPort{
            }
            exhibit state driverStates{
                state initial;
                state wait;
                transition initial then wait;
                //ignition on
                transition 'wait-wait-1'
                first wait
                do send IgnitionCmd (ignitionOnOff=IgnitionOnOff::on) via handPort
                   then wait;
                // ignition off
                transition 'wait-wait-2'
                first wait
                do send IgnitionCmd (ignitionOnOff=IgnitionOnOff::off) via handPort
                   then wait;
            }
        }
        part def Passenger;
            
        requirement transportRequirements;
        use case def TransportPassenger{
            objective TransportObjective {
                doc /*deliver passenger to destination safely, comfortably, and within acceptable time*/
                require transportRequirements;
            }
            subject vehicle:Vehicle;
            actor environment;
            actor road;
            actor driver;
            actor passenger [0..4];
            include use case getInVehicle_a:>getInVehicle [1..5];
                    include use case getOutOfVehicle_a:>getOutOfVehicle [1..5];
        }
            
        use case getInVehicle:GetInVehicle {
            action unlockDoor_in [0..1];
            then action openDoor_in;
            then action enterVehicle;
            then action closeDoor_in;
        }
        use case def GetInVehicle{
            subject vehicle:Vehicle;
            actor driver [0..1];
            actor passenger [0..1];
            assert constraint {driver != null xor passenger != null}
        }

        use case getOutOfVehicle:GetOutOfVehicle {
            action openDoor_out;
            then action exitVehicle;
            then action closeDoor_out;
            then action lockDoor_out;
        }
        use case def GetOutOfVehicle{
            subject vehicle:Vehicle;
            actor driver [0..1];
            actor passenger [0..1];
            assert constraint {driver != null xor passenger != null}
        }
    }
    package TransportPassengerScenario{
        import ContextDefinitions::TransportPassenger;
            
        // this version uses nesting vs fork and join for concurrent actions
        use case transportPassenger:TransportPassenger{
            first start; 
            then action a{
                action driverGetInVehicle subsets getInVehicle_a[1];
                action passenger1GetInVehicle subsets getInVehicle_a[1];
            }
            then action trigger accept ignitionCmd:IgnitionCmd;
            then action b{
                action driveVehicleToDestination;
                action providePower;   
            }
            then action c{
                action driverGetOutOfVehicle subsets getOutOfVehicle_a[1];
                action passenger1GetOutOfVehicle subsets getOutOfVehicle_a[1];
            }
            then done;
        }
            
            
        //this version uses forks and joins
        use case transportPassenger_1:TransportPassenger{
            // declare actions
            action driverGetInVehicle subsets getInVehicle_a[1];
            action passenger1GetInVehicle subsets getInVehicle_a[1];
            action driverGetOutOfVehicle subsets getOutOfVehicle_a[1];
            action passenger1GetOutOfVehicle subsets getOutOfVehicle_a[1];
            action driveVehicleToDestination;
            action providePower;
            item def VehicleOnSignal;
            join join1;
            join join2;
            join join3;
            action trigger accept ignitionCmd:IgnitionCmd;
                
            // define control flow
            first start;               
            then fork fork1;
            then driverGetInVehicle;
            then passenger1GetInVehicle;
            first driverGetInVehicle then join1;
            first passenger1GetInVehicle then join1;
            first join1 then trigger;
            first trigger then fork2;
            //succession trigger if trigger.ignitionCmd.ignitionOnOff==IgnitionOnOff::on then fork2;
                
            fork fork2;
            then driveVehicleToDestination;
            then providePower;
            first driveVehicleToDestination then join2;
            first providePower then join2;
            first join2 then fork3;

            fork fork3; 
            then driverGetOutOfVehicle;
            then passenger1GetOutOfVehicle;
            first driverGetOutOfVehicle then join3;
            first passenger1GetOutOfVehicle then join3;

            first join3 then done;
        }
    }
        
    part missionContext:ContextDefinitions::MissionContext{
        #moe attribute transportTime :> ISQ::time;
        perform transportPassenger;
        // bind parts to actors of use case
        part road:ContextDefinitions::Road = transportPassenger.road;
        part driver:ContextDefinitions::Driver = transportPassenger.driver{
            perform transportPassenger.a.driverGetInVehicle.unlockDoor_in;
            perform transportPassenger.a.driverGetInVehicle.openDoor_in;
            perform transportPassenger.a.driverGetInVehicle.enterVehicle; 
            perform transportPassenger.a.driverGetInVehicle.closeDoor_in;
            perform transportPassenger.c.driverGetOutOfVehicle.openDoor_out;
            perform transportPassenger.c.driverGetOutOfVehicle.exitVehicle; 
            perform transportPassenger.c.driverGetOutOfVehicle.closeDoor_out;
            perform transportPassenger.c.driverGetOutOfVehicle.lockDoor_out;
            perform transportPassenger.b.driveVehicleToDestination;
        }
        part passenger1:ContextDefinitions::Passenger = transportPassenger.passenger {
            perform transportPassenger.a.passenger1GetInVehicle.unlockDoor_in;
            perform transportPassenger.a.passenger1GetInVehicle.openDoor_in;
            perform transportPassenger.a.passenger1GetInVehicle.enterVehicle; 
            perform transportPassenger.a.passenger1GetInVehicle.closeDoor_in;
            perform transportPassenger.c.passenger1GetOutOfVehicle.openDoor_out;
            perform transportPassenger.c.passenger1GetOutOfVehicle.exitVehicle; 
            perform transportPassenger.c.passenger1GetOutOfVehicle.closeDoor_out;
            perform transportPassenger.c.passenger1GetOutOfVehicle.lockDoor_out;
        }
        part vehicle_b_1:>vehicle_b = transportPassenger.vehicle{
            attribute :>> position3dVector = (0,0,0) [spatialCF];
            perform transportPassenger.b.providePower redefines providePower;
            perform transportPassenger.trigger;
        }
        connect driver.handPort to vehicle_b_1.ignitionCmdPort;
        connect road to vehicle_b_1.vehicleToRoadPort;
    }
}
