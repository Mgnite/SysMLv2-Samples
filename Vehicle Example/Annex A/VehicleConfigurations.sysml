package VehicleConfigurations {
    import VehicleDefinitions::*;

    package VehicleConfiguration_a {
        package PartsTree {
            part vehicle_a:Vehicle{
                attribute mass redefines Vehicle::mass=dryMass+cargoMass+fuelTank.fuel.fuelMass;
                attribute dryMass redefines Vehicle::dryMass=sum(partMasses);
                attribute redefines Vehicle::cargoMass=0 [kg];
                attribute partMasses [*] nonunique :>ISQ::mass;
                part fuelTank:FuelTank{
                    attribute redefines mass=75[kg];
                    ref item redefines fuel{
                        attribute redefines fuelMass=50[kg];
                    }   
                }
                part frontAxleAssembly:AxleAssembly{
                    attribute mass :> ISQ::mass=800[kg];
                    part frontAxle:Axle;
                    part frontWheels:Wheel[2];
                }
                part rearAxleAssembly:AxleAssembly{
                    attribute mass :> ISQ::mass=875[kg];
                    attribute driveTrainEfficiency:Real = 0.6;
                    part rearAxle:Axle;
                    part rearWheels:Wheel[2]{
                        attribute redefines diameter;
                    }
                }
            }
        }
        package ActionTree{  
        }
        package Requirements{
        }
    }
    package VehicleConfiguration_b{
        //Shapes library for simple geometry
        import ShapeItems::Box;
        import ParametersOfInterestMetadata::mop;
        import ModelingMetadata::*; // incudes status info
            
        package PartsTree{
            part vehicle_b : Vehicle{
                #mop attribute mass redefines mass=dryMass+cargoMass+fuelTank.fuel.fuelMass;
                attribute dryMass redefines dryMass=sum(partMasses);
                attribute redefines cargoMass default 0 [kg];
                attribute partMasses=(fuelTank.mass,frontAxleAssembly.mass,rearAxleAssembly.mass,engine.mass,transmission.mass,driveshaft.mass);
                attribute avgFuelEconomy :> distancePerVolume;
                port fuelCmdPort: FuelCmdPort redefines pwrCmdPort {
                    in item fuelCmd redefines pwrCmd;
                }
                port setSpeedPort:~SetSpeedPort;
                port vehicleToRoadPort redefines vehicleToRoadPort{
                    port wheelToRoadPort1:WheelToRoadPort;
                    port wheelToRoadPort2:WheelToRoadPort;
                }
                perform ActionTree::providePower redefines providePower;
                perform ActionTree::performSelfTest redefines performSelfTest;
                perform ActionTree::applyParkingBrake redefines applyParkingBrake;
                perform ActionTree::senseTemperature redefines senseTemperature;
                exhibit state vehicleStates redefines vehicleStates;
                    
                // Example vehicle with simple enveloping shape that is a solid 
                item :> envelopingShapes : Box[1] {
                length1:>> length = 4800 [mm];
                width1:>> width = 1840 [mm];
                height1:>> height = 1350 [mm];
                }
                    
                part fuelTank:FuelTank{
                    attribute redefines mass=75[kg];
                    ref item redefines fuel{
                        attribute redefines fuelMass=60[kg];
                    }
                    attribute redefines fuelMassMax=60 [kg];
                }
                part frontAxleAssembly:AxleAssembly{
                    attribute mass :> ISQ::mass=800[kg];
                    port shaftPort_d:ShaftPort_d;
                    part frontAxle:FrontAxle;
                    part frontWheels:Wheel[2];
                }
                    
                part rearAxleAssembly:AxleAssembly{
                    attribute mass :> ISQ::mass=875[kg];
                    attribute driveTrainEfficiency:Real = 0.6;
                    port shaftPort_d:ShaftPort_d;
                    perform providePower.distributeTorque;
                    part rearWheel1:Wheel{
                        attribute redefines diameter;
                        port wheelToRoadPort:WheelToRoadPort;
                        port lugNutCompositePort :>> lugNutCompositePort{
                            port lugNutPort :>> lugNutPort [5];
                        }
                    }
                    part rearWheel2:Wheel{
                        attribute redefines diameter;
                        port wheelToRoadPort:WheelToRoadPort;
                        port lugNutCompositePort :>> lugNutCompositePort{
                            port lugNutPort :>> lugNutPort [5];
                        }
                    }
                    part differential:Differential{
                        port shaftPort_d:ShaftPort_d;
                        port leftDiffPort:DiffPort;
                        port rightDiffPort:DiffPort;
                    }
                    part rearAxle{
                        part leftHalfAxle:HalfAxle{
                            port leftAxleToDiffPort:AxlePort;
                            port shankCompositePort :>> shankCompositePort{
                                port shankPort :>> shankPort [5];
                            }
                        }
                        part rightHalfAxle:HalfAxle{
                            port rightAxleToDiffPort:AxlePort;
                            port shankCompositePort :>> shankCompositePort {
                                port shankPort :>> shankPort [5];
                            }
                        }
                    }
                        
                    bind shaftPort_d=differential.shaftPort_d;
                    connect differential.leftDiffPort to rearAxle.leftHalfAxle.leftAxleToDiffPort;
                    connect differential.rightDiffPort to rearAxle.rightHalfAxle.rightAxleToDiffPort;
                        
                    interface wheelToleftHalAxleInterface:WheelHubInterface 
                    connect rearWheel1.lugNutCompositePort [1] to rearAxle.leftHalfAxle.shankCompositePort [1];
                    interface wheelTorightHalAxleInterface:WheelHubInterface
                    connect rearWheel2.lugNutCompositePort [1] to rearAxle.rightHalfAxle.shankCompositePort [1];
                        
                }
                part starterMotor:StarterMotor;
                part engine:Engine{
                    perform providePower.generateTorque redefines generateTorque;            
                    part cylinders:Cylinder[4..6];
                    part alternator{
                        action generateElectricity;
                    }
                    satisfy Requirements::engineSpecification by vehicle_b.engine{
                        requirement torqueGenerationRequirement :>> torqueGenerationRequirement{
                            subject generateTorque redefines generateTorque = vehicle_b.engine.generateTorque;
                        }
                        requirement drivePowerOuputRequirement :>> drivePowerOutputRequirement{
                            port torqueOutPort redefines torqueOutPort=vehicle_b.engine.drivePwrPort;
                        }
                    } 
                }
                part transmission:Transmission{
                    attribute mass :> ISQ::mass=100[kg];
                    port shaftPort_a:ShaftPort_a;
                    perform providePower.amplifyTorque;
                }
                part driveshaft:Driveshaft{
                    attribute mass :> ISQ::mass=100[kg];
                    port shaftPort_b:ShaftPort_b;
                    port shaftPort_c:ShaftPort_c;
                    perform providePower.transferTorque;
                }
                part vehicleSoftware:VehicleSoftware{
                    part vehicleController: VehicleController {
                        exhibit state controllerStates redefines controllerStates;
                        part cruiseController:CruiseController;
                    }
                }
                part speedSensor:SpeedSensor;
                    
                // parts in bodyAssy and interioer are marked as safety or security features
                part bodyAssy:BodyAssy{
                    part body:Body{
                        attribute :>> color = Colors::red;  
                    }
                    part bumper {@Safety{isMandatory = true;}}
                    part keylessEntry {@Security;}
                }
                part interior {
                    part alarm {@Security;}
                    part seatBelt[2] {@Safety{isMandatory = true;}}
                    part frontSeat[2];
                    part driverAirBag {@Safety{isMandatory = false;}}
                }
                    
                //connections
                bind engine.fuelCmdPort=fuelCmdPort;

                interface engineToTransmissionInterface:EngineToTransmissionInterface
                connect engine.drivePwrPort to transmission.clutchPort;
                
                interface fuelInterface:FuelInterface
                connect fuelTank.fuelOutPort to engine.fuelInPort;

                allocate ActionTree::providePower.generateToAmplify to engineToTransmissionInterface;
                    
                bind engine.ignitionCmdPort=ignitionCmdPort;
                connect starterMotor.gearPort to engine.flyWheelPort;
                connect vehicleSoftware.vehicleController.controlPort to engine.engineControlPort;
                bind vehicle_b.setSpeedPort = vehicleSoftware.vehicleController.cruiseController.setSpeedPort;
                connect speedSensor.speedSensorPort to vehicleSoftware.vehicleController.cruiseController.speedSensorPort;
                bind vehicleSoftware.vehicleController.cruiseController.cruiseControlPort = vehicleSoftware.vehicleController.controlPort;
                connect transmission.shaftPort_a to driveshaft.shaftPort_b; 
                connect driveshaft.shaftPort_c to rearAxleAssembly.shaftPort_d;
                bind rearAxleAssembly.rearWheel1.wheelToRoadPort=vehicleToRoadPort.wheelToRoadPort1;
                bind rearAxleAssembly.rearWheel2.wheelToRoadPort=vehicleToRoadPort.wheelToRoadPort2;
                    
                satisfy Requirements::vehicleSpecification by vehicle_b{
                    requirement vehicleMassRequirement:>>vehicleMassRequirement{
                        attribute redefines massActual=vehicle_b.mass;
                        attribute redefines fuelMassActual = vehicle_b.fuelTank.fuel.fuelMass;
                    }
                }
            }
        }
        package ActionTree{
            action providePower:ProvidePower{
                in item fuelCmd:FuelCmd redefines pwrCmd;
                out wheelToRoadTorque redefines wheelToRoadTorque [2] = distributeTorque.wheelToRoadTorque;
                action generateTorque:GenerateTorque {
                    in item = providePower.fuelCmd;
                }
                action amplifyTorque:AmplifyTorque;
                action transferTorque:TransferTorque;
                action distributeTorque:DistributeTorque;
                    
                //named flow
                flow generateToAmplify from generateTorque.engineTorque to amplifyTorque.engineTorque;
                //unnamed flows
                flow amplifyTorque.transmissionTorque to transferTorque.transmissionTorque;
                flow transferTorque.driveshaftTorque to distributeTorque.driveshaftTorque;
            }
            action performSelfTest: PerformSelfTest;
            action applyParkingBrake: ApplyParkingBrake;
            action senseTemperature: SenseTemperature;
        }                   
        package DiscreteInteractions{
            package Sequence{
                part def Driver{
                    port p1;
                    port p2;
                }

                part part0{
                    perform action startVehicle{
                        action turnVehicleOn send ignitionCmd via driver.p1{
                            in ignitionCmd:IgnitionCmd;
                        }
                        action trigger1 accept ignitionCmd:IgnitionCmd via vehicle.ignitionCmdPort;
                        flow of IgnitionCmd from trigger1.ignitionCmd to startEngine.ignitionCmd;
                        action startEngine{
                            in item ignitionCmd:IgnitionCmd; 
                            out item es:EngineStatus;
                        }
                        flow of EngineStatus from startEngine.es to sendStatus.es;
                        action sendStatus send es via vehicle.statusPort{
                            in es:EngineStatus;
                        }
                        action trigger2 accept es:EngineStatus via driver.p2;
                    }
                    part driver : Driver {
                        perform startVehicle.turnVehicleOn;
                        perform startVehicle.trigger2;
                        event occurrence driverReady;
                    }
                    part vehicle : Vehicle {
                        perform startVehicle.trigger1;
                        perform startVehicle.sendStatus;
                        event occurrence doorClosed;
                    }
                    first vehicle.doorClosed then driver.driverReady;
                    message of ignitionCmd:IgnitionCmd from driver.turnVehicleOn to vehicle.trigger1;  
                    message of es:EngineStatus from vehicle.sendStatus to driver.trigger2;
                }
            }
            occurrence CruiseControl1{
                part vehicle_b:>PartsTree::vehicle_b{
                    port redefines setSpeedPort{
                        event occurrence setSpeedReceived;
                    }
                    part redefines speedSensor{
                        port redefines speedSensorPort{
                            event occurrence sensedSpeedSent;
                        }
                    }
                    part redefines vehicleSoftware{
                        part redefines vehicleController{
                            part redefines cruiseController{
                                port redefines setSpeedPort{
                                    //analagous to gate: event occurrence bound but may not need this since the port is bound
                                    event occurrence setSpeedReceived = vehicle_b.setSpeedPort.setSpeedReceived;
                                }
                                port redefines speedSensorPort{
                                    event occurrence sensedSpeedReceived;
                                }
                                port redefines cruiseControlPort{
                                    event occurrence fuelCmdSent;
                                }
                            }
                        }
                    }
                    part redefines engine{
                        port redefines fuelCmdPort{
                            event occurrence fuelCmdReceived;
                        }
                    }
                    message sendSensedSpeed of SensedSpeed
                    from speedSensor.speedSensorPort.sensedSpeedSent to vehicleSoftware.vehicleController.cruiseController.speedSensorPort.sensedSpeedReceived;
                    message sendFuelCmd of FuelCmd
                    from vehicleSoftware.vehicleController.cruiseController.cruiseControlPort.fuelCmdSent to engine.fuelCmdPort.fuelCmdReceived;
                }
            }
            occurrence CruiseControl2{
                part vehicle_b:>PartsTree::vehicle_b{
                    port redefines setSpeedPort{
                        event occurrence setSpeedReceived;
                    }
                    part redefines speedSensor{
                        port redefines speedSensorPort{
                            event sendSensedSpeed.source;
                        }
                    }
                    part redefines vehicleSoftware{
                        part redefines vehicleController{
                            part redefines cruiseController{
                                port redefines setSpeedPort{
                                    //analagous to gate: event occurrence bound but may not need this since the port is bound
                                    event occurrence setSpeedReceived = vehicle_b.setSpeedPort.setSpeedReceived;
                                }
                                port redefines speedSensorPort{
                                    event occurrence setSpeedReceived=setSpeedPort.setSpeedReceived;
                                    then event sendSensedSpeed.target;
                                }
                                port redefines cruiseControlPort{             
                                    event sendFuelCmd.source;
                                }
                            }
                        }
                    }
                    part redefines engine{
                        port redefines fuelCmdPort{
                            event sendFuelCmd.target;
                        }
                    }
                    message sendSensedSpeed of SensedSpeed;
                    message sendFuelCmd of FuelCmd;
                }
            }
        }
        package Requirements{
            import RequirementDerivation::*;
            import ModelingMetadata::*; // incudes status info
            item marketSurvey;
            dependency from vehicleSpecification to marketSurvey;
                
            requirement vehicleSpecification{
                subject vehicle:Vehicle;
                requirement <'1'> vehicleMassRequirement: MassRequirement {
                    doc /* The total mass of the vehicle shall be less than or equal to the required mass.
                           Assume total mass includes a full tank of gas of 60 kg*/
                    attribute redefines massRequired=2000 [kg];                     
                    attribute redefines massActual default vehicle.dryMass + fuelMassActual;
                    attribute fuelMassActual:>ISQ::mass;
                    attribute fuelMassMax:>ISQ::mass = 60 [kg];
                    assume constraint {fuelMassActual==fuelMassMax}
                }
                    
                allocate vehicleMassRequirement to PartsTree::vehicle_b.mass;
                    
                requirement <'2'> vehicleFuelEconomyRequirements{
                    doc /* fuel economy requirements group */
                    attribute assumedCargoMass:>ISQ::mass;
                    requirement <'2_1'> cityFuelEconomyRequirement:FuelEconomyRequirement{
                        redefines requiredFuelEconomy= 10 [km / L];
                        assume constraint {assumedCargoMass<=500 [kg]}
                    }
                    requirement <'2_2'> highwayFuelEconomyRequirement:FuelEconomyRequirement{
                        redefines requiredFuelEconomy= 12.75 [km / L];
                        assume constraint {assumedCargoMass<=500 [kg]}
                            
                        //StatusInfo is contained in ModelingMetadata library
                        // StatusKind has values for open, closed, tbd, tbr, tbd
                        @StatusInfo {
                            status = StatusKind::closed;     
                            originator = "Bob";
                            owner = "Mary";
                        }
                    }
                }
            }
            requirement engineSpecification {
                subject engine1:Engine;
                requirement <'1'> engineMassRequirement: MassRequirement {
                    doc /* The total mass of the engine shall be less than or equal to the required mass.*/
                    attribute redefines massRequired=200 [kg];                     
                    attribute redefines massActual = engine1.mass;
                }
                requirement torqueGenerationRequirement : TorqueGenerationRequirement{
                    subject generateTorque default engine1.generateTorque;
                }

                requirement drivePowerOutputRequirement : DrivePowerOutputRequirement{
                    port torqueOutPort{
                        out torque:Torque;
                    }
                }
            }
            // the engine mass requirement is derived from the vehicle mass requirement
            #derivation connection {
                end #original ::> vehicleSpecification.vehicleMassRequirement;
                end #derive ::> engineSpecification.engineMassRequirement;
            }

        }
    }    
    package Engine4Cyl_Variant{
        import ModelingMetadata::*; // incudes refinement
        part engine:Engine{
            part cylinders:Cylinder[4..8] ordered;
        }
        part engine4Cyl:>engine{
            part redefines cylinders [4];
            part cylinder1 subsets cylinders[1];
            part cylinder2 subsets cylinders[1];
            part cylinder3 subsets cylinders[1];
            part cylinder4 subsets cylinders[1];
        }
        #refinement dependency engine4Cyl to VehicleConfiguration_b::PartsTree::vehicle_b::engine;
    }
    package WheelHubAssemblies{
        // alternative 1 - w/o explicit nesxted interfaces
        part wheelHubAssy1{
            part wheel1:Wheel{
                port :>>lugNutCompositePort:LugNutCompositePort {
                    port lugNutPort :>> lugNutPort [5];
                }
            }
            part hub1:Hub{
                port :>> shankCompositePort:ShankCompositePort {
                    port shankPort :>> shankPort [5];
                }
            }
            interface wheelHubInterface:WheelHubInterface
            connect wheel1.lugNutCompositePort [1] to hub1.shankCompositePort [1];
        }
        // alternative 2 - w multiple nesxted interfaces
        part wheelHubAssy2{
            part wheel1:Wheel{
                port :>>lugNutCompositePort:LugNutCompositePort {
                    port lugNutPort :>> lugNutPort [5];
                }
            }
            part hub1:Hub{
                port :>> shankCompositePort:ShankCompositePort {
                    port shankPort :>> shankPort [5];
                }
            }
            interface wheelHubInterface:WheelHubInterface
            connect lugNutCompositePort ::> wheel1.lugNutCompositePort [1] to shankCompositePort ::> hub1.shankCompositePort [1] {
                interface wheelFastenerInterface1 :> wheelFastenerInterface
                connect lugNutPort ::> lugNutCompositePort.lugNutPort [5] to shankPort ::> shankCompositePort.shankPort [5];
            }
        }
        // alternative 3 - w explicit nesxted interfaces
        part wheelHubAssy3{
            part wheel1:Wheel{
                port lugNutCompositePort :>> lugNutCompositePort {
                    port lugNutPort [5] :>> lugNutPort {
                        attribute :>> threadDia = 14 [mm];
                        attribute :>> threadPitch = 1.5 [mm];
                    }
                    port lugNutPort1 [1] :> lugNutPort;
                    port lugNutPort2 [1] :> lugNutPort;
                    port lugNutPort3 [1] :> lugNutPort;
                }
            }
            part hub1:Hub{
                port shankCompositePort :>> shankCompositePort {
                    port shankPort [5] :>> shankPort {
                        attribute :>> threadDia = 14 [mm];
                        attribute :>> threadPitch = 1.5 [mm];
                        attribute :>> shaftLength = 70 [mm];
                    }
                    port shankPort1 [1] :> shankPort;
                    port shankPort2 [1] :> shankPort;
                    port shankPort3 [1] :> shankPort;
                }
            }
            interface wheelHubInterface:WheelHubInterface
            connect lugNutCompositePort ::> wheel1.lugNutCompositePort [1] to shankCompositePort ::> hub1.shankCompositePort [1] {
                interface wheelFastenerInterface1 :> wheelFastenerInterface
                connect lugNutPort ::> lugNutCompositePort.lugNutPort1 to shankPort ::> shankCompositePort.shankPort1 {
                    attribute :>> maxTorque = 90 * 1.356 [N*m];
                }
                interface wheelFastenerInterface2 :> wheelFastenerInterface
                connect lugNutPort ::> lugNutCompositePort.lugNutPort2 to shankPort ::> shankCompositePort.shankPort2 {
                    attribute :>> maxTorque = 90 * 1.356 [N*m];
                }
                interface wheelFastenerInterface3 :> wheelFastenerInterface
                connect lugNutPort ::> lugNutCompositePort.lugNutPort3 to shankPort ::> shankCompositePort.shankPort3 {
                    attribute :>> maxTorque = 90 * 1.356 [N*m];
                }
            }
        }
    }
}
