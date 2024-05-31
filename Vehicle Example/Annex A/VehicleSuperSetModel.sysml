package VehicleSuperSetModel {
    import VehicleDefinitions::*;
    
    /* all of vehicleFamily is included in the superset model to enable subsetting a specific vehicle configuration*/
    package VariationPointDefinitions {
        variation part def TransmissionChoices:>Transmission {
            variant part transmissionAutomatic:TransmissionAutomatic;
            variant part transmissionManual:TransmissionManual;
        }
    }
    package VehiclePartsTree{
        import VariationPointDefinitions::*;
        abstract part vehicleFamily {
            // variation with nested variation
            variation part engine:Engine{
                variant part engine4Cyl:Engine4Cyl;
                variant part engine6Cyl:Engine6Cyl{
                    part cylinder:Cylinder [6]{
                        variation attribute diameter:LengthValue{
                            variant attribute smallDiameter:LengthValue;
                            variant attribute largeDiagmeter:LengthValue;
                        }
                    }
                }
            }
            // variation point based on variation of part definition
            part transmissionChoices:TransmissionChoices;
            // optional variation point
            part sunroof:Sunroof[0..1];
            // selection constraint
            assert constraint selectionConstraint{
                (engine==engine::engine4Cyl and transmissionChoices==TransmissionChoices::transmissionManual) xor
                (engine==engine::engine6Cyl and transmissionChoices==TransmissionChoices::transmissionAutomatic)
                }
            part driveshaft;
            part frontAxleAssembly;
            part rearAxleAssembly;
        }
    }
}
