package VehicleSafetyandSecurityGroups {
    import VehicleDefinitions::MetadataDefinitions::*;
    import VehicleConfigurations::VehicleConfiguration_b::PartsTree::*;
    package SafetyGroup {
        /* Parts that contribute to safety. */
        import vehicle_b::**;
        filter @Safety;
    }
    package SecurityGroup {
        /* Parts that contribute to security. */
        import vehicle_b::**;
        filter @Security;
    }
    package SafetyandSecurityGroup {
        /* Parts that contribute to safety OR security. */
        import vehicle_b::**;
        filter @Safety or @Security;
    }
    package MandatorySafetyGroup {
        /* Parts that contribute to safety AND are mandatory. */
        import vehicle_b::**;
        filter @Safety and Safety::isMandatory;
    }
}
