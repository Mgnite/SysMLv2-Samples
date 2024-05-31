package VehicleLogicalToPhysicalAllocation {
    import VehicleDefinitions::*;
    import VehicleConfigurations::VehicleConfiguration_b::PartsTree::**;
    import VehicleLogicalConfiguration::PartsTree::*;

    allocation vehicleLogicalToPhysicalAllocation : LogicalToPhysical
    allocate vehicleLogical to vehicle_b {
        allocate vehicleLogical.torqueGenerator to vehicle_b.engine {
            allocate vehicleLogical.torqueGenerator.generateTorque to vehicle_b.engine.generateTorque;
        }
        allocate vehicleLogical.electricalGenerator to vehicle_b.engine {
            allocate vehicleLogical.electricalGenerator.generateElectricity to vehicle_b.engine.alternator.generateElectricity;
        }
    }
} 
