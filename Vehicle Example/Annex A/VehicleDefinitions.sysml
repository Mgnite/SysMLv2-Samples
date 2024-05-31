package VehicleDefinitions {
    import ISQ::*;

    import PartDefinitions::*;
    import PortDefinitions::*;
    import ItemDefinitions::*;
    import SignalDefinitions::*;
    import InterfaceDefinitions::*;
    import AllocationDefinitions::*;
    import ActionDefinitions::*;
    import StateDefinitions::*;
    import RequirementDefinitions::*;
    import AttributeDefinitions::*;
    import IndividualDefinitions::*;
    import MetadataDefinitions::**;
    import KeyWord_MetadataDefinitions::*;

    package PartDefinitions {
        part def Vehicle {
            attribute mass :> ISQ::mass;
            attribute dryMass:>ISQ::mass;
            attribute cargoMass:>ISQ::mass;
            attribute position:>ISQ::length;
            attribute velocity:>ISQ::speed;
            attribute acceleration:>ISQ::acceleration;
            attribute electricalPower:>ISQ::power;
            attribute Tmax:>ISQ::temperature;
            attribute maintenanceTime: Time::DateTime; 
            attribute brakePedalDepressed: Boolean;
            port ignitionCmdPort:IgnitionCmdPort;
            port pwrCmdPort:PwrCmdPort;
            port vehicleToRoadPort:VehicleToRoadPort;
            port statusPort:StatusPort;
            perform action providePower;
            perform action provideBraking;
            perform action controlDirection;
            perform action performSelfTest;
            perform action applyParkingBrake;
            perform action senseTemperature;
            exhibit state vehicleStates parallel {
                ref controller : VehicleController;
                state operatingStates {
                    entry action initial;
                    state off;                    
                    state starting;                    
                    state on {
                        entry performSelfTest;
                        do providePower;
                        exit applyParkingBrake;
                        constraint {electricalPower<=500[W]}
                    }

                    transition initial then off;

                    transition off_To_starting
                    first off
                    accept ignitionCmd:IgnitionCmd via ignitionCmdPort
                    if ignitionCmd.ignitionOnOff==IgnitionOnOff::on and brakePedalDepressed
                                  do send StartSignal() to controller
                                     then starting;
                        
                    transition starting_To_on
                    first starting
                    accept VehicleOnSignal
                    then on;
                        
                    transition on_To_off
                    first on
                    accept VehicleOffSignal
                    do send OffSignal() to controller
                       then off;
                }

                state healthStates {
                    entry action initial;
                    do senseTemperature{
                        out temp;
                    }

                    state normal;
                    state maintenance;
                    state degraded;                    

                    transition initial then normal;

                    transition normal_To_maintenance
                    first normal
                    accept at maintenanceTime
                    then maintenance;

                    transition normal_To_degraded
                    first normal
                    accept when senseTemperature.temp > Tmax 
                    do send OverTemp() to controller
                       then degraded;

                    transition maintenance_To_normal
                    first maintenance
                    accept ReturnToNormal
                    then normal;

                    transition degraded_To_normal
                    first degraded
                    accept ReturnToNormal
                    then normal;
                }
            }
        }

        part def Engine {
            attribute mass :> ISQ::mass;
            attribute peakHorsePower:>ISQ::power;
            attribute fuelEfficiency:Real;
            attribute cost:Real;
            attribute displacement :> ISQ::volume;
            port engineControlPort: ~ControlPort;
            port fuelInPort: ~ FuelPort;
            port fuelCmdPort:FuelCmdPort;
            port drivePwrPort:DrivePwrPort;
            port ignitionCmdPort:IgnitionCmdPort;
            port flyWheelPort;
            perform action generateTorque;
            exhibit state engineStates{
                state off;
                state starting;
                state on{
                    do generateTorque;
                }
            }
        }
        part def StarterMotor {
            port gearPort:GearPort;
        }
        part def Cylinder;
        part def Transmission {
            attribute gearRatio:Real;
            port clutchPort:~DrivePwrPort;
            exhibit state transmissionStates;
        }
        part def Driveshaft;
        part def AxleAssembly;
        part def Axle {
            attribute mass:>ISQ::mass;
        }
        part def FrontAxle:>Axle {
            attribute steeringAngle:>ISQ::angularMeasure;
        }
        part def HalfAxle{
            port shankCompositePort:ShankCompositePort{
            }
        }
        part def Differential;
        part def Wheel{
            attribute diameter:LengthValue;
            port lugNutCompositePort:LugNutCompositePort;
        }
        part def Hub{
            port shankCompositePort:ShankCompositePort;
        }
        abstract part def Software;
        part def VehicleSoftware:>Software;
        part def VehicleController:>Software {
            port controlPort:ControlPort;
            exhibit state controllerStates parallel {
                state operatingStates {
                    entry action initial; 
                    state off;
                    state on;    
                    transition initial then off;
                    transition 'off-on'
                    first off
                    accept StartSignal
                    then on;
                    transition 'on-off'
                    first on
                    accept OffSignal
                    then off;
                }
            }  
        }
        part def CruiseController:>Software {
            port setSpeedPort:~SetSpeedPort;
            port speedSensorPort:~SpeedSensorPort;
            port cruiseControlPort:CruiseControlPort;
            exhibit state cruiseControllerStates;
        }
        part def SpeedSensor{
            port speedSensorPort:SpeedSensorPort;
        }
        part def FuelTank{
            attribute mass :> ISQ::mass;
            ref item fuel:Fuel{
                attribute :>> fuelMass;
            }
            attribute fuelKind:FuelKind;
            attribute fuelMassMax:>ISQ::mass;
            assert constraint fuelConstraint {fuel.fuelMass<=fuelMassMax}
            port fuelOutPort:FuelPort;
            port fuelInPort:~FuelPort;
        }
        part def BodyAssy;
        part def Body{
            attribute color:Colors;
        }
        part def Thermostat;
        part def WaterHose;
        part def Road{
            attribute incline:Real;
            attribute friction:Real;
        }
        part def Engine4Cyl;
        part def Engine6Cyl;
        part def TransmissionChoices;
        part def TransmissionAutomatic;
        part def TransmissionManual;
        part def Sunroof;
            
        //logical Components
        part def ElectricalGenerator;
        part def TorqueGenerator;
        part def SteeringSubsystem;
        part def BrakingSubsystem;
    }
    package PortDefinitions{
        port def IgnitionCmdPort{
            in item ignitionCmd:IgnitionCmd;
        }
        port def StatusPort;
        port def GearPort;
        port def PwrCmdPort{
            in item pwrCmd:PwrCmd;
        }
        port def FuelCmdPort:>PwrCmdPort{
            in item fuelCmd:FuelCmd redefines pwrCmd;
        }
        port def FuelPort{
            out item fuel:Fuel;
        }
        port def DrivePwrPort{
            out torque:Torque;
        }
        port def ShaftPort_a;
        port def ShaftPort_b;
        port def ShaftPort_c;
        port def ShaftPort_d;
        port def DiffPort;
        port def AxlePort;
        port def AxleToWheelPort;
        port def WheelToAxlePort;
        port def WheelToRoadPort;

        port def LugNutCompositePort{
            port lugNutPort:LugNutPort [*];
        }
        port def ShankCompositePort{
            port shankPort:ShankPort [*];
        }
        port def LugNutPort{
            attribute threadDia;
            attribute threadPitch;
        }
        port def ShankPort{
            attribute threadDia;
            attribute threadPitch;   
            attribute shaftLength;
        }
            
        port def VehicleToRoadPort;
        port def ControlPort;
        port def CruiseControlPort:>ControlPort;
        port def SpeedSensorPort;
        port def SetSpeedPort;

        port def DriverCmdPort{
            out item driverCmd[*]:DriverCmd;
        }
        port def HandPort :> DriverCmdPort {
            out item ignitionCmd:IgnitionCmd subsets driverCmd;
            out item pwrCmd:PwrCmd subsets driverCmd;
        }  
    }
    package ItemDefinitions{
        item def PwrCmd{
            attribute throttleLevel:Real;
        }
        item def FuelCmd:>PwrCmd;
        item def Fuel{
            attribute fuelMass:>ISQ::mass;
        }
        item def SensedSpeed{
            attribute speed:>ISQ::speed;
        }
    }
    package SignalDefinitions{
        item def Cmd{
        }
        item def DriverCmd;
        item def IgnitionCmd:>DriverCmd{
            attribute ignitionOnOff:IgnitionOnOff;
        }
        item def EngineStatus;
            
        attribute def VehicleStartSignal;
        attribute def VehicleOnSignal;
        attribute def VehicleOffSignal;
        attribute def StartSignal;
        attribute def OffSignal;
        attribute def OverTemp;
        attribute def ReturnToNormal;
        attribute def SetSpeed:>Real;
    }
    package InterfaceDefinitions{
        interface def EngineToTransmissionInterface{
            end p1:DrivePwrPort;
            end p2:~DrivePwrPort;
            flow p1.torque to p2.torque;
        }
        interface def FuelInterface {
            end fuelOutPort:FuelPort;
            end fuelInPort:~FuelPort;
            flow of Fuel from fuelOutPort.fuel to fuelInPort.fuel;
        }
            
        interface def WheelFastenerInterface{
            end lugNutPort:LugNutPort;
            end shankPort:ShankPort;
            attribute maxTorque : Torque;
            constraint {lugNutPort.threadDia == shankPort.threadDia}
        }
        interface def WheelHubInterface{
            end lugNutCompositePort:LugNutCompositePort;
            end shankCompositePort:ShankCompositePort;
            interface wheelFastenerInterface:WheelFastenerInterface [5]
            connect lugNutCompositePort.lugNutPort to shankCompositePort.shankPort;
        }
    }
    package AllocationDefinitions{
        allocation def LogicalToPhysical{
            end #logical logicalEnd;
            end #physical physicalEnd;
        }
    }
    package ActionDefinitions{
        action def ProvidePower {
            in item pwrCmd:PwrCmd;
            out wheelToRoadTorque:Torque[2];
        }
        action def GenerateTorque {
            in item fuelCmd:FuelCmd;
            out engineTorque:Torque;
        }
        action def AmplifyTorque {
            in engineTorque:Torque;
            out transmissionTorque:Torque;
        }
        action def TransferTorque {
            in transmissionTorque:Torque;
            out driveshaftTorque:Torque;
        }
        action def DistributeTorque {
            in driveshaftTorque:Torque;
            out wheelToRoadTorque:Torque[2];
        }
        action def PerformSelfTest;
        action def ApplyParkingBrake;
        action def SenseTemperature{
            out temp: ISQ::TemperatureValue;
        }
    }    
    package StateDefinitions {
        state def VehicleStates;
        state def ControllerStates;  
        state def CruiseControllerStates;
    }
    package RequirementDefinitions{
        requirement def MassRequirement{
            doc /*The actual mass shall be less than the required mass*/
            attribute massRequired:>ISQ::mass;
            attribute massActual:>ISQ::mass;
            require constraint {massActual<=massRequired}
        }
        requirement def ReliabilityRequirement{
            doc /*The actual reliability shall be greater than the required reliability*/
            attribute reliabilityRequired:Real;
            attribute reliabilityActual:Real;
            require constraint {reliabilityActual>=reliabilityRequired}
        }
        requirement def TorqueGenerationRequirement {
            doc /* The engine shall generate torque as a function of RPM as shown in Table 1. */
            subject generateTorque:ActionDefinitions::GenerateTorque;
        }
        requirement def DrivePowerOutputRequirement { 
            doc /* The engine shall provide a connection point to transfer torque to the transmission.*/
            }
        requirement def FuelEconomyRequirement {
            doc /* The vehicle shall maintain an average fuel economomy of at least x miles per gallon for the nominal 
                   driving scenario */
            attribute actualFuelEconomy :> distancePerVolume;
            attribute requiredFuelEconomy :> distancePerVolume;
            require constraint {actualFuelEconomy >= requiredFuelEconomy}
        }
    }
    package AttributeDefinitions{
        import ScalarValues::*;
        import Quantities::*;
        import MeasurementReferences::DerivedUnit;
        import SIPrefixes::kilo;
        // Numerical Functions provides basic operators such as Sum expression
        import NumericalFunctions::*;
        import SI::*;
        import USCustomaryUnits::*;
        alias Torque for ISQ::TorqueValue;
            
        enum def Colors {black;grey;red;}
        enum def DiameterChoices:>ISQ::LengthValue{
            enum = 60 [mm];
            enum = 80 [mm];
            enum = 100 [mm];
        }
        attribute cylinderDiameter: DiameterChoices = 80 [mm]; 
        enum def IgnitionOnOff {on;off;}
        enum def FuelKind {gas;diesel;}

        distancePerVolume :> scalarQuantities = distance / volume;
        timePerDistance :> scalarQuantities = time / distance;
        volumePerDistance :> scalarQuantities = volume / distance;
        volumePerTime :> scalarQuantities = volume / time;
            
        // kpl is approx .425 * mpg
        kpl : DerivedUnit = km / L;
        rpm : DerivedUnit = 1 / SI::min;
        kW : DerivedUnit = kilo * W;
            
    }
    package IndividualDefinitions{
        individual def VehicleRoadContext_1:>GenericContext::Context;
        individual def Vehicle_1:>Vehicle;
        individual def FrontAxleAssembly_1:>AxleAssembly;
        individual def FrontAxle_1:>FrontAxle;
        individual def Wheel_1:>Wheel;
        individual def Wheel_2:>Wheel;
        individual def RearAxleAssembly_1:>AxleAssembly;
        individual def Road_1:>Road;
    }
    package MetadataDefinitions { 
        import AnalysisTooling::*;   
        metadata def Safety {
            attribute isMandatory : Boolean;
        }
        metadata def Security;
    }
    package KeyWord_MetadataDefinitions{
        import Metaobjects::SemanticMetadata;
            
        // the following is used to define the key word failureMode
        state failureModes[*] nonunique;
            
        // with alias <fm>
        metadata def <fm> failureMode :> SemanticMetadata {
:>> baseType = failureModes meta SysML::StateUsage;
        }
            
        occurrence logicalOccurrences [*] nonunique;
            
        metadata def <l> logical :> SemanticMetadata {
:>> baseType = logicalOccurrences meta SysML::Usage;
        }
            
        occurrence physicalOccurrences [*] nonunique;
            
        metadata def <p> physical :> SemanticMetadata {
:>> baseType = physicalOccurrences meta SysML::Usage;
        }  
    }
    package GenericContext {

        part def Context {
            attribute time:TimeValue;
            attribute spatialCF: CartesianSpatial3dCoordinateFrame[1] { :>> mRefs = (m, m, m); }
            attribute velocityCF: CartesianVelocity3dCoordinateFrame[1] = spatialCF/s;
            attribute accelarationCF: CartesianAcceleration3dCoordinateFrame[1] = velocityCF/s;
        }
    }
}
