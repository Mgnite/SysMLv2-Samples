package VehicleLogicalConfiguration {
    import VehicleDefinitions::*;
    package PartsTree {
        #logical part vehicleLogical:Vehicle{
            part torqueGenerator:TorqueGenerator{
                action generateTorque;
            }
            part electricalGenerator:ElectricalGenerator{
                action generateElectricity;
            }
            part steeringSystem:SteeringSubsystem;
            part brakingSubsystem:BrakingSubsystem;
        }
    }
}
